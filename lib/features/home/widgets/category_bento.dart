// US5 T068 — 홈 2x2 카테고리 카드.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/models/item.dart';

class CategoryBento extends StatelessWidget {
  const CategoryBento({required this.perBucket, super.key});

  final Map<Category, int> perBucket;

  @override
  Widget build(BuildContext context) {
    const entries = [
      _Entry(category: Category.outer),
      _Entry(category: Category.top),
      _Entry(category: Category.bottom),
      _Entry(category: Category.etc, accent: true),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        for (final e in entries)
          _BentoCard(
            entry: e,
            count: perBucket[e.category] ?? 0,
          ),
      ],
    );
  }
}

class _Entry {
  const _Entry({required this.category, this.accent = false});
  final Category category;
  final bool accent;
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.entry, required this.count});

  final _Entry entry;
  final int count;

  IconData get _icon => switch (entry.category) {
        Category.outer => Icons.dry_cleaning_outlined,
        Category.top => Icons.checkroom_outlined,
        Category.bottom => Icons.straighten_outlined,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final bg = entry.accent
        ? surfaces.bgMintSoft
        : surfaces.containerLowest;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      child: InkWell(
        onTap: () => context.goNamed(
          Routes.wardrobe,
          queryParameters: {'category': entry.category.name},
        ),
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 6),
                  Text(
                    entry.category.label,
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
