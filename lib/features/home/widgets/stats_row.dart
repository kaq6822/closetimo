// US5 T067 — 홈 상단 3컬럼 통계.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/repositories/item_repository.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({required this.stats, super.key});

  final WardrobeStats stats;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: stats.total,
              label: '전체 아이템',
              color: ClosetimoColors.primary,
            ),
          ),
          Expanded(
            child: _StatCell(
              value: stats.clean,
              label: '깨끗한 의류',
              color: ClosetimoColors.ink,
            ),
          ),
          Expanded(
            child: _StatCell(
              value: stats.dirty,
              label: '관리 필요',
              color: ClosetimoColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: ClosetimoColors.muted,
          ),
        ),
      ],
    );
  }
}
