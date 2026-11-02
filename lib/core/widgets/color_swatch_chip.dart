// 005 — 색상 선택 칩(등록 폼·정리하기·옷장 상세 필터 공용).
// 원형 스와치 + 라벨. 선택은 primary 배경과 체크 표시로, 색 외 단서도 준다(#49).

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'min_touch_target.dart';

class ColorSwatchChip extends StatelessWidget {
  const ColorSwatchChip({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// 스와치 색. 카탈로그의 의류 색(디자인 토큰이 아니라 데이터 값)이다.
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MinTouchTarget(
      onTap: onTap,
      child: Semantics(
        container: true,
        button: true,
        selected: selected,
        label: '$label 색',
        excludeSemantics: true,
        child: Material(
          color: selected
              ? ClosetimoColors.primary
              : ClosetimoColors.secondaryContainer,
          borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClosetimoSpacing.space10,
                vertical: ClosetimoSpacing.space6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorDot(color: color, size: ClosetimoSize.colorSwatch),
                  const SizedBox(width: ClosetimoSpacing.space6),
                  Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? ClosetimoColors.onPrimary
                          : ClosetimoColors.ink,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: ClosetimoSpacing.xs),
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: ClosetimoColors.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 테두리가 있는 원형 색 점. 흰색·아이보리도 배경과 구분되게 윤곽선을 그린다.
class ColorDot extends StatelessWidget {
  const ColorDot({
    required this.color,
    this.size = ClosetimoSize.colorDot,
    super.key,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ClosetimoColors.outlineVariantGhost),
      ),
    );
  }
}
