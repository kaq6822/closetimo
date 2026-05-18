// US3 T054 — 옷 상세 화면.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/widgets/chip_filter.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/providers/app_providers.dart';
import 'widgets/hero_image.dart';
import 'widgets/history_timeline.dart';
import 'widgets/stats_grid.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  Item? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.get(widget.id);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
    if (item == null && context.mounted) {
      showClosetimoToast(context, '옷을 찾을 수 없어요');
      context.pop();
    }
  }

  Future<void> _refresh() async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.get(widget.id);
    if (mounted) setState(() => _item = item);
  }

  // ignore_for_file: use_build_context_synchronously
  Future<void> _recordWear() async {
    await ref.read(eventRepositoryProvider).recordWear(widget.id);
    if (!context.mounted) return;
    showClosetimoToast(context, '오늘의 착용이 기록되었어요');
    context.pop();
  }

  Future<void> _toggleLaundry() async {
    if (_item == null) return;
    final wasIn = _item!.inLaundry;
    await ref.read(laundryRepositoryProvider).toggle(widget.id);
    await _refresh();
    if (!context.mounted) return;
    showClosetimoToast(
      context,
      wasIn ? '세탁 바구니에서 제외됐어요' : '세탁 바구니에 담겼어요',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final item = _item;
    if (item == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.md,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.huge + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroImage(item: item),
                    const SizedBox(height: ClosetimoSpacing.xl + 2),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.md),
                    Row(
                      children: [
                        ChipFilter(
                          label: item.category.label,
                          active: false,
                          onTap: () {},
                        ),
                        const SizedBox(width: ClosetimoSpacing.sm),
                        ChipFilter(
                          label: item.careMethod.label,
                          active: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl + 2),
                    StatsGrid(item: item),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    PrimaryButton(
                      label: '착용 기록하기',
                      leading: const Icon(Icons.add_rounded),
                      onPressed: _recordWear,
                    ),
                    const SizedBox(height: ClosetimoSpacing.sm + 4),
                    SoftButton(
                      label: item.inLaundry ? '바구니에서 제외' : '세탁 바구니',
                      leading: const Icon(Icons.local_laundry_service_rounded),
                      onPressed: _toggleLaundry,
                    ),
                    const SizedBox(height: ClosetimoSpacing.xxl),
                    const Text(
                      '착용 히스토리',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.md + 2),
                    HistoryTimeline(itemId: item.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
