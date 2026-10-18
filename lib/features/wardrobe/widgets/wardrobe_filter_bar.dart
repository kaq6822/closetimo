// US2 T044 — 옷장 검색 + 카테고리 + 정렬 필터바.
// #21 — 첫 줄 타일이 첫 화면에 보이도록 칩을 한 줄 가로 스크롤로 압축하고
// 검색창에 지우기(✕) 버튼을 둔다. #43 — '입을 수 있음' 칩.
// #46 — 같은 줄 끝에 '태그' 칩 하나를 두고 태그 선택은 시트로 접어 둔다.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_filter.dart';
import '../../../data/models/item_tags.dart';
import '../../../data/repositories/item_repository.dart';
import 'tag_filter_sheet.dart';

class WardrobeFilterBar extends StatelessWidget {
  const WardrobeFilterBar({
    required this.searchController,
    required this.scope,
    required this.readyToWear,
    required this.sort,
    required this.onQueryChanged,
    required this.onScopeChanged,
    required this.onReadyToWearChanged,
    required this.onSortChanged,
    this.tagUsages = const [],
    super.key,
  });

  /// 검색창 텍스트. 화면이 소유해 홈 카드 진입 시 함께 비운다(#33).
  final TextEditingController searchController;

  /// 종류·용도 조건(검색어 제외). 종류가 비어 있으면 '전체'.
  final ItemFilter scope;

  /// '입을 수 있음' 조건(#43, spec FR-005a).
  final bool readyToWear;
  final WardrobeSort sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ItemFilter> onScopeChanged;
  final ValueChanged<bool> onReadyToWearChanged;
  final ValueChanged<WardrobeSort> onSortChanged;

  /// 이미 쓴 태그(#46). 비어 있고 선택된 태그도 없으면 '태그' 칩을 숨긴다.
  final List<TagUsage> tagUsages;

  String _sortLabel(WardrobeSort s) => switch (s) {
    WardrobeSort.statusCleanFirst => '정렬: 상태순 (깨끗한 옷 먼저)',
    WardrobeSort.recentlyWorn => '정렬: 최근 착용순',
    WardrobeSort.mostWorn => '정렬: 착용 빈도순',
  };

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 검색
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: searchController,
          builder: (context, value, _) => TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            // #14 — 모바일 TextField는 바깥을 눌러도 포커스를 유지한다. 포커스를 둔 채
            // 타일·+로 화면을 push하면 pop 시 Navigator가 포커스를 복원해 키보드가
            // 다시 올라오므로, 바깥 탭에서 포커스를 해제한다.
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: '옷 이름·브랜드·태그 검색',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: ClosetimoColors.muted,
              ),
              // #21 — 입력이 있을 때만 지우기 버튼을 보인다.
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ClosetimoColors.muted,
                      ),
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                    ),
              filled: true,
              fillColor: surfaces.containerLow,
              isDense: true,
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
        ),
        const SizedBox(height: ClosetimoSpacing.space12),
        // 종류·용도 칩 — #21 한 줄 가로 스크롤(여러 줄 Wrap이 첫 타일을 밀어냈다).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final chip in _scopeChips(context)) ...[
                chip,
                const SizedBox(width: ClosetimoSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClosetimoSpacing.space12),
        // '입을 수 있음' + 정렬 한 줄
        Row(
          children: [
            ChipFilter(
              label: '입을 수 있음',
              active: readyToWear,
              onTap: () => onReadyToWearChanged(!readyToWear),
            ),
            const SizedBox(width: ClosetimoSpacing.sm),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaces.containerLow,
                  borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: ClosetimoSpacing.md,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WardrobeSort>(
                    value: sort,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ClosetimoColors.muted,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: ClosetimoColors.ink,
                    ),
                    dropdownColor: surfaces.containerLowest,
                    items: [
                      for (final s in WardrobeSort.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(
                            _sortLabel(s),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) onSortChanged(v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        // #43 — 앱은 실제 오염을 감지하지 않는다. 기록된 상태 기준임을 밝힌다.
        if (readyToWear)
          const Padding(
            padding: EdgeInsets.only(
              top: ClosetimoSpacing.sm,
              left: ClosetimoSpacing.space4,
            ),
            child: Text(
              '관리 권장(세탁 필요) 전이고 세탁 바구니에 없는 옷이에요. '
              '기록된 상태 기준이니 실제 상태는 직접 확인해 주세요.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: ClosetimoColors.muted,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  String _tagChipLabel() => switch (scope.tags.length) {
    0 => '태그',
    1 => '태그: ${scope.tags.single}',
    final n => '태그 $n개',
  };

  Future<void> _pickTags(BuildContext context) async {
    final picked = await showTagFilterSheet(
      context,
      usages: [
        for (final u in tagUsages)
          if (u.activeItemCount > 0) u,
      ],
      selected: scope.tags,
    );
    if (picked != null) onScopeChanged(scope.copyWith(tags: picked));
  }

  List<Widget> _scopeChips(BuildContext context) => [
    ChipFilter(
      label: '전체',
      active: scope.categories.isEmpty,
      onTap: () => onScopeChanged(scope.copyWith(categories: {})),
    ),
    // #37 — 홈 '그 외' 카드처럼 여러 종류를 합산한 범위로 들어오면
    // 개별 '기타'와 구분되는 합산 칩을 선택 상태로 보여준다.
    if (scope.groupBucket case final bucket?)
      ChipFilter(label: '${bucket.label} 전체', active: true, onTap: () {}),
    for (final c in Category.selectable)
      ChipFilter(
        label: c.label,
        active: scope.categories.length == 1 && scope.categories.contains(c),
        onTap: () => onScopeChanged(scope.copyWith(categories: {c})),
      ),
    // #41 — 용도는 종류와 독립된 축(AND)이다.
    for (final p in ItemPurpose.values)
      ChipFilter(
        label: '용도: ${p.label}',
        active: scope.purposes.contains(p),
        onTap: () => onScopeChanged(
          scope.copyWith(
            purposes: scope.purposes.contains(p)
                ? ({...scope.purposes}..remove(p))
                : {...scope.purposes, p},
          ),
        ),
      ),
    // #46 — 사용자 태그 축(OR). 기본 접힘: 칩 하나로 시트를 연다.
    if (tagUsages.isNotEmpty || scope.tags.isNotEmpty)
      ChipFilter(
        label: _tagChipLabel(),
        active: scope.tags.isNotEmpty,
        onTap: () => _pickTags(context),
      ),
  ];
}
