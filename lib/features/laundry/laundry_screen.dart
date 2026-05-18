// US4 T060 — 세탁 바구니 화면.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/providers/app_providers.dart';
import 'laundry_selection_provider.dart';
import 'widgets/laundry_tile.dart';

class LaundryScreen extends ConsumerWidget {
  const LaundryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(laundryRepositoryProvider).watchBasket();
    final selection = ref.watch(laundrySelectionProvider);
    final selectionCtl = ref.read(laundrySelectionProvider.notifier);

    return Column(
      children: [
        TopBar(
          rightSlot: TopBarPlusAction(
            onTap: () => context.goNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Item>>(
            stream: basket,
            builder: (ctx, snap) {
              final items = snap.data ?? const [];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.md,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.huge + 32,
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
                      label: '선택 항목 세탁 완료 처리',
                      leading: const Icon(Icons.check_rounded),
                      onPressed: selection.isEmpty
                          ? null
                          : () async {
                              final ids = selection.toList();
                              await ref
                                  .read(laundryRepositoryProvider)
                                  .completeWashFor(ids);
                              selectionCtl.clear();
                              if (context.mounted) {
                                showClosetimoToast(
                                  context,
                                  '${ids.length}점의 세탁이 완료됐어요',
                                );
                              }
                            },
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
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
                            '(${items.length})',
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
                                selectionCtl
                                    .selectAll(items.map((i) => i.id));
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
                      const SizedBox(height: ClosetimoSpacing.sm + 4),
                      Column(
                        children: [
                          for (final it in items) ...[
                            LaundryTile(
                              item: it,
                              selected: selection.contains(it.id),
                              onToggleSelection: () =>
                                  selectionCtl.toggle(it.id),
                            ),
                            const SizedBox(height: ClosetimoSpacing.md - 4),
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
