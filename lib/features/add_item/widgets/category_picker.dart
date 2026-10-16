// US1 T037 — 종류 wrap chip picker. #41 — 선택 가능한 종류([Category.selectable])만
// 표시하고 '미분류'를 허용한다. legacy 운동복은 새로 선택할 수 없다.
// 용도(운동 등)는 종류와 독립 축이므로 [PurposePicker]로 따로 고른다.

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
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
      spacing: ClosetimoSpacing.sm,
      runSpacing: ClosetimoSpacing.sm,
      children: [
        for (final c in Category.selectable)
          ChipFilter(
            label: c.label,
            active: c == value,
            onTap: () => onChanged(c),
          ),
      ],
    );
  }
}

/// #41 — 선택 용도 축(복수 선택). 아무것도 고르지 않아도 된다.
class PurposePicker extends StatelessWidget {
  const PurposePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<ItemPurpose> value;
  final ValueChanged<List<ItemPurpose>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ClosetimoSpacing.sm,
      runSpacing: ClosetimoSpacing.sm,
      children: [
        for (final p in ItemPurpose.values)
          ChipFilter(
            label: p.label,
            active: value.contains(p),
            onTap: () => onChanged(
              value.contains(p)
                  ? [
                      for (final v in value)
                        if (v != p) v,
                    ]
                  : [...value, p],
            ),
          ),
      ],
    );
  }
}
