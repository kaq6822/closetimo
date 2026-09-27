// 공용 상단바. 좌측 백 버튼·중앙 브랜드/서브타이틀, 우측 액션 슬롯.
// 서브타이틀이 없는 브랜드 모드에서는 워드마크 앞에 B1 미소 옷걸이 심볼을 둔다.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 브랜드 심볼 에셋 경로. 해상도별 변형은 `assets/images/2.0x`, `3.0x`에 있다.
const closetimoSymbolAsset = 'assets/images/closetimo_symbol.png';

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
            _IconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticLabel: '뒤로 가기',
              onTap: onBack!,
            ),
          if (onBack != null) const SizedBox(width: 8),
          if (subtitle == null) ...[
            Image.asset(
              closetimoSymbolAsset,
              key: const ValueKey('topBarBrandSymbol'),
              width: 28,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: ClosetimoSpacing.sm),
          ],
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

/// 아이콘만 있는 버튼. 스크린리더용 [semanticLabel]을 필수로 받는다(#17).
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: ClosetimoColors.ink),
        ),
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
    return _IconButton(
      icon: Icons.add_rounded,
      semanticLabel: '옷 등록',
      onTap: onTap,
    );
  }
}
