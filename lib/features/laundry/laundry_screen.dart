// US4 T060 — 세탁 바구니 화면.
// #48 FR-029·030 — 로딩·읽기 실패 구분, 세탁 완료 처리 중복 입력 차단·실패 안내.

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
                      "'세탁 중' 또는 '오염됨'으로 표시된 아이템들입니다.\n"
                      '세탁이 완료되면 착용 횟수를 초기화하세요.',
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
                      Column(
                        children: [
                          for (final it in items) ...[
                            LaundryTile(
                              item: it,
                              selected: selection.contains(it.id),
                              onToggleSelection: () =>
                                  selectionCtl.toggle(it.id),
                            ),
                            const SizedBox(height: ClosetimoSpacing.space12),
                          ],
                        ],
                      ),
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
