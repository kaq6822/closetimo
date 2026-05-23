// US1 T038 — 신규 옷 등록 화면. 디자인 패키지의 add.jsx와 1:1 매핑.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/providers/app_providers.dart';
import 'new_item_draft.dart';
import 'widgets/care_method_picker.dart';
import 'widgets/category_picker.dart';
import 'widgets/photo_picker_card.dart';
import 'widgets/wash_cycle_stepper.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  NewItemDraft _draft = const NewItemDraft();
  bool _saving = false;

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (_draft == const NewItemDraft()) return true;
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
      await repo.create(_draft);
      message = '새 옷이 옷장에 등록됐어요';
      success = true;
    } catch (_) {
      message = '등록에 실패했어요';
    }
    if (!context.mounted) return;
    showClosetimoToast(context, message);
    if (success) context.pop();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return PopScope(
      // 빈 폼이면 자유롭게 pop, dirty일 때만 시스템 back을 가로채 다이얼로그를 띄운다.
      // canPop:false를 무조건 켜두면 go_router의 명시적 context.pop()까지 차단된다.
      canPop: _draft == const NewItemDraft(),
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
                    subtitle: '신규 옷 등록',
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
                            onPicked: (f) =>
                                setState(() => _draft = _draft.copyWith(tempPhoto: f)),
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
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    ClosetimoSpacing.lg,
                    ClosetimoSpacing.md,
                    ClosetimoSpacing.lg,
                    MediaQuery.paddingOf(context).bottom + ClosetimoSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: surfaces.containerLowest.withValues(alpha: 0.92),
                  ),
                  child: PrimaryButton(
                    label: '등록하기',
                    trailing: const Icon(Icons.check_rounded),
                    onPressed: _draft.canSave && !_saving ? _save : null,
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
