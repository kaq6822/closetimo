// US5 T071 — 홈 대시보드.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/providers/app_providers.dart';
import '../../data/repositories/item_repository.dart';
import 'widgets/category_bento.dart';
import 'widgets/laundry_preview.dart';
import 'widgets/recently_worn_list.dart';
import 'widgets/stats_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(itemRepositoryProvider).watchStats();
    return Column(
      children: [
        TopBar(
          rightSlot: TopBarPlusAction(
            onTap: () => context.pushNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: StreamBuilder<WardrobeStats>(
            stream: stats,
            initialData: const WardrobeStats(
              total: 0,
              clean: 0,
              dirty: 0,
              perBucket: {},
            ),
            builder: (ctx, snap) {
              final s = snap.data ??
                  const WardrobeStats(
                    total: 0,
                    clean: 0,
                    dirty: 0,
                    perBucket: {},
                  );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.huge + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '좋은 아침입니다, 큐레이터님',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: ClosetimoColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.sm),
                    const Text(
                      '기분 좋은 옷장 관리',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: ClosetimoColors.ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    StatsRow(stats: s),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    CategoryBento(perBucket: s.perBucket),
                    const SizedBox(height: ClosetimoSpacing.xxl),
                    const RecentlyWornList(),
                    const SizedBox(height: ClosetimoSpacing.xxl),
                    const LaundryPreview(),
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
