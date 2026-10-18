// #46 — 옷장 태그 필터 시트. 필터바에는 '태그' 칩 하나만 두고(기본 접힘)
// 여기서 여러 태그를 고른다. 같은 축 안은 OR(하나라도 붙은 옷)이다.

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/item_tags.dart';

/// 태그 선택 시트를 띄운다. 적용하면 고른 태그 집합(빈 집합 = 조건 해제),
/// 닫으면 null.
Future<Set<String>?> showTagFilterSheet(
  BuildContext context, {
  required List<TagUsage> usages,
  required Set<String> selected,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TagFilterSheet(usages: usages, initial: selected),
  );
}

class _TagFilterSheet extends StatefulWidget {
  const _TagFilterSheet({required this.usages, required this.initial});

  final List<TagUsage> usages;
  final Set<String> initial;

  @override
  State<_TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<_TagFilterSheet> {
  late final Set<String> _picked = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    // 라우트로 들어온 태그가 지금 목록에 없더라도 해제할 수 있게 함께 보여준다.
    final names = [
      for (final u in widget.usages) u.name,
      for (final t in widget.initial)
        if (!widget.usages.any((u) => u.name == t)) t,
    ];
    final counts = {for (final u in widget.usages) u.name: u.activeItemCount};
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
          Text('태그로 찾기', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ClosetimoSpacing.xs),
          const Text(
            '고른 태그 중 하나라도 붙은 옷을 보여줘요. 종류·용도 조건과는 함께 적용돼요.',
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
              child: Wrap(
                spacing: ClosetimoSpacing.sm,
                runSpacing: ClosetimoSpacing.sm,
                children: [
                  for (final name in names)
                    ChipFilter(
                      label: '$name ${counts[name] ?? 0}',
                      active: _picked.contains(name),
                      onTap: () => setState(() {
                        if (!_picked.add(name)) _picked.remove(name);
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.lg),
          Row(
            children: [
              TextButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () => setState(_picked.clear),
                child: const Text('선택 해제'),
              ),
              const SizedBox(width: ClosetimoSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: _picked.isEmpty ? '전체 보기' : '${_picked.length}개 태그 적용',
                  onPressed: () => Navigator.pop(context, {..._picked}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
