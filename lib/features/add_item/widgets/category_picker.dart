// US1 T037 — 카테고리 wrap chip picker. Category.values 9종 모두 표시(전체는 wardrobe 화면 전용이라 제외).

import 'package:flutter/material.dart';

import '../../../core/widgets/chip_filter.dart';
import '../../../data/models/item.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Category value;
  final ValueChanged<Category> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in Category.values)
          ChipFilter(
            label: c.label,
            active: c == value,
            onTap: () => onChanged(c),
          ),
      ],
    );
  }
}
