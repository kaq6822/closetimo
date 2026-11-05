// 005 FR-509 — 옷장 상세 필터 시트: 세부 종류·색상·계절·용도.
// 같은 축 안은 OR, 다른 축과는 AND다. 적용 전에 결과 수를 보여 준다.
// 세부 종류·색상은 활성 옷에 실제로 있는 값만(사용 수와 함께) 보여 준다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../core/widgets/color_swatch_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_attributes.dart';
import '../../../data/models/item_filter.dart';
import '../../../data/providers/app_providers.dart';

/// 상세 필터 시트를 띄운다. 적용하면 새 필터, 닫으면 null.
/// [filter]는 검색어·입을 수 있음·이번 계절까지 포함한 현재 조건(결과 수 계산용)이다.
Future<ItemFilter?> showDetailFilterSheet(
  BuildContext context, {
  required ItemFilter filter,
}) {
  return showModalBottomSheet<ItemFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DetailFilterSheet(initial: filter),
  );
}

class _DetailFilterSheet extends ConsumerStatefulWidget {
  const _DetailFilterSheet({required this.initial});

  final ItemFilter initial;

  @override
  ConsumerState<_DetailFilterSheet> createState() => _DetailFilterSheetState();
}

class _DetailFilterSheetState extends ConsumerState<_DetailFilterSheet> {
  late ItemFilter _filter = widget.initial;

  Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(itemRepositoryProvider);
    // #48 FR-029 — 로딩·읽기 실패를 0벌과 구분한다.
    return StreamStateBuilder<List<Item>>(
      stream: repo.watchAll,
      streamKey: repo,
      errorMessage: '옷 목록을 불러오지 못했어요',
      builder: (context, all) {
        final active = [
          for (final i in all)
            if (_filter.archive.includes(i)) i,
        ];
        final count = active.where(_filter.matches).length;
        // 선택지: 종류가 정해져 있으면 그 종류의 세부 종류만.
        final subCounts = <String, int>{};
        final colorCounts = <String, int>{};
        for (final i in active) {
          if (i.subType case final s?
              when _filter.categories.isEmpty ||
                  _filter.categories.contains(i.category)) {
            subCounts[s] = (subCounts[s] ?? 0) + 1;
          }
          for (final c in i.colors) {
            colorCounts[c] = (colorCounts[c] ?? 0) + 1;
          }
        }
        final subs = [
          for (final d in ItemAttributes.subTypes)
            if (subCounts.containsKey(d.code) ||
                _filter.subTypes.contains(d.code))
              d,
        ];
        final colors = [
          for (final d in ItemAttributes.colors)
            if (colorCounts.containsKey(d.code) ||
                _filter.colors.contains(d.code))
              d,
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            ClosetimoSpacing.lg,
            ClosetimoSpacing.md,
            ClosetimoSpacing.lg,
            ClosetimoSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('상세 필터', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: ClosetimoSpacing.xs),
              const Text(
                '같은 줄에서 고른 값은 하나라도 맞으면, 다른 줄과는 모두 맞아야 보여요.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: ClosetimoColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (subs.isNotEmpty) ...[
                        const _SheetLabel('세부 종류'),
                        _Wrap([
                          for (final d in subs)
                            ChipFilter(
                              label: '${d.label} ${subCounts[d.code] ?? 0}',
                              active: _filter.subTypes.contains(d.code),
                              onTap: () => setState(
                                () => _filter = _filter.copyWith(
                                  subTypes: _toggle(_filter.subTypes, d.code),
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: ClosetimoSpacing.lg),
                      ],
                      if (colors.isNotEmpty) ...[
                        const _SheetLabel('색상'),
                        _Wrap([
                          for (final d in colors)
                            ColorSwatchChip(
                              color: Color(d.argb),
                              label: '${d.label} ${colorCounts[d.code] ?? 0}',
                              selected: _filter.colors.contains(d.code),
                              onTap: () => setState(
                                () => _filter = _filter.copyWith(
                                  colors: _toggle(_filter.colors, d.code),
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: ClosetimoSpacing.lg),
                      ],
                      const _SheetLabel('계절'),
                      _Wrap([
                        for (final s in Season.values)
                          ChipFilter(
                            label: s.label,
                            active: _filter.seasons.contains(s),
                            onTap: () => setState(
                              () => _filter = _filter.copyWith(
                                seasons: _toggle(_filter.seasons, s),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: ClosetimoSpacing.lg),
                      const _SheetLabel('용도'),
                      _Wrap([
                        for (final p in ItemPurpose.selectable)
                          ChipFilter(
                            label: p.label,
                            active: _filter.purposes.contains(p),
                            onTap: () => setState(
                              () => _filter = _filter.copyWith(
                                purposes: _toggle(_filter.purposes, p),
                              ),
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.lg),
              Row(
                children: [
                  TextButton(
                    onPressed: _filter.detailCount == 0
                        ? null
                        : () => setState(
                            () => _filter = _filter.copyWith(
                              subTypes: {},
                              colors: {},
                              seasons: {},
                              purposes: {},
                            ),
                          ),
                    child: const Text('선택 해제'),
                  ),
                  const SizedBox(width: ClosetimoSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: '$count벌 보기',
                      onPressed: () => Navigator.pop(context, _filter),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ClosetimoSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ClosetimoColors.muted,
        ),
      ),
    );
  }
}

class _Wrap extends StatelessWidget {
  const _Wrap(this.children);

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
