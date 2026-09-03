// US1 T038 — 신규 옷 등록 화면. 002 T009 — editId로 수정 모드 겸용.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item_patch.dart';
import '../../data/providers/app_providers.dart';
import 'new_item_draft.dart';
import 'widgets/care_method_picker.dart';
import 'widgets/category_picker.dart';
import 'widgets/photo_picker_card.dart';
import 'widgets/wash_cycle_stepper.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({this.editId, super.key});

  /// null이면 등록 모드, 그 외에는 해당 옷의 수정 모드(002 FR-001).
  final int? editId;

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  NewItemDraft _draft = const NewItemDraft();

  /// 수정 모드의 dirty 판정 기준. 진입 시 원본 값으로 채워진다.
  NewItemDraft _initialDraft = const NewItemDraft();
  bool _saving = false;

  /// 수정 모드에서 로드된 기존 사진의 sandbox 절대 경로(표시용).
  String? _existingImagePath;

  /// 사용자가 "사진 제거"를 선택했는지(수정 모드).
  bool _photoCleared = false;

  bool get _isEdit => widget.editId != null;

  /// 로딩 완료 여부(수정 모드 진입 시 옷을 fetch하는 동안 false).
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _loadForEdit();
    }
  }

  Future<void> _loadForEdit() async {
    final item = await ref.read(itemRepositoryProvider).get(widget.editId!);
    if (!mounted) return;
    if (item == null) {
      showClosetimoToast(context, '옷을 찾을 수 없어요');
      context.pop();
      return;
    }
    final draft = NewItemDraft.fromItem(item);
    String? existingAbs;
    final imagePath = item.imagePath;
    if (imagePath != null) {
      existingAbs = await ref.read(imageStoreProvider).absolutePath(imagePath);
    }
    if (!mounted) return;
    setState(() {
      _draft = draft;
      _initialDraft = draft;
      _existingImagePath = existingAbs;
      _loading = false;
    });
  }

  /// 폼에 변경 사항이 있는지. 등록 모드는 빈 폼과 비교, 수정 모드는 원본과 비교.
  bool get _isDirty {
    if (!_isEdit) return _draft != const NewItemDraft();
    return _draft != _initialDraft || _photoCleared;
  }

  void _pickPhoto(File file) {
    setState(() {
      _draft = _draft.copyWith(tempPhoto: file);
      _photoCleared = false;
    });
  }

  /// tempPhoto를 확실히 null로 되돌리기 위해 draft를 재구성한다
  /// (freezed copyWith로는 nullable 필드를 null로 설정할 수 없다).
  void _removePhoto() {
    setState(() {
      _draft = NewItemDraft(
        name: _draft.name,
        brand: _draft.brand,
        category: _draft.category,
        washCycle: _draft.washCycle,
        careMethod: _draft.careMethod,
        purchasedAt: _draft.purchasedAt,
      );
      // 원본 사진이 있었을 때만 "제거" 의도가 유의미하다. 원본이 없는데
      // 새로 골랐다 지운 경우는 순변화 없음이므로 dirty로 오판하지 않는다.
      _photoCleared = _existingImagePath != null;
    });
  }

  Future<void> _pickPurchaseDate() async {
    final now = ref.read(clockProvider).now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.purchasedAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(purchasedAt: picked));
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!_isDirty) return true;
    final keep = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('작성을 그만두시겠어요?'),
        content: const Text('지금까지 입력한 내용이 사라져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('계속 작성'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    return keep ?? false;
  }

  // ignore_for_file: use_build_context_synchronously
  // (analyzer false positive — `context.mounted`/`mounted` 가드가 모든 사용에
  // 직접 선행하지만 분석기가 ConsumerState의 State.context를 비동기 갭 너머의
  // unrelated 참조로 잘못 분류한다.)
  Future<void> _save() async {
    if (!_draft.canSave || _saving) return;
    setState(() => _saving = true);
    String message;
    var success = false;
    try {
      final repo = ref.read(itemRepositoryProvider);
      if (_isEdit) {
        final photoChanged = _draft.tempPhoto != null || _photoCleared;
        await repo.update(
          widget.editId!,
          ItemPatch(
            name: _draft.name,
            brand: _draft.brand,
            category: _draft.category,
            careMethod: _draft.careMethod,
            washCycle: _draft.washCycle,
            purchasedAt: _draft.purchasedAt,
            newPhoto: _draft.tempPhoto,
            removePhoto: _photoCleared,
          ),
        );
        // 같은 경로(items/{id}.jpg)에 덮어쓰므로 FileImage 캐시가 이전
        // 이미지를 계속 반환한다. 상세·옷장이 새 사진을 즉시 반영하도록
        // 이미지 캐시를 비운다(FR-006, 파일 경로 기반 캐시 무효화 함정 회피).
        //
        // 경로 기반 타깃 evict(FileImage(File(abs)))는 쓰지 않는다: 표시 표면
        // (hero_image·garment_tile·recently_worn·laundry_tile)이 모두
        // Image.file(cacheWidth: N)을 쓰므로 캐시 키가 bare FileImage가 아니라
        // ResizeImage(_SizeAwareCacheKey)다. bare FileImage로 evict하면 어떤
        // 리사이즈 엔트리와도 == 이 성립하지 않아 stale 이미지가 남는다. 한 파일이
        // 최대 4가지 width로 캐싱되므로 키 무관 전역 clear가 이 경우 올바른 도구다.
        if (photoChanged) {
          PaintingBinding.instance.imageCache
            ..clear()
            ..clearLiveImages();
        }
        message = '옷 정보를 수정했어요';
      } else {
        await repo.create(_draft);
        message = '새 옷이 옷장에 등록됐어요';
      }
      success = true;
    } catch (e, stackTrace) {
      debugPrint('Failed to save item (edit=$_isEdit): $e\n$stackTrace');
      message = _isEdit ? '수정에 실패했어요' : '등록에 실패했어요';
    }
    if (!context.mounted) return;
    showClosetimoToast(context, message);
    if (success) context.pop();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return PopScope(
      // 변경 없으면 자유롭게 pop, dirty일 때만 시스템 back을 가로채 다이얼로그를 띄운다.
      // canPop은 시스템 back/maybePop 경로에서만 참조된다. go_router의 명시적
      // context.pop()은 Navigator.pop()을 명령형 호출해 PopScope를 우회하므로
      // 다이얼로그 후 context.pop()이 이중 다이얼로그 없이 정상 pop된다.
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard(context);
        if (!ok || !context.mounted) return;
        context.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  TopBar(
                    subtitle: _isEdit ? '옷 정보 수정' : '신규 옷 등록',
                    onBack: () async {
                      final ok = await _confirmDiscard(context);
                      if (!ok || !context.mounted) return;
                      context.pop();
                    },
                    rightSlot: TextButton(
                      onPressed: _draft.canSave && !_saving ? _save : null,
                      child: const Text('저장'),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        ClosetimoSpacing.lg,
                        ClosetimoSpacing.md,
                        ClosetimoSpacing.lg,
                        120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PhotoPickerCard(
                            tempPhoto: _draft.tempPhoto,
                            existingImagePath:
                                (_photoCleared || _draft.tempPhoto != null)
                                    ? null
                                    : _existingImagePath,
                            onPicked: _pickPhoto,
                            onRemove: _isEdit ? _removePhoto : null,
                          ),
                          const SizedBox(height: ClosetimoSpacing.xl + 2),
                          const _FieldLabel(label: '의류 명칭'),
                          _FieldInput(
                            initial: _draft.name,
                            hint: 'e.g. 오버사이즈 캐시미어 코트',
                            onChanged: (v) =>
                                setState(() => _draft = _draft.copyWith(name: v)),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '브랜드'),
                          _FieldInput(
                            initial: _draft.brand,
                            hint: 'e.g. ZARA',
                            onChanged: (v) =>
                                setState(() => _draft = _draft.copyWith(brand: v)),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '세탁 주기 설정'),
                          WashCycleStepper(
                            value: _draft.washCycle,
                            onChanged: (v) => setState(
                              () => _draft = _draft.copyWith(washCycle: v),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.sm),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              '설정한 횟수만큼 착용하면 세탁 알림을 보냅니다.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: ClosetimoColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(
                            label: '카테고리',
                            required: true,
                          ),
                          CategoryPicker(
                            value: _draft.category,
                            onChanged: (c) => setState(
                              () => _draft = _draft.copyWith(category: c),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '세탁 방법'),
                          CareMethodPicker(
                            value: _draft.careMethod,
                            onChanged: (m) => setState(
                              () => _draft = _draft.copyWith(careMethod: m),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '구매일'),
                          _DateField(
                            value: _draft.purchasedAt,
                            onTap: _pickPurchaseDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                // 글래스모피즘 바: 배경이 실제로 비치도록 alpha를 낮추고
                // 블러로 아래 폼 콘텐츠의 형태만 남긴다. ClipRect가 없으면
                // BackdropFilter의 블러 대상이 화면 전체로 번진다.
                // 하단 여백: 이 Stack은 SafeArea 안에 있어 home indicator
                // 만큼 이미 올라와 있으므로 MediaQuery bottom을 더하면
                // 이중 패딩이 된다(리뷰 지적). 고정 여백만 준다.
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        ClosetimoSpacing.lg,
                        ClosetimoSpacing.md,
                        ClosetimoSpacing.lg,
                        ClosetimoSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color:
                            surfaces.containerLowest.withValues(alpha: 0.72),
                      ),
                      child: PrimaryButton(
                        label: _isEdit ? '수정 완료' : '등록하기',
                        trailing: const Icon(Icons.check_rounded),
                        onPressed: _draft.canSave && !_saving ? _save : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ClosetimoSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ClosetimoColors.muted,
            ),
          ),
          if (required) ...[
            const Spacer(),
            const Text(
              'REQUIRED',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                letterSpacing: 2,
                color: ClosetimoColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 구매일 선택 필드. 탭하면 날짜 피커를 띄운다(002 FR-002). 값이 없으면
/// 안내 문구를 보여준다. _FieldInput과 동일한 surface-container-low 스타일.
class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final hasValue = value != null;
    return Material(
      color: surfaces.containerLow,
      borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? formatFullDate(value!) : '구매일 선택',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: hasValue ? ClosetimoColors.ink : ClosetimoColors.muted,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: ClosetimoColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldInput extends StatefulWidget {
  const _FieldInput({
    required this.initial,
    required this.hint,
    required this.onChanged,
  });

  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_FieldInput> createState() => _FieldInputState();
}

class _FieldInputState extends State<_FieldInput> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return TextField(
      controller: _ctl,
      onChanged: widget.onChanged,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        color: ClosetimoColors.ink,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: surfaces.containerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
