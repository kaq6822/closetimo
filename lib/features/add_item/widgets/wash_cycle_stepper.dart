// US1 T035 — 세탁 주기 -/+ 스테퍼. 최소값 1.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';

class WashCycleStepper extends StatelessWidget {
  const WashCycleStepper({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Container(
      decoration: BoxDecoration(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ClosetimoSpacing.md,
        vertical: ClosetimoSpacing.sm + 4,
      ),
      child: Row(
        children: [
          const Text(
            '착용 횟수',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ClosetimoColors.ink,
            ),
          ),
          const Spacer(),
          _RoundButton(
            icon: Icons.remove_rounded,
            background: surfaces.containerLowest,
            foreground: ClosetimoColors.ink,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          const SizedBox(width: ClosetimoSpacing.sm + 4),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ClosetimoColors.ink,
              ),
            ),
          ),
          const SizedBox(width: ClosetimoSpacing.sm + 4),
          _RoundButton(
            icon: Icons.add_rounded,
            background: ClosetimoColors.primary,
            foreground: ClosetimoColors.onPrimary,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: background.withValues(alpha: disabled ? 0.5 : 1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: foreground),
        ),
      ),
    );
  }
}
