// design.md §5 "Primary" — 알약 모양, Sage primary 배경, on-primary 텍스트.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: ClosetimoColors.primary,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: ClosetimoSpacing.xl,
              vertical: ClosetimoSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: const IconThemeData(
                      color: ClosetimoColors.onPrimary,
                      size: 18,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: ClosetimoSpacing.sm),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ClosetimoColors.onPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: ClosetimoSpacing.sm),
                  IconTheme.merge(
                    data: const IconThemeData(
                      color: ClosetimoColors.onPrimary,
                      size: 18,
                    ),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
