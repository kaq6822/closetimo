// US2 T044 — 옷장 검색 + 카테고리 + 정렬 필터바.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../data/models/item.dart';
import '../../../data/repositories/item_repository.dart';

class WardrobeFilterBar extends StatelessWidget {
  const WardrobeFilterBar({
    required this.query,
    required this.category,
    required this.sort,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    super.key,
  });

  final String query;
  final Category? category; // null = 전체
  final WardrobeSort sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Category?> onCategoryChanged;
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
          padding: const EdgeInsets.all(ClosetimoSpacing.md - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '카테고리',
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
                    active: category == null,
                    onTap: () => onCategoryChanged(null),
                  ),
                  for (final c in Category.values)
                    ChipFilter(
                      label: c.label,
                      active: category == c,
                      onTap: () => onCategoryChanged(c),
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
            vertical: 4,
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
