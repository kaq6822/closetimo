// design.md §5 "의류 칩" — 활성: primary 배경, 비활성: secondary-container.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class ChipFilter extends StatelessWidget {
  const ChipFilter({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? ClosetimoColors.primary
          : ClosetimoColors.secondaryContainer,
      borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClosetimoSpacing.md,
            vertical: ClosetimoSpacing.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? ClosetimoColors.onPrimary : ClosetimoColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
