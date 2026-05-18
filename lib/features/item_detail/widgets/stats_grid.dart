// US3 T051 — 옷 상세 2x2 통계 카드.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/item.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Container(
      decoration: BoxDecoration(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '세탁 후 착용 횟수',
                  value: '${item.wearSinceWash}',
                  trailing: ' /${item.washCycle}회',
                  hint: '• 목표: ${item.washCycle}회 착용 후 세탁',
                  bg: surfaces.containerLowest,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: '총 착용 횟수',
                  value: '${item.totalWears}',
                  trailing: '회',
                  bg: surfaces.containerLowest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '마지막 세탁',
                  value: item.lastWashedAt == null
                      ? '—'
                      : formatMonthDayOrDash(item.lastWashedAt),
                  smallValue: true,
                  bg: surfaces.containerLowest,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: '구매일',
                  value: item.purchasedAt == null
                      ? '—'
                      : formatFullDate(item.purchasedAt!),
                  smallValue: true,
                  bg: surfaces.containerLowest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.bg,
    this.trailing,
    this.hint,
    this.smallValue = false,
  });

  final String label;
  final String value;
  final String? trailing;
  final String? hint;
  final Color bg;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lg + 2),
      ),
      padding: const EdgeInsets.all(ClosetimoSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              letterSpacing: 1,
              color: ClosetimoColors.muted,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.sm),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: smallValue ? 17 : 28,
                fontWeight: FontWeight.w700,
                color: ClosetimoColors.ink,
              ),
              children: trailing != null
                  ? [
                      TextSpan(
                        text: trailing,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: ClosetimoColors.muted,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: ClosetimoColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
