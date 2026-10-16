// US5 T068 — 홈 2x2 카테고리 카드. #37 — 카드 집계와 이동 목록 범위를
// 같은 [HomeBucket] 정의로 맞춘다('그 외'는 합산, 옷장 '기타' 칩은 개별).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_filter.dart';

class CategoryBento extends StatelessWidget {
  const CategoryBento({required this.perBucket, super.key});

  final Map<HomeBucket, int> perBucket;

  @override
  Widget build(BuildContext context) {
    const entries = [
      _Entry(bucket: HomeBucket.outer),
      _Entry(bucket: HomeBucket.top),
      _Entry(bucket: HomeBucket.bottom),
      _Entry(bucket: HomeBucket.others, accent: true),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: ClosetimoSpacing.space12,
      crossAxisSpacing: ClosetimoSpacing.space12,
      childAspectRatio: 1.15,
      children: [
        for (final e in entries)
          _BentoCard(entry: e, count: perBucket[e.bucket] ?? 0),
      ],
    );
  }
}

class _Entry {
  const _Entry({required this.bucket, this.accent = false});
  final HomeBucket bucket;
  final bool accent;
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.entry, required this.count});

  final _Entry entry;
  final int count;

  IconData get _icon => switch (entry.bucket) {
    HomeBucket.outer => Icons.dry_cleaning_outlined,
    HomeBucket.top => Icons.checkroom_outlined,
    HomeBucket.bottom => Icons.straighten_outlined,
    HomeBucket.others => Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final bg = entry.accent ? surfaces.bgMintSoft : surfaces.containerLowest;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      child: InkWell(
        onTap: () => context.goNamed(
          Routes.wardrobe,
          queryParameters: wardrobeQueryParameters(
            ItemFilter.homeBucket(entry.bucket),
          ),
        ),
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(ClosetimoSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(_icon, size: 26, color: ClosetimoColors.inkSoft),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: ClosetimoColors.ink,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: ClosetimoSpacing.space6),
                  Text(
                    entry.bucket.label,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: ClosetimoColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
