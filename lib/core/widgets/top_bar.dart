// 공용 상단바. 좌측 백 버튼·중앙 브랜드/서브타이틀, 우측 액션 슬롯.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    this.title = '옷장이모',
    this.subtitle,
    this.onBack,
    this.rightSlot,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? rightSlot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClosetimoSpacing.md,
        ClosetimoSpacing.sm,
        ClosetimoSpacing.lg,
        ClosetimoSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            _IconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack!),
          if (onBack != null) const SizedBox(width: 8),
          Text(
            subtitle ?? title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: subtitle != null ? 14 : 17,
              fontWeight: FontWeight.w600,
              color: ClosetimoColors.ink,
              letterSpacing: subtitle != null ? 0 : 0.2,
            ),
          ),
          const Spacer(),
          if (rightSlot != null) rightSlot!,
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: ClosetimoColors.ink),
      ),
    );
  }
}

/// AppBar 우측에 자주 쓰이는 + 버튼.
class TopBarPlusAction extends StatelessWidget {
  const TopBarPlusAction({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _IconButton(icon: Icons.add_rounded, onTap: onTap);
  }
}
