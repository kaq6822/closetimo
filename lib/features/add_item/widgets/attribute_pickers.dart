// 005 FR-501 — 구조화 속성 칩 선택(등록·수정 폼과 정리하기 화면 공용).
// 모두 선택 입력이며 타이핑 없이 탭으로만 고른다.

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../core/widgets/color_swatch_chip.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_attributes.dart';

/// 세부 종류(종류에 종속, 단일). 선택한 칩을 다시 누르면 해제한다.
/// 미분류·기타처럼 세부 종류가 없는 종류에서는 아무것도 그리지 않는다.
class SubTypePicker extends StatelessWidget {
  const SubTypePicker({
    required this.category,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Category category;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final defs = ItemAttributes.subTypesOf(category);
    if (defs.isEmpty) return const SizedBox.shrink();
    return _ChipWrap(
      children: [
        for (final d in defs)
          ChipFilter(
            label: d.label,
            active: d.code == value,
            onTap: () => onChanged(d.code == value ? null : d.code),
          ),
      ],
    );
  }
}

/// 색상(복수, 최대 [maxItemColors]). 첫 선택이 대표 색상이다.
/// 이미 최대 개수일 때 새 색을 누르면 마지막 색을 바꾼다.
class ColorPicker extends StatelessWidget {
  const ColorPicker({required this.value, required this.onChanged, super.key});

  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  void _toggle(String code) {
    if (value.contains(code)) {
      onChanged([
        for (final c in value)
          if (c != code) c,
      ]);
    } else if (value.length >= maxItemColors) {
      onChanged([...value.take(maxItemColors - 1), code]);
    } else {
      onChanged([...value, code]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ChipWrap(
      children: [
        for (final c in ItemAttributes.colors)
          ColorSwatchChip(
            color: Color(c.argb),
            label: c.label,
            selected: value.contains(c.code),
            onTap: () => _toggle(c.code),
          ),
      ],
    );
  }
}

/// 계절(복수) + `사계절` 단축 칩. 계절이 비어 있고 [suggested]가 있으면
/// 한 번에 적용하는 추천 버튼을 보여 준다(자동 저장하지 않는다).
class SeasonPicker extends StatelessWidget {
  const SeasonPicker({
    required this.value,
    required this.onChanged,
    this.suggested = const {},
    super.key,
  });

  final List<Season> value;
  final ValueChanged<List<Season>> onChanged;
  final Set<Season> suggested;

  @override
  Widget build(BuildContext context) {
    final all = value.length == Season.values.length;
    final ordered = ItemAttributes.normalizeSeasons(suggested);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipWrap(
          children: [
            for (final s in Season.values)
              ChipFilter(
                label: s.label,
                active: value.contains(s),
                onTap: () => onChanged(
                  ItemAttributes.normalizeSeasons(
                    value.contains(s)
                        ? [
                            for (final v in value)
                              if (v != s) v,
                          ]
                        : [...value, s],
                  ),
                ),
              ),
            ChipFilter(
              label: '사계절',
              active: all,
              onTap: () => onChanged(all ? const [] : Season.values),
            ),
          ],
        ),
        if (value.isEmpty && ordered.isNotEmpty)
          TextButton.icon(
            onPressed: () => onChanged(ordered),
            icon: const Icon(Icons.auto_awesome_outlined, size: 16),
            label: Text('추천: ${ordered.map((s) => s.label).join('·')}'),
          ),
      ],
    );
  }
}

/// 소재·패턴 같은 단일 선택 속성. 선택한 칩을 다시 누르면 해제한다.
class SingleAttributePicker extends StatelessWidget {
  const SingleAttributePicker({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<AttributeDef> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ChipWrap(
      children: [
        for (final o in options)
          ChipFilter(
            label: o.label,
            active: o.code == value,
            onTap: () => onChanged(o.code == value ? null : o.code),
          ),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ClosetimoSpacing.sm,
      runSpacing: ClosetimoSpacing.sm,
      children: children,
    );
  }
}
