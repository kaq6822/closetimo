// US1 T038 — 신규 옷 등록 화면. 002 T009 — editId로 수정 모드 겸용.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/action_guard.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/models/item_attributes.dart';
import '../../data/models/item_patch.dart';
import '../../data/models/item_tags.dart';
import '../../data/providers/app_providers.dart';
import '../../data/suggestions/attribute_suggester.dart';
import 'new_item_draft.dart';
import 'widgets/attribute_pickers.dart';
import 'widgets/care_method_picker.dart';
import 'widgets/category_picker.dart';
import 'widgets/photo_picker_card.dart';
import 'widgets/tag_input.dart';
import 'widgets/wash_cycle_stepper.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({this.editId, super.key});

  /// null이면 등록 모드, 그 외에는 해당 옷의 수정 모드(002 FR-001).
  final int? editId;

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

/// 진행 표시를 그릴 저장 버튼 구분(#48).
enum _SaveAction { save, saveAndNext, batch }

/// 005 — 제안이 채울 수 있는 속성 축.
enum _Axis { category, subType, colors, seasons, material, pattern }

/// 축 값의 출처 순위. 높은 순위 값은 낮은 순위 제안으로 덮어쓰지 않는다(FR-517).
abstract final class _Rank {
  static const none = 0;
  static const photo = 1;
  static const name = 2;
  static const user = 3;
}

/// 여러 장 등록 최대 장수(FR-505).
const int maxBatchPhotos = 30;

