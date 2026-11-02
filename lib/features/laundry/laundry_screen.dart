// US4 T060 — 세탁 바구니 화면.
// #48 FR-029·030 — 로딩·읽기 실패 구분, 세탁 완료 처리 중복 입력 차단·실패 안내.
// 005 FR-512 — 세탁 그룹(손세탁·드라이 / 데님 / 흰옷·밝은색 / 어두운색 / 색상 미지정)으로
// 나눠 보여 주고 그룹 단위로 고른다. 그룹이 하나뿐이면 나누지 않는다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/action_guard.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/models/item_attributes.dart';
import '../../data/providers/app_providers.dart';
import 'laundry_selection_provider.dart';
import 'widgets/laundry_tile.dart';

class LaundryScreen extends ConsumerStatefulWidget {
  const LaundryScreen({super.key});

  @override
  ConsumerState<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends ConsumerState<LaundryScreen>
    with ActionGuardMixin {
  /// 선택 항목을 세탁 완료 처리한다. 실패하면 선택을 유지한다.
  Future<void> _completeWash(Set<int> selection) => runGuarded(() async {
    final done = await ref
        .read(laundryRepositoryProvider)
        .completeWashFor(selection.toList());
    if (!mounted) return;
    ref.read(laundrySelectionProvider.notifier).clear();
    if (done > 0) showClosetimoToast(context, '$done점의 세탁이 완료됐어요');
  }, failureMessage: '세탁 완료 처리에 실패했어요. 다시 시도해 주세요.');

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(laundryRepositoryProvider);
    final rawSelection = ref.watch(laundrySelectionProvider);
    final selectionCtl = ref.read(laundrySelectionProvider.notifier);

    return Column(
      children: [
        TopBar(
          rightSlot: TopBarPlusAction(
            onTap: () => context.pushNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: StreamStateBuilder<List<Item>>(
            stream: repo.watchBasket,
            streamKey: repo,
            errorMessage: '세탁 바구니를 불러오지 못했어요',
            builder: (ctx, items) {
              // 제외·삭제·외부 완료로 사라진 항목은 선택에서 제거한다.
              final basketIds = items.map((i) => i.id).toSet();
              final selection = rawSelection.where(basketIds.contains).toSet();
              if (selection.length != rawSelection.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  selectionCtl.retainOnly(basketIds);
                });
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.md,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.space76,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '세탁 바구니',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: ClosetimoSpacing.sm),
                    const Text(
                      '바구니에 담았거나 관리가 필요한 옷이에요.\n'
                      '색과 관리 방법별로 나눠 빨고, 끝나면 완료 처리하세요.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: ClosetimoColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    PrimaryButton(
                      label: actionBusy ? '세탁 완료 처리 중…' : '선택 항목 세탁 완료 처리',
                      leading: const Icon(Icons.check_rounded),
                      busy: actionBusy,
                      onPressed: selection.isEmpty
                          ? null
                          : () => _completeWash(selection),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: ClosetimoSpacing.space60,
                        ),
                        child: Center(
                          child: Text(
                            '세탁할 옷이 없어요.',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: ClosetimoColors.muted,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '세탁 대기 ${items.length}점',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: ClosetimoColors.muted,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (selection.length == items.length) {
                                selectionCtl.clear();
                              } else {
                                selectionCtl.selectAll(items.map((i) => i.id));
                              }
                            },
                            child: Text(
                              selection.length == items.length
                                  ? '선택 해제'
                                  : '모두 선택',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ClosetimoSpacing.space12),
                      for (final (group, members) in _groups(items)) ...[
                        if (group != null)
                          _GroupHeader(
                            group: group,
                            count: members.length,
                            allSelected: members.every(
                              (m) => selection.contains(m.id),
                            ),
                            onToggle: () => selectionCtl.toggleGroup(
                              members.map((m) => m.id),
                            ),
                          ),
                        for (final it in members) ...[
                          LaundryTile(
                            item: it,
                            selected: selection.contains(it.id),
                            onToggleSelection: () => selectionCtl.toggle(it.id),
                          ),
                          const SizedBox(height: ClosetimoSpacing.space12),
                        ],
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 세탁 그룹별 묶음(그룹 순서, 그룹 안은 바구니 순서). 그룹이 하나뿐이면 머리말 없이
/// (null, 전체) 하나로 돌려준다.
List<(WashGroup?, List<Item>)> _groups(List<Item> items) {
  final byGroup = <WashGroup, List<Item>>{};
  for (final i in items) {
    byGroup.putIfAbsent(i.washGroup, () => []).add(i);
  }
  if (byGroup.length <= 1) return [(null, items)];
  return [
    for (final g in WashGroup.values)
      if (byGroup[g] case final members?) (g, members),
  ];
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.count,
    required this.allSelected,
    required this.onToggle,
  });

  final WashGroup group;
  final int count;
  final bool allSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ClosetimoSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${group.label} $count',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ClosetimoColors.ink,
              ),
            ),
          ),
          Semantics(
            label: '${group.label} ${allSelected ? '그룹 해제' : '그룹 선택'}',
            excludeSemantics: true,
            button: true,
            child: TextButton(
              onPressed: onToggle,
              child: Text(allSelected ? '그룹 해제' : '그룹 선택'),
            ),
          ),
        ],
      ),
    );
  }
}
