// 005 FR-508 — 홈 "정리 대기 N벌": 활성 미분류 옷이 있을 때만 보이고 정리하기로 이어진다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/models/item.dart';
import '../../../data/providers/app_providers.dart';

/// 정리 대기 = 보관하지 않은 미분류 옷.
int pendingSortCount(Iterable<Item> items) => items
    .where((i) => !i.isArchived && i.category == Category.uncategorized)
    .length;

class SortPendingCard extends ConsumerWidget {
  const SortPendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(itemRepositoryProvider);
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return StreamBuilder<List<Item>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        // 보조 카드라 로딩·오류 중에는 그리지 않는다. 같은 옷 스트림을 쓰는 홈 통계·
        // 오늘 입은 옷 카드가 오류 안내와 다시 시도를 보여 준다(FR-029).
        if (snap.hasError) {
          debugPrint('Sort pending count failed: ${snap.error}');
          return const SizedBox.shrink();
        }
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final count = pendingSortCount(data);
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: ClosetimoSpacing.md),
          child: Material(
            color: surfaces.bgMintSoft,
            borderRadius: BorderRadius.circular(ClosetimoRadius.lgPlus),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.pushNamed(Routes.sortItems),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClosetimoSpacing.space18,
                  vertical: ClosetimoSpacing.space16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.style_outlined,
                      color: ClosetimoColors.tertiary,
                    ),
                    const SizedBox(width: ClosetimoSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '정리 대기 $count벌',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ClosetimoColors.ink,
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.space2),
                          const Text(
                            '종류·색상·계절을 탭으로 골라 정리해요',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: ClosetimoColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ClosetimoColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
