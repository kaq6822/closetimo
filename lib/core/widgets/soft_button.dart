// design.md §5 "Secondary" — surface-container-highest 배경, 보더 없음.

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

class SoftButton extends StatelessWidget {
  const SoftButton({
    required this.label,
    required this.onPressed,
    this.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Material(
      color: surfaces.containerHighest,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: ClosetimoSpacing.lg,
            vertical: ClosetimoSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                IconTheme.merge(
                  data: const IconThemeData(
                    color: ClosetimoColors.ink,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ClosetimoColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
