// US5 T071 — 홈 대시보드.
// #48 FR-029 — 통계 로딩·읽기 실패를 0점과 구분한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/greeting.dart';
import '../../core/widgets/async_state_view.dart';
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
    final repo = ref.watch(itemRepositoryProvider);
    final greeting = greetingFor(ref.watch(clockProvider).now());
    return Column(
      children: [
        TopBar(
          rightSlot: TopBarPlusAction(
            onTap: () => context.pushNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: StreamStateBuilder<WardrobeStats>(
            stream: repo.watchStats,
            streamKey: repo,
            errorMessage: '옷장 정보를 불러오지 못했어요',
            builder: (ctx, s) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.space76,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$greeting, 큐레이터님',
                      style: const TextStyle(
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
