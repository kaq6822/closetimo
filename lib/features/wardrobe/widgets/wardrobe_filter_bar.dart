// US2 T044 — 옷장 검색 + 카테고리 + 정렬 필터바.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_filter.dart';
import '../../../data/repositories/item_repository.dart';

class WardrobeFilterBar extends StatelessWidget {
  const WardrobeFilterBar({
    required this.query,
    required this.scope,
    required this.sort,
    required this.onQueryChanged,
    required this.onScopeChanged,
    required this.onSortChanged,
    super.key,
  });

  final String query;

  /// 종류·용도 조건(검색어 제외). 종류가 비어 있으면 '전체'.
  final ItemFilter scope;
  final WardrobeSort sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ItemFilter> onScopeChanged;
  final ValueChanged<WardrobeSort> onSortChanged;

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
        TextField(
          onChanged: onQueryChanged,
          // #14 — 모바일 TextField는 바깥을 눌러도 포커스를 유지한다. 포커스를 둔 채
          // 타일·+로 화면을 push하면 pop 시 Navigator가 포커스를 복원해 키보드가
          // 다시 올라오므로, 바깥 탭에서 포커스를 해제한다.
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: '옷 이름 또는 브랜드 검색',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: ClosetimoColors.muted,
            ),
            filled: true,
            fillColor: surfaces.containerLow,
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
        const SizedBox(height: ClosetimoSpacing.md),
        // 카테고리 칩 — surface-container-low 위에 nest
        Container(
          decoration: BoxDecoration(
            color: surfaces.containerLow,
            borderRadius: BorderRadius.circular(ClosetimoRadius.lg + 2),
          ),
          padding: const EdgeInsets.all(ClosetimoSpacing.space14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  left: ClosetimoSpacing.space4,
                  bottom: ClosetimoSpacing.space10,
                ),
                child: Text(
                  '종류',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: ClosetimoColors.muted,
                  ),
                ),
              ),
              Wrap(
                spacing: ClosetimoSpacing.sm,
                runSpacing: ClosetimoSpacing.sm,
                children: [
                  ChipFilter(
                    label: '전체',
                    active: scope.categories.isEmpty,
                    onTap: () => onScopeChanged(scope.copyWith(categories: {})),
                  ),
                  // #37 — 홈 '그 외' 카드처럼 여러 종류를 합산한 범위로 들어오면
                  // 개별 '기타'와 구분되는 합산 칩을 선택 상태로 보여준다.
                  if (scope.groupBucket case final bucket?)
                    ChipFilter(
                      label: '${bucket.label} 전체',
                      active: true,
                      onTap: () {},
                    ),
                  for (final c in Category.selectable)
                    ChipFilter(
                      label: c.label,
                      active:
                          scope.categories.length == 1 &&
                          scope.categories.contains(c),
                      onTap: () =>
                          onScopeChanged(scope.copyWith(categories: {c})),
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
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: ClosetimoSpacing.md),
        // 정렬 드롭다운
        Container(
          decoration: BoxDecoration(
            color: surfaces.containerLow,
            borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ClosetimoSpacing.md,
            vertical: ClosetimoSpacing.space4,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<WardrobeSort>(
              value: sort,
              isExpanded: true,
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
                  DropdownMenuItem(value: s, child: Text(_sortLabel(s))),
              ],
              onChanged: (v) {
                if (v != null) onSortChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
