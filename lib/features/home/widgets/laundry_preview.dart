// US5 T070 — 홈 세탁 바구니 미리보기 + 전문가 팁.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/item.dart';
import '../../../data/providers/app_providers.dart';

final _laundryTipsProvider = FutureProvider<List<String>>((ref) async {
  final raw = await rootBundle.loadString('assets/tips/laundry_tips.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['tips'] as List).cast<String>();
});

/// 앱 부트 시 한 번만 결정되는 팁 인덱스 시드.
/// rebuild에도 같은 팁이 표시되도록 [Random]을 build 밖으로 격리한다.
final _laundryTipIndexProvider = Provider<int>((ref) {
  return Random().nextInt(1 << 20);
});

class LaundryPreview extends ConsumerWidget {
  const LaundryPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(laundryRepositoryProvider).watchBasket();
    final tips = ref.watch(_laundryTipsProvider).valueOrNull ?? const [];
    final seed = ref.watch(_laundryTipIndexProvider);
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return StreamBuilder<List<Item>>(
      stream: basket,
      builder: (ctx, snap) {
        final items = (snap.data ?? const []).take(3).toList();
        if (items.isEmpty && tips.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaces.containerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.opacity_rounded,
                    size: 18,
                    color: ClosetimoColors.tertiary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '세탁 바구니',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: ClosetimoColors.ink,
                    ),
                  ),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: ClosetimoSpacing.md),
                for (var i = 0; i < items.length; i++) ...[
                  _Row(item: items[i]),
                  if (i < items.length - 1) const SizedBox(height: 12),
                ],
              ],
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: surfaces.container,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '전문가의 팁: ${tips[seed % tips.length]}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: ClosetimoColors.primary,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final progress = item.washCycle == 0
        ? 0.0
        : (item.wearSinceWash / item.washCycle).clamp(0.0, 1.0);
    return Row(
      children: [
        Container(
          width: 42,
          height: 54,
          decoration: BoxDecoration(
            color: Color(item.fallbackColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: ClosetimoColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ProgressBar(
                      value: progress,
                      variant: ProgressBarVariant.alert,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.wearSinceWash}/${item.washCycle}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: ClosetimoColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
