// US5 T073 — 설정 항목 행 (토글 또는 텍스트 값).

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';

class PreferenceRow extends StatelessWidget {
  const PreferenceRow({
    required this.label,
    this.toggleValue,
    this.onToggle,
    this.textValue,
    super.key,
  });

  final String label;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final String? textValue;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: ClosetimoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: surfaces.containerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: ClosetimoColors.ink,
              ),
            ),
          ),
          if (toggleValue != null && onToggle != null)
            Switch.adaptive(
              value: toggleValue!,
              onChanged: onToggle,
              activeThumbColor: ClosetimoColors.onPrimary,
              activeTrackColor: ClosetimoColors.primary,
            )
          else if (textValue != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  textValue!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: ClosetimoColors.muted,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: ClosetimoColors.muted,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