class _AddItemScreenState extends ConsumerState<AddItemScreen>
    with ActionGuardMixin {
  NewItemDraft _draft = const NewItemDraft();

  /// 수정 모드의 dirty 판정 기준. 진입 시 원본 값으로 채워진다.
  NewItemDraft _initialDraft = const NewItemDraft();

  /// 수정 모드에서 로드된 기존 사진의 sandbox 절대 경로(표시용).
  String? _existingImagePath;

  /// 사용자가 "사진 제거"를 선택했는지(수정 모드).
  bool _photoCleared = false;

  bool get _isEdit => widget.editId != null;

  /// 등록 모드 dirty 판정 기준. 연속 등록 후에는 직전 카테고리만 유지한 빈 폼이다.
  NewItemDraft _blankDraft = const NewItemDraft();

  /// "추가 정보 (선택)" 펼침 여부. 등록 모드는 접힘, 수정 모드는 펼침으로 시작한다.
  late bool _optionalExpanded = _isEdit;

  /// 연속 등록 시 텍스트 필드를 새 controller로 다시 만들기 위한 세대 번호.
  int _formGeneration = 0;

  final ScrollController _scroll = ScrollController();

  /// 로딩 완료 여부(수정 모드 진입 시 옷을 fetch하는 동안 false).
  bool _loading = false;

  /// 005 — 축별 값의 출처([_Rank]). 사용자 > 이름 > 사진 순.
  final Map<_Axis, int> _axisRank = {};

  /// 005 — 사진 분석 중인지(사진 카드 진행 표시).
  bool _analyzing = false;

  /// 005 — 사진을 바꿀 때마다 올려 이전 사진의 늦은 분석 결과를 버린다.
  int _photoGeneration = 0;

  /// 005 — 수정 모드의 기존 배경 제거본 절대 경로.
  String? _existingCutoutPath;

  /// 005 — 수정 모드에서 "원본 사진 사용"을 골랐는지.
  bool _cutoutCleared = false;

  /// 005 — 이 화면의 분석이 만든 임시 배경 제거본 경로(화면을 떠날 때 지운다).
  final Set<String> _tempCutouts = {};

  /// 005 — 여러 장 선택기가 열려 있는지.
  bool _pickingBatch = false;

  /// 005 — 지금 사진의 마지막 분석 제안. 이름에서 채웠던 값을 되돌릴 때 사진 제안을 다시 적용한다.
  AttributeSuggestion _photoSuggestion = AttributeSuggestion.empty;

  /// 005 — 사진 분석이 색상을 골라 두었는지(안내 문구 표시용).
  bool get _colorsFromPhoto =>
      _axisRank[_Axis.colors] == _Rank.photo && _draft.colors.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loading = true;
      _loadForEdit();
    }
    // FR-515 — 기기 내 AI를 쓰는 사용자는 첫 분석 지연을 줄이려고 모델을 미리 깨운다.
    final prefs = ref.read(preferencesStreamProvider).valueOrNull;
    ref
        .read(attributeSuggesterProvider)
        .prewarm(useOnDeviceAi: prefs?.onDeviceAi ?? false);
  }

  @override
  void dispose() {
    _scroll.dispose();
    // 분석이 만든 임시 배경 제거본을 정리한다. 저장한 것은 이미 sandbox로 복사됐다.
    for (final path in _tempCutouts) {
      _deleteTemp(File(path));
    }
    super.dispose();
  }

  /// 임시 파일을 지운다(best-effort).
  static void _deleteTemp(File? file) {
    try {
      if (file != null && file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('Failed to delete temp cutout: $e');
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
    String? cutoutAbs;
    final store = ref.read(imageStoreProvider);
    final imagePath = item.imagePath;
    if (imagePath != null) {
      existingAbs = await store.absolutePath(imagePath);
    }
    final cutoutPath = item.cutoutPath;
    if (cutoutPath != null) cutoutAbs = await store.absolutePath(cutoutPath);
    if (!mounted) return;
    setState(() {
      _draft = draft;
      _initialDraft = draft;
      _existingImagePath = existingAbs;
      _existingCutoutPath = cutoutAbs;
      _loading = false;
      // 이미 저장된 속성은 사용자가 정한 값으로 보고 제안이 덮어쓰지 않는다.
      if (draft.category != Category.uncategorized) {
        _axisRank[_Axis.category] = _Rank.user;
      }
      if (draft.subType != null) _axisRank[_Axis.subType] = _Rank.user;
      if (draft.colors.isNotEmpty) _axisRank[_Axis.colors] = _Rank.user;
      if (draft.seasons.isNotEmpty) _axisRank[_Axis.seasons] = _Rank.user;
      if (draft.material != null) _axisRank[_Axis.material] = _Rank.user;
      if (draft.pattern != null) _axisRank[_Axis.pattern] = _Rank.user;
    });
  }

  /// 폼에 변경 사항이 있는지. 등록 모드는 빈 폼과 비교, 수정 모드는 원본과 비교.
  bool get _isDirty {
    if (!_isEdit) return _draft != _blankDraft;
    return _draft != _initialDraft || _photoCleared || _cutoutCleared;
  }

  /// 저장 가능 여부. 수정 모드는 변경이 있을 때만 활성(#24, 등록 화면과 일관).
  /// 등록 모드는 명칭 또는 사진만 있으면 된다(#42 FR-002). 저장 진행 중에는
  /// 모든 저장 버튼을 막아 중복 생성을 차단한다(FR-001b).
  bool get _canSubmit =>
      !actionBusy &&
      _isDirty &&
      (_isEdit ? _draft.canSave : _draft.canQuickSave);

  void _pickPhoto(File file) {
    setState(() {
      _photoSuggestion = AttributeSuggestion.empty;
      _draft = _draft.copyWith(tempPhoto: file, tempCutout: null);
      _photoCleared = false;
      _cutoutCleared = false;
    });
    _analyzePhoto(file);
  }

  /// 005 FR-504·513~515 — 사진을 분석해 배경 제거본과 속성 제안을 붙인다.
  /// 실패해도 등록 흐름은 그대로다(SC-504).
  Future<void> _analyzePhoto(File file) async {
    final generation = ++_photoGeneration;
    final prefs = ref.read(preferencesStreamProvider).valueOrNull;
    setState(() => _analyzing = true);
    final result = await ref
        .read(attributeSuggesterProvider)
        .analyzePhoto(
          file,
          removeBackground: prefs?.removeBackground ?? true,
          useOnDeviceAi: prefs?.onDeviceAi ?? false,
        );
    // 화면을 떠났으면 임시 배경 제거본을 바로 지운다(dispose가 이미 지나갔다).
    if (!mounted) {
      _deleteTemp(result.cutout);
      return;
    }
    if (result.cutout case final c?) _tempCutouts.add(c.path);
    // 그사이 사진을 바꾸거나 지웠으면 이 결과는 버린다.
    if (generation != _photoGeneration) return;
    setState(() {
      _analyzing = false;
      if (_draft.tempPhoto?.path == file.path) {
        _draft = _draft.copyWith(tempCutout: result.cutout);
      }
      _photoSuggestion = result.suggestion;
      _applySuggestion(result.suggestion, _Rank.photo);
    });
  }

  /// [s]를 순위 [rank]로 비어 있거나 더 낮은 순위의 축에만 적용한다. setState 안에서 부른다.
  void _applySuggestion(AttributeSuggestion s, int rank) {
    bool can(_Axis a) {
      final current = _axisRank[a] ?? _Rank.none;
      return current < _Rank.user && current <= rank;
    }

    var d = _draft;
    // 사용자가 고른 세부 종류와 맞지 않는 종류로는 바꾸지 않는다(그 세부 종류가 지워진다).
    final keepsUserSubType =
        _axisRank[_Axis.subType] == _Rank.user && d.subType != null;
    if (s.category case final c?
        when can(_Axis.category) &&
            c != d.category &&
            (!keepsUserSubType ||
                ItemAttributes.normalizeSubType(c, d.subType) != null)) {
      d = d.copyWith(
        category: c,
        subType: ItemAttributes.normalizeSubType(c, d.subType),
      );
      _axisRank[_Axis.category] = rank;
    }
    final sub = ItemAttributes.normalizeSubType(d.category, s.subType);
    if (sub != null && can(_Axis.subType)) {
      d = d.copyWith(subType: sub);
      _axisRank[_Axis.subType] = rank;
    }
    if (s.colors.isNotEmpty && can(_Axis.colors)) {
      d = d.copyWith(colors: s.colors);
      _axisRank[_Axis.colors] = rank;
    }
    if (s.seasons.isNotEmpty && can(_Axis.seasons)) {
      d = d.copyWith(seasons: s.seasons);
      _axisRank[_Axis.seasons] = rank;
    }
    if (s.material != null && can(_Axis.material)) {
      d = d.copyWith(material: s.material);
      _axisRank[_Axis.material] = rank;
    }
    if (s.pattern != null && can(_Axis.pattern)) {
      d = d.copyWith(pattern: s.pattern);
      _axisRank[_Axis.pattern] = rank;
    }
    _draft = d;
  }

  /// 사용자가 직접 바꾼 축은 이후 제안이 덮어쓰지 않는다. 세부 종류를 고르면 그 종류도
  /// 사용자가 정한 것으로 본다.
  void _setByUser(_Axis axis, NewItemDraft next) {
    setState(() {
      _draft = next;
      _axisRank[axis] = _Rank.user;
      if (axis == _Axis.subType && next.subType != null) {
        _axisRank[_Axis.category] = _Rank.user;
      }
    });
  }

  /// 이름에서만 채웠던 축 중 새 이름에 더는 근거가 없는 축을 비운다(이름을 고치거나 지울 때).
  void _clearStaleNameAxes(AttributeSuggestion s) {
    bool fromName(_Axis a) => _axisRank[a] == _Rank.name;
    var d = _draft;
    if (fromName(_Axis.category) && s.category == null) {
      d = d.copyWith(
        category: Category.uncategorized,
        subType: _axisRank[_Axis.subType] == _Rank.user ? d.subType : null,
      );
      _axisRank.remove(_Axis.category);
    }
    if (fromName(_Axis.subType) && s.subType == null) {
      d = d.copyWith(subType: null);
      _axisRank.remove(_Axis.subType);
    }
    if (fromName(_Axis.colors) && s.colors.isEmpty) {
      d = d.copyWith(colors: const []);
      _axisRank.remove(_Axis.colors);
    }
    if (fromName(_Axis.material) && s.material == null) {
      d = d.copyWith(material: null);
      _axisRank.remove(_Axis.material);
    }
    if (fromName(_Axis.pattern) && s.pattern == null) {
      d = d.copyWith(pattern: null);
      _axisRank.remove(_Axis.pattern);
    }
    _draft = d;
  }

  void _onNameChanged(String v) {
    setState(() {
      _draft = _draft.copyWith(name: v);
      // FR-503 — 등록 모드에서만 이름 키워드로 비어 있는 축을 채운다. 수정 모드는
      // 이미 정리된 옷이라 이름만 고쳐도 속성이 바뀌면 의도치 않은 변경이 된다.
      if (!_isEdit) {
        final s = AttributeSuggestion.fromName(v);
        _clearStaleNameAxes(s);
        // 이름이 비운 축에는 사진 제안을 되살린다(이름 > 사진 순위는 그대로).
        _applySuggestion(_photoSuggestion, _Rank.photo);
        _applySuggestion(s, _Rank.name);
      }
    });
  }

  void _removePhoto() {
    _photoGeneration++; // 진행 중인 분석 결과를 버린다.
    setState(() {
      _analyzing = false;
      _photoSuggestion = AttributeSuggestion.empty;
      _draft = _draft.copyWith(tempPhoto: null, tempCutout: null);
      // 원본 사진이 있었을 때만 "제거" 의도가 유의미하다. 원본이 없는데
      // 새로 골랐다 지운 경우는 순변화 없음이므로 dirty로 오판하지 않는다.
      _photoCleared = _existingImagePath != null;
    });
  }

  /// 005 FR-513 — 배경 제거본을 버리고 원본을 쓴다.
  void _useOriginalPhoto() {
    setState(() {
      if (_draft.tempCutout != null) {
        _draft = _draft.copyWith(tempCutout: null);
      } else {
        _cutoutCleared = _existingCutoutPath != null;
      }
    });
  }

  /// 005 FR-505 — 앨범에서 여러 장을 골라 옷을 한 번에 만들고 정리하기로 넘어간다.
  /// 빠른 분석(배경 제거·색상·분류 힌트)만 쓰고 기기 내 AI는 쓰지 않는다(장당 수 초).
  Future<void> _batchImport() async {
    // 빠른 연속 탭으로 선택기가 두 번 열리지 않게 막는다(already_active 오류).
    if (_pickingBatch || actionBusy) return;
    _pickingBatch = true;
    final List<XFile> picked;
    try {
      picked = await ImagePicker().pickMultiImage(
        limit: maxBatchPhotos,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      debugPrint('Batch photo picker failed: ${e.code}');
      if (mounted) {
        showClosetimoToast(
          context,
          '사진을 불러오지 못했어요. 사진 접근 권한을 확인해 주세요.',
          isError: true,
        );
      }
      return;
    } finally {
      _pickingBatch = false;
    }
    if (picked.isEmpty || !mounted) return;
    final files = picked.take(maxBatchPhotos).map((x) => File(x.path)).toList();
    final progress = ValueNotifier<int>(0);
    final ids = <int>[];
    var failed = 0;
    await runGuarded(
      () async {
        // 진행 대화상자는 루프가 끝나면 직접 닫으므로 기다리지 않는다.
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                _BatchProgressDialog(progress: progress, total: files.length),
          ),
        );
        final repo = ref.read(itemRepositoryProvider);
        final suggester = ref.read(attributeSuggesterProvider);
        final prefs = ref.read(preferencesStreamProvider).valueOrNull;
        try {
          for (final file in files) {
            File? tempCutout;
            try {
              final analysis = await suggester.analyzePhoto(
                file,
                removeBackground: prefs?.removeBackground ?? true,
                useOnDeviceAi: false,
              );
              tempCutout = analysis.cutout;
              final s = analysis.suggestion;
              final category = s.category ?? Category.uncategorized;
              final draft = NewItemDraft(
                category: category,
                subType: ItemAttributes.normalizeSubType(category, s.subType),
                colors: s.colors,
                seasons: s.seasons,
                material: s.material,
                pattern: s.pattern,
                tempPhoto: file,
                tempCutout: analysis.cutout,
              ).forCreate();
              ids.add(await repo.create(draft));
            } catch (e) {
              failed++;
              debugPrint('Batch import failed for ${file.path}: $e');
            } finally {
              // 성공하면 저장소가 sandbox로 복사했고, 실패하면 쓸 일이 없다.
              _deleteTemp(tempCutout);
            }
            progress.value++;
          }
        } finally {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
        }
      },
      tag: _SaveAction.batch,
      failureMessage: '사진을 등록하지 못했어요. 다시 시도해 주세요.',
    );
    progress.dispose();
    if (!mounted) return;
    if (ids.isEmpty) {
      showClosetimoToast(context, '사진을 등록하지 못했어요. 다시 시도해 주세요.', isError: true);
      return;
    }
    showClosetimoToast(
      context,
      failed == 0
          ? '${ids.length}벌을 만들었어요. 하나씩 정리해 볼까요?'
          : '${ids.length}벌을 만들었어요. $failed장은 등록하지 못했어요',
      placement: ToastPlacement.top,
    );
    context.pushReplacementNamed(
      Routes.sortItems,
      queryParameters: {'ids': ids.join(',')},
    );
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
  /// [next]가 true면(등록 모드 전용) 저장 후 화면을 유지하고 폼을 비운다(FR-001a).
  /// #48 FR-030 — 저장 중에는 다른 저장을 막고(공용 액션 가드), 실패하면 입력을
  /// 유지한 채 오류 토스트를 띄운다.
  Future<void> _save({bool next = false}) async {
    if (!_canSubmit) return;
    await runGuarded(
      () => _persist(next: next),
      tag: next ? _SaveAction.saveAndNext : _SaveAction.save,
      failureMessage: _isEdit
          ? '수정에 실패했어요. 다시 시도해 주세요.'
          : '등록에 실패했어요. 다시 시도해 주세요.',
      // #22 N-02 — 실패 시 수정 화면에 머물고 하단 CTA를 가리지 않도록 상단.
      placement: _isEdit ? ToastPlacement.top : ToastPlacement.bottom,
    );
  }

  Future<void> _persist({required bool next}) async {
    final repo = ref.read(itemRepositoryProvider);
    final String message;
    if (_isEdit) {
      final photoChanged =
          _draft.tempPhoto != null ||
          _photoCleared ||
          _cutoutCleared ||
          _draft.tempCutout != null;
      await repo.update(
        widget.editId!,
        ItemPatch(
          name: _draft.name,
          brand: _draft.brand,
          category: _draft.category,
          careMethod: _draft.careMethod,
          washCycle: _draft.washCycle,
          careMode: _draft.careMode,
          purposes: _draft.purposes,
          purchasedAt: _draft.purchasedAt,
          newPhoto: _draft.tempPhoto,
          removePhoto: _photoCleared,
          tags: _draft.tags,
          attributes: _draft.attributes,
          newCutout: _draft.tempCutout,
          removeCutout: _cutoutCleared,
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
      await repo.create(_draft.forCreate());
      message = next ? '저장했어요. 다음 옷을 등록해 주세요' : '새 옷이 옷장에 등록됐어요';
    }
    if (!context.mounted) return;
    if (next) {
      // FR-001a — 같은 입력이 다시 저장되지 않도록 성공 직후 폼을 비운다.
      // 직전 카테고리는 같은 종류를 연달아 등록하기 쉽게 유지한다.
      final blank = NewItemDraft(category: _draft.category);
      _photoGeneration++;
      setState(() {
        _blankDraft = blank;
        _draft = blank;
        _formGeneration++;
        _analyzing = false;
        _photoSuggestion = AttributeSuggestion.empty;
        final keepsCategory = _axisRank[_Axis.category] == _Rank.user;
        _axisRank.clear();
        if (keepsCategory) _axisRank[_Axis.category] = _Rank.user;
      });
      if (_scroll.hasClients) _scroll.jumpTo(0);
      // 하단 CTA 바를 가리지 않도록 상단에 띄운다.
      showClosetimoToast(context, message, placement: ToastPlacement.top);
      return;
    }
    // #22 N-02 — 수정은 하단 탭이 없는 상세로 돌아가 하단 토스트가
    // "착용 기록하기" 등을 덮으므로 상단에 띄운다. 신규 등록은 옷장 등 탭 화면으로
    // 돌아가므로 하단 탭 위(기본)를 유지한다.
    showClosetimoToast(
      context,
      message,
      placement: _isEdit ? ToastPlacement.top : ToastPlacement.bottom,
    );
    context.pop();
  }

  /// 이름 칸 안내. 등록 모드에서 이름을 비우면 자동 이름으로 저장됨을 알린다(FR-502).
  String get _nameNote {
    if (_isEdit) return '필수';
    if (_draft.name.trim().isNotEmpty) return '';
    final auto = _draft.autoName;
    return auto == NewItemDraft.untitledName
        ? '이름 또는 사진 중 하나만 있어도 돼요'
        : "비워 두면 '$auto'(으)로 저장돼요";
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    // #46 — 이미 쓴 태그(많이 쓴 순)를 입력 제안으로 쓴다.
    final usages = ref.watch(tagUsageProvider).valueOrNull;
    final tagSuggestions = [
      for (final u in usages ?? const <TagUsage>[]) u.name,
    ];
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
                      onPressed: _canSubmit ? _save : null,
                      child: const Text('저장'),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                        ClosetimoSpacing.lg,
                        ClosetimoSpacing.md,
                        ClosetimoSpacing.lg,
                        // 등록 모드는 하단 바에 연속 등록 버튼이 더해진다.
                        _isEdit
                            ? ClosetimoSpacing.space120
                            : ClosetimoSpacing.space120 +
                                  ClosetimoSpacing.space52,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PhotoPickerCard(
                            tempPhoto: _draft.tempPhoto,
                            tempCutout: _draft.tempCutout,
                            existingImagePath:
                                (_photoCleared || _draft.tempPhoto != null)
                                ? null
                                : _existingImagePath,
                            existingCutoutPath:
                                (_photoCleared ||
                                    _cutoutCleared ||
                                    _draft.tempPhoto != null)
                                ? null
                                : _existingCutoutPath,
                            analyzing: _analyzing,
                            onPicked: _pickPhoto,
                            onRemove: _isEdit ? _removePhoto : null,
                            onUseOriginal: _useOriginalPhoto,
                          ),
                          // FR-505 — 빈 폼에서만 여러 장 등록을 제안한다(입력 유실 방지).
                          if (!_isEdit && !_isDirty)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: actionBusy ? null : _batchImport,
                                icon: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 18,
                                ),
                                label: const Text('여러 장 한 번에 등록'),
                              ),
                            )
                          else
                            const SizedBox(height: ClosetimoSpacing.lg),
                          _FieldLabel(label: '의류 명칭', note: _nameNote),
                          _FieldInput(
                            key: ValueKey('name-$_formGeneration'),
                            label: '의류 명칭',
                            initial: _draft.name,
                            hint: '예) 베이지 울 코트',
                            onChanged: _onNameChanged,
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '종류', note: '선택'),
                          CategoryPicker(
                            value: _draft.category,
                            onChanged: (c) => _setByUser(
                              _Axis.category,
                              _draft.copyWith(
                                category: c,
                                subType: ItemAttributes.normalizeSubType(
                                  c,
                                  _draft.subType,
                                ),
                              ),
                            ),
                          ),
                          if (ItemAttributes.subTypesOf(
                            _draft.category,
                          ).isNotEmpty) ...[
                            const SizedBox(height: ClosetimoSpacing.lg),
                            const _FieldLabel(label: '세부 종류', note: '선택'),
                            SubTypePicker(
                              category: _draft.category,
                              value: _draft.subType,
                              onChanged: (v) => _setByUser(
                                _Axis.subType,
                                _draft.copyWith(subType: v),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: ClosetimoSpacing.sm),
                            const _FieldHint('아직 정하지 않았다면 미분류로 두어도 돼요.'),
                          ],
                          const SizedBox(height: ClosetimoSpacing.lg),
                          _FieldLabel(
                            label: '색상',
                            note: _colorsFromPhoto
                                ? '사진에서 골랐어요. 맞지 않으면 바꿔 주세요'
                                : '최대 3개, 첫 색이 대표 색',
                          ),
                          ColorPicker(
                            value: _draft.colors,
                            onChanged: (v) => _setByUser(
                              _Axis.colors,
                              _draft.copyWith(colors: v),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '계절', note: '선택'),
                          SeasonPicker(
                            value: _draft.seasons,
                            suggested:
                                ItemAttributes.subType(
                                  _draft.subType,
                                )?.seasons ??
                                const {},
                            onChanged: (v) => _setByUser(
                              _Axis.seasons,
                              _draft.copyWith(seasons: v),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          const _FieldLabel(label: '용도', note: '선택'),
                          PurposePicker(
                            value: _draft.purposes,
                            onChanged: (p) => setState(
                              () => _draft = _draft.copyWith(purposes: p),
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.lg),
                          _OptionalSectionHeader(
                            expanded: _optionalExpanded,
                            onTap: () => setState(
                              () => _optionalExpanded = !_optionalExpanded,
                            ),
                          ),
                          if (_optionalExpanded) ...[
                            const SizedBox(height: ClosetimoSpacing.md),
                            const _FieldLabel(label: '브랜드'),
                            _FieldInput(
                              key: ValueKey('brand-$_formGeneration'),
                              label: '브랜드',
                              initial: _draft.brand,
                              hint: '예) ZARA',
                              onChanged: (v) => setState(
                                () => _draft = _draft.copyWith(brand: v),
                              ),
                            ),
                            const SizedBox(height: ClosetimoSpacing.lg),
                            const _FieldLabel(label: '소재'),
                            SingleAttributePicker(
                              options: ItemAttributes.materials,
                              value: _draft.material,
                              onChanged: (v) => _setByUser(
                                _Axis.material,
                                _draft.copyWith(material: v),
                              ),
                            ),
                            const SizedBox(height: ClosetimoSpacing.lg),
                            const _FieldLabel(label: '패턴'),
                            SingleAttributePicker(
                              options: ItemAttributes.patterns,
                              value: _draft.pattern,
                              onChanged: (v) => _setByUser(
                                _Axis.pattern,
                                _draft.copyWith(pattern: v),
                              ),
                            ),
                            const SizedBox(height: ClosetimoSpacing.lg),
                            // #46 — 사용자 태그(선택). 이미 쓴 태그를 제안한다.
                            const _FieldLabel(
                              label: '태그',
                              note: '장소·상황 등 자유롭게',
                            ),
                            TagInput(
                              key: ValueKey('tags-$_formGeneration'),
                              value: _draft.tags,
                              suggestions: tagSuggestions,
                              onChanged: (t) => setState(
                                () => _draft = _draft.copyWith(tags: t),
                              ),
                            ),
                            const SizedBox(height: ClosetimoSpacing.lg),
                            const _FieldLabel(label: '세탁 주기 설정'),
                            // #45 — 횟수 기반 관리 적용 여부. 끄면 주기 값은 보존한다.
                            _CareModeSwitch(
                              value: _draft.careMode == CareMode.wearCycle,
                              onChanged: (on) => setState(
                                () => _draft = _draft.copyWith(
                                  careMode: on
                                      ? CareMode.wearCycle
                                      : CareMode.manual,
                                ),
                              ),
                            ),
                            if (_draft.careMode == CareMode.wearCycle) ...[
                              const SizedBox(height: ClosetimoSpacing.sm),
                              WashCycleStepper(
                                value: _draft.washCycle,
                                onChanged: (v) => setState(
                                  () => _draft = _draft.copyWith(washCycle: v),
                                ),
                              ),
                            ],
                            const SizedBox(height: ClosetimoSpacing.sm),
                            _FieldHint(
                              _draft.careMode == CareMode.wearCycle
                                  ? "설정한 횟수만큼 착용하면 '세탁 필요'로 표시돼요."
                                  : '횟수와 관계없이 필요할 때 세탁 바구니에 직접 담아요.',
                            ),
                            const SizedBox(height: ClosetimoSpacing.lg),
                            const _FieldLabel(label: '세탁 방법'),
                            CareMethodPicker(
                              value: _draft.careMethod,
                              onChanged: (m) => setState(
                                () => _draft = _draft.copyWith(careMethod: m),
                              ),
                            ),
                            const SizedBox(height: ClosetimoSpacing.sm),
                            const _FieldHint(
                              '실제 세탁 조건은 옷의 케어 라벨을 따라 주세요. '
                              '모르면 미지정으로 두어도 돼요.',
                            ),
                            const SizedBox(height: ClosetimoSpacing.lg),
                            const _FieldLabel(label: '구매일'),
                            _DateField(
                              value: _draft.purchasedAt,
                              onTap: _pickPurchaseDate,
                            ),
                          ],
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
                        color: surfaces.containerLowest.withValues(alpha: 0.72),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PrimaryButton(
                            label: isActionBusy(_SaveAction.save)
                                ? '저장 중…'
                                : (_isEdit ? '수정 완료' : '등록하기'),
                            trailing: const Icon(Icons.check_rounded),
                            busy: isActionBusy(_SaveAction.save),
                            onPressed: _canSubmit ? _save : null,
                          ),
                          // FR-001a — 여러 벌을 이어서 등록하는 보조 액션.
                          if (!_isEdit)
                            TextButton(
                              onPressed: _canSubmit
                                  ? () => _save(next: true)
                                  : null,
                              child: Text(
                                isActionBusy(_SaveAction.saveAndNext)
                                    ? '저장 중…'
                                    : '저장하고 다음 옷 등록',
                              ),
                            ),
                        ],
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
  const _FieldLabel({required this.label, this.note});

  final String label;

  /// 라벨 오른쪽의 필수/선택 안내 문구(#42 — 선택 정보임을 분명히 한다).
  final String? note;

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
          if (note != null) ...[
            const SizedBox(width: ClosetimoSpacing.sm),
            Expanded(
              child: Text(
                note!,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: ClosetimoColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "추가 정보 (선택)" 접이식 헤더(#42). 브랜드·태그(#46)·세탁 주기·세탁 방법·구매일을
/// 접어 두어 처음 등록할 때 모두 채워야 한다는 부담을 줄인다.
class _OptionalSectionHeader extends StatelessWidget {
  const _OptionalSectionHeader({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Semantics(
      button: true,
      expanded: expanded,
      child: Material(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClosetimoSpacing.space18,
              vertical: ClosetimoSpacing.space14,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '추가 정보 (선택)',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ClosetimoColors.ink,
                        ),
                      ),
                      SizedBox(height: ClosetimoSpacing.space2),
                      Text(
                        '브랜드 · 소재 · 패턴 · 태그 · 세탁 주기 · 세탁 방법 · 구매일',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: ClosetimoColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: ClosetimoColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 필드 아래 보조 안내 문구.
class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: ClosetimoSpacing.xs),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: ClosetimoColors.muted,
        ),
      ),
    );
  }
}

/// #45 — 착용 횟수 기준 관리 적용 스위치. 행 전체를 하나의 토글로 읽힌다.
class _CareModeSwitch extends StatelessWidget {
  const _CareModeSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Material(
      color: surfaces.containerLow,
      borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: ClosetimoColors.onPrimary,
          activeTrackColor: ClosetimoColors.primary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ClosetimoSpacing.md,
          ),
          title: const Text(
            '착용 횟수로 관리',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ClosetimoColors.ink,
            ),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: ClosetimoSpacing.space18,
            vertical: ClosetimoSpacing.space16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? formatFullDate(value!) : '구매일 선택',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: hasValue
                        ? ClosetimoColors.ink
                        : ClosetimoColors.muted,
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
    required this.label,
    super.key,
    required this.initial,
    required this.hint,
    required this.onChanged,
  });

  /// 스크린리더가 읽을 필드 이름. 화면의 _FieldLabel과 같은 문구(#17).
  final String label;
  final String initial;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_FieldInput> createState() => _FieldInputState();
}

class _FieldInputState extends State<_FieldInput> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    // #17 — 힌트("e.g. …")만으로는 필드 이름을 알 수 없어 라벨을 붙인다.
    return Semantics(
      label: widget.label,
      child: TextField(
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
            horizontal: ClosetimoSpacing.space18,
            vertical: ClosetimoSpacing.space16,
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
      ),
    );
  }
}

/// 005 FR-505 — 여러 장 등록 진행 표시(닫을 수 없음).
class _BatchProgressDialog extends StatelessWidget {
  const _BatchProgressDialog({required this.progress, required this.total});

  final ValueNotifier<int> progress;
  final int total;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (context, done, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: total == 0 ? null : done / total),
              const SizedBox(height: ClosetimoSpacing.md),
              Text(
                '사진 정리 중… $done / $total',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: ClosetimoColors.ink,
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.xs),
              const Text(
                '배경을 지우고 색상을 고르고 있어요',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: ClosetimoColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
