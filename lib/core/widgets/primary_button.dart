// design.md §5 "Primary" — 알약 모양, Sage primary 배경, on-primary 텍스트.
// #48 FR-030 — [busy]면 탭을 막고 앞쪽 아이콘 자리에 진행 표시를 그린다.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  /// 이 버튼의 액션이 진행 중인가. 흐리게 하지 않고 진행 표시로 대신한다.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !busy;
    final leading = busy
        ? const SizedBox.square(
            dimension: ClosetimoSpacing.space18,
            child: CircularProgressIndicator(
              strokeWidth: ClosetimoSpacing.space2,
              color: ClosetimoColors.onPrimary,
            ),
          )
        : this.leading;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: ClosetimoColors.primary,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: busy ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: ClosetimoSpacing.space56,
            ),
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
                    child: leading,
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
