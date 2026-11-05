// 005 FR-506 — 정리하기: 옷을 한 벌씩 카드로 보여 주고 칩만 눌러 분류한다(SC-501).
// 진입: 여러 장 등록 직후(`ids`), 홈 "정리 대기 N벌"(ids 없음 = 활성 미분류 전체).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/action_guard.dart';
import '../../core/widgets/item_photo.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/models/item_attributes.dart';
import '../../data/models/item_patch.dart';
import '../../data/providers/app_providers.dart';
import 'batch_suggestions.dart';
import 'widgets/attribute_pickers.dart';
import 'widgets/category_picker.dart';

/// `/sort-items?ids=1,2,3` 쿼리를 해석한다. 없거나 비면 null(활성 미분류 전체).
List<int>? parseSortItemIds(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final ids = <int>[];
  for (final part in raw.split(',')) {
    final id = int.tryParse(part.trim());
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids.isEmpty ? null : ids;
}

/// 이름이 자동으로 만든 이름(또는 기본 이름)이면 속성이 바뀔 때 다시 만든다.
bool hasAutoName(Item item) =>
    item.name == untitledItemName ||
    item.name ==
        autoItemName(
          category: item.category,
          subType: item.subType,
          colors: item.colors,
        );

class SortItemsScreen extends ConsumerStatefulWidget {
  const SortItemsScreen({this.ids, super.key});

  /// 정리할 옷 id(순서 유지). null이면 활성 미분류 옷 전체를 등록 순으로.
  final List<int>? ids;

  @override
  ConsumerState<SortItemsScreen> createState() => _SortItemsScreenState();
}

class _SortItemsScreenState extends ConsumerState<SortItemsScreen>
    with ActionGuardMixin {
  List<int>? _queue;
  int _index = 0;
  int _sorted = 0;
  Item? _item;

  // 카드에서 고른 값.
  Category _category = Category.uncategorized;
  String? _subType;
  List<String> _colors = const [];
  List<Season> _seasons = const [];
  List<ItemPurpose> _purposes = const [];

  /// 종류·세부 종류를 여러 장 등록의 사진 제안으로 미리 골랐는지(사용자가 바꾸면 false).
  bool _photoHint = false;

  final ScrollController _scroll = ScrollController();

  /// 화면을 닫는 중인지. 저장 완료와 뒤로 가기가 겹쳐 두 번 pop하지 않게 한다.
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    final repo = ref.read(itemRepositoryProvider);
    final List<int> queue;
    if (widget.ids case final ids?) {
      queue = ids;
    } else {
      final all = await repo.watchAll().first;
      final pending = [
        for (final i in all)
          if (!i.isArchived && i.category == Category.uncategorized) i,
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      queue = [for (final i in pending) i.id];
    }
    if (!mounted) return;
    setState(() => _queue = queue);
    // 정리할 옷이 없으면 빈 상태 안내를 보여 준다(바로 닫지 않는다).
    if (queue.isNotEmpty) await _show(0);
  }

  /// [index]번째 옷을 불러온다. 사라졌거나 보관한 옷은 건너뛴다.
  Future<void> _show(int index) async {
    final queue = _queue!;
    final repo = ref.read(itemRepositoryProvider);
    var i = index;
    Item? item;
    while (i < queue.length) {
      item = await repo.get(queue[i]);
      if (item != null && !item.isArchived) break;
      item = null;
      i++;
    }
    if (!mounted) return;
    if (item == null) {
      // 남은 옷이 모두 사라졌거나 보관됐다. 처음부터 하나도 없으면 빈 상태를 보인다.
      if (index == 0 && _sorted == 0) {
        setState(() => _queue = const []);
      } else {
        _finish();
      }
      return;
    }
    final found = item;
    // 미분류 옷이면 여러 장 등록의 사진 제안을 미리 선택한다. 저장은 사용자가 누를 때만 한다.
    final hint = found.category == Category.uncategorized
        ? ref.read(batchSuggestionsProvider)[found.id]
        : null;
    final hintCategory = hint?.category;
    setState(() {
      _index = i;
      _item = found;
      _photoHint = hintCategory != null;
      _category = hintCategory ?? found.category;
      _subType = hintCategory != null
          ? ItemAttributes.normalizeSubType(hintCategory, hint!.subType)
          : found.subType;
      _colors = found.colors;
      _seasons = found.seasons;
      _purposes = found.purposes;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool get _isLast => _queue != null && _index >= _queue!.length - 1;

  String get _previewName {
    final item = _item!;
    if (!hasAutoName(item)) return item.name;
    return autoItemName(
      category: _category,
      subType: _subType,
      colors: _colors,
    );
  }

  Future<void> _saveAndNext() async {
    final item = _item;
    if (item == null) return;
    await runGuarded(() async {
      await ref
          .read(itemRepositoryProvider)
          .update(
            item.id,
            ItemPatch(
              name: _previewName,
              brand: item.brand,
              category: _category,
              careMethod: item.careMethod,
              washCycle: item.washCycle,
              careMode: item.careMode,
              purposes: _purposes,
              purchasedAt: item.purchasedAt,
              attributes: ItemAttributeValues(
                subType: _subType,
                colors: _colors,
                seasons: _seasons,
                material: item.material,
                pattern: item.pattern,
              ),
            ),
          );
      _sorted++;
      ref
          .read(batchSuggestionsProvider.notifier)
          .update((m) => {...m}..remove(item.id));
      if (!mounted) return;
      if (_isLast) {
        _finish();
      } else {
        await _show(_index + 1);
      }
    }, failureMessage: '저장하지 못했어요. 다시 시도해 주세요.');
  }

  Future<void> _skip() async {
    if (_isLast) {
      _finish();
    } else {
      await _show(_index + 1);
    }
  }

  void _finish() {
    if (!mounted || _closing) return;
    _closing = true;
    if (_sorted > 0) showClosetimoToast(context, '$_sorted벌을 정리했어요');
    // pop 애니메이션 중에도 mounted는 true이므로 이 라우트가 맨 위일 때만 닫는다.
    if (ModalRoute.of(context)?.isCurrent ?? true) context.pop();
  }

  /// 뒤로 가기. 저장 중에는 막고(완료 후 _finish가 닫는다), 정리한 수를 알리며 닫는다.
  void _close() {
    if (actionBusy) return;
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;
    final item = _item;
    final total = queue?.length ?? 0;
    // 시스템 뒤로 가기도 저장 중에는 막고, 닫히면 이후 저장 완료가 다시 닫지 않게 한다.
    return PopScope(
      canPop: !actionBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _closing = true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                subtitle: '정리하기',
                onBack: _close,
                rightSlot: item == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(
                          right: ClosetimoSpacing.md,
                        ),
                        child: Text(
                          '${_index + 1} / $total',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: ClosetimoColors.muted,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: queue == null || (item == null && total > 0)
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : total == 0
                    ? const _EmptyQueue()
                    : _buildCard(context, item!),
              ),
              if (item != null) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Item item) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final suggestedSeasons =
        ItemAttributes.subType(_subType)?.seasons ?? const <Season>{};
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        ClosetimoSpacing.lg,
        ClosetimoSpacing.sm,
        ClosetimoSpacing.lg,
        ClosetimoSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
            child: SizedBox(
              height: ClosetimoSize.triagePhotoHeight,
              child: ColoredBox(
                color: surfaces.containerLow,
                child: ItemPhoto(
                  key: ValueKey('sort-photo-${item.id}'),
                  imagePath: item.displayImagePath,
                  cutout: item.showsCutout,
                  originalPath: item.imagePath,
                  fallback: Color(item.fallbackColor),
                  cacheWidth: 900,
                  cutoutPadding: ClosetimoSpacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.md),
          Text(
            _previewName,
            key: const ValueKey('sort-preview-name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ClosetimoColors.ink,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.lg),
          _SectionLabel(
            '종류',
            note: _photoHint ? '사진에서 골랐어요. 맞지 않으면 바꿔 주세요' : null,
          ),
          CategoryPicker(
            value: _category,
            onChanged: (c) => setState(() {
              _photoHint = false;
              _category = c;
              _subType = ItemAttributes.normalizeSubType(c, _subType);
            }),
          ),
          if (ItemAttributes.subTypesOf(_category).isNotEmpty) ...[
            const SizedBox(height: ClosetimoSpacing.lg),
            const _SectionLabel('세부 종류'),
            SubTypePicker(
              category: _category,
              value: _subType,
              onChanged: (v) => setState(() {
                _photoHint = false;
                _subType = v;
              }),
            ),
          ],
          const SizedBox(height: ClosetimoSpacing.lg),
          const _SectionLabel('색상', note: '최대 3개, 첫 색이 대표 색'),
          ColorPicker(
            value: _colors,
            onChanged: (v) => setState(() => _colors = v),
          ),
          const SizedBox(height: ClosetimoSpacing.lg),
          const _SectionLabel('계절'),
          SeasonPicker(
            value: _seasons,
            suggested: suggestedSeasons,
            onChanged: (v) => setState(() => _seasons = v),
          ),
          const SizedBox(height: ClosetimoSpacing.lg),
          const _SectionLabel('용도'),
          PurposePicker(
            value: _purposes,
            onChanged: (v) => setState(() => _purposes = v),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Container(
      color: surfaces.containerLowest,
      padding: const EdgeInsets.fromLTRB(
        ClosetimoSpacing.lg,
        ClosetimoSpacing.sm,
        ClosetimoSpacing.lg,
        ClosetimoSpacing.md,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: actionBusy ? null : _skip,
            child: const Text('나중에'),
          ),
          const SizedBox(width: ClosetimoSpacing.sm),
          Expanded(
            child: PrimaryButton(
              label: actionBusy ? '저장 중…' : (_isLast ? '저장하고 끝내기' : '저장하고 다음'),
              trailing: Icon(
                _isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              ),
              busy: actionBusy,
              onPressed: actionBusy ? null : _saveAndNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.note});

  final String label;
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

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ClosetimoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: ClosetimoColors.primary,
            ),
            const SizedBox(height: ClosetimoSpacing.md),
            const Text(
              '정리할 옷이 없어요',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ClosetimoColors.ink,
              ),
            ),
            const SizedBox(height: ClosetimoSpacing.sm),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
