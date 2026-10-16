// #46 — 옷장 다중 선택 '태그' 액션. 선택한 여러 옷에 태그를 한 번에 붙이거나 뗀다.
// 선택 바(SelectionActionBar)에 액션만 추가하는 형태로 옷장 화면과 분리한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../core/widgets/toast.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_tags.dart';
import '../../../data/providers/app_providers.dart';
import 'item_selection.dart';
import 'selection_action_bar.dart';

/// 일괄 태그 편집 1회의 결정. [tags]를 모두 붙이거나([remove] false) 뗀다.
@immutable
class BulkTagCommand {
  const BulkTagCommand.add(this.tags) : remove = false;
  BulkTagCommand.remove(String tag) : tags = [tag], remove = true;

  final List<String> tags;
  final bool remove;
}

/// 선택 바에 넣을 '태그' 액션. [selected]는 현재 선택된 옷(보이는 목록 기준)이다.
SelectionAction bulkTagAction(
  BuildContext context,
  WidgetRef ref, {
  required List<Item> selected,
}) {
  return SelectionAction(
    label: '태그',
    icon: Icons.sell_outlined,
    onPressed: () => _run(context, ref, selected),
  );
}

Future<void> _run(
  BuildContext context,
  WidgetRef ref,
  List<Item> selected,
) async {
  if (selected.isEmpty) return;
  final usages = ref.read(tagUsageProvider).valueOrNull ?? const <TagUsage>[];
  final command = await showModalBottomSheet<BulkTagCommand>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BulkTagSheet(
      selected: selected,
      suggestions: [for (final u in usages) u.name],
    ),
  );
  if (command == null || !context.mounted) return;
  final repo = ref.read(tagRepositoryProvider);
  final ids = {for (final i in selected) i.id};
  var changed = 0;
  try {
    for (final tag in command.tags) {
      changed += command.remove
          ? await repo.removeTag(ids, tag)
          : await repo.addTag(ids, tag);
    }
  } catch (e, st) {
    debugPrint('Failed to apply bulk tag edit: $e\n$st');
    if (context.mounted) showClosetimoToast(context, '태그를 바꾸지 못했어요');
    return;
  }
  if (!context.mounted) return;
  ref.read(wardrobeSelectionProvider.notifier).exit();
  final label = command.tags.map((t) => "'$t'").join(', ');
  showClosetimoToast(
    context,
    changed == 0
        ? (command.remove ? '뗄 태그가 없었어요' : '이미 모두 붙어 있어요')
        : command.remove
        ? '$changed벌에서 $label 태그를 뗐어요'
        : '${ids.length}벌에 $label 태그를 붙였어요',
  );
}

/// 일괄 태그 편집 시트. 새 태그 입력·이미 쓴 태그 붙이기·선택한 옷의 태그 떼기를
/// 한 화면에 둔다. 한 번 고르면 바로 닫고 [BulkTagCommand]를 돌려준다.
class BulkTagSheet extends StatefulWidget {
  const BulkTagSheet({
    required this.selected,
    required this.suggestions,
    super.key,
  });

  final List<Item> selected;

  /// 이미 쓴 태그(많이 쓴 순).
  final List<String> suggestions;

  @override
  State<BulkTagSheet> createState() => _BulkTagSheetState();
}

class _BulkTagSheetState extends State<BulkTagSheet> {
  final TextEditingController _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _submitText() {
    final tags = parseTagInput(_ctl.text);
    if (tags.isEmpty) return;
    Navigator.pop(context, BulkTagCommand.add(tags));
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final n = widget.selected.length;
    // 선택한 옷에 붙은 태그와 그 태그가 붙은 옷 수.
    final present = <String, int>{};
    for (final item in widget.selected) {
      for (final t in item.tags) {
        present[t] = (present[t] ?? 0) + 1;
      }
    }
    final addable = [
      for (final s in widget.suggestions)
        if ((present[s] ?? 0) < n) s,
    ];
    const caption = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 12,
      color: ClosetimoColors.muted,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClosetimoSpacing.lg,
        ClosetimoSpacing.md,
        ClosetimoSpacing.lg,
        ClosetimoSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '선택한 $n벌 태그 편집',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ClosetimoSpacing.md),
            Semantics(
              label: '붙일 태그',
              child: TextField(
                controller: _ctl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitText(),
                decoration: InputDecoration(
                  hintText: '새 태그 입력 (예: 검정, 여름)',
                  filled: true,
                  fillColor: surfaces.containerLow,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _ctl,
                    builder: (context, v, _) => TextButton(
                      onPressed: parseTagInput(v.text).isEmpty
                          ? null
                          : _submitText,
                      child: const Text('붙이기'),
                    ),
                  ),
                ),
              ),
            ),
            if (addable.isNotEmpty) ...[
              const SizedBox(height: ClosetimoSpacing.md),
              const Text('이미 쓴 태그 붙이기', style: caption),
              const SizedBox(height: ClosetimoSpacing.sm),
              Wrap(
                spacing: ClosetimoSpacing.sm,
                runSpacing: ClosetimoSpacing.sm,
                children: [
                  for (final s in addable)
                    Semantics(
                      label: '$s 태그 붙이기',
                      excludeSemantics: true,
                      button: true,
                      child: ChipFilter(
                        label: '+ $s',
                        active: false,
                        onTap: () =>
                            Navigator.pop(context, BulkTagCommand.add([s])),
                      ),
                    ),
                ],
              ),
            ],
            if (present.isNotEmpty) ...[
              const SizedBox(height: ClosetimoSpacing.md),
              const Text('선택한 옷에서 떼기', style: caption),
              const SizedBox(height: ClosetimoSpacing.sm),
              Wrap(
                spacing: ClosetimoSpacing.sm,
                runSpacing: ClosetimoSpacing.sm,
                children: [
                  for (final e in present.entries)
                    Semantics(
                      label: '${e.key} 태그 떼기, ${e.value}벌',
                      excludeSemantics: true,
                      button: true,
                      child: ChipFilter(
                        label: '${e.key} ✕ ${e.value}',
                        active: true,
                        onTap: () => Navigator.pop(
                          context,
                          BulkTagCommand.remove(e.key),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: ClosetimoSpacing.md),
            const Text('태그를 떼도 옷과 착용 기록은 그대로 남아요.', style: caption),
          ],
        ),
      ),
    );
  }
}
