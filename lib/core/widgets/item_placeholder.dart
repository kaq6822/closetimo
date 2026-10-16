// 사진이 없는 옷의 기본 플레이스홀더 (FR-003, #23).
// 단색 박스 위에 옷걸이 아이콘을 얹는다. 아이콘 크기는 박스에 비례한다.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

class ItemPlaceholder extends StatelessWidget {
  const ItemPlaceholder({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final size = side.isFinite ? (side * 0.36).clamp(16.0, 72.0) : 32.0;
          return Center(
            child: ExcludeSemantics(
              child: Icon(
                Icons.checkroom_outlined,
                size: size,
                color: ClosetimoColors.muted.withValues(alpha: 0.55),
              ),
            ),
          );
        },
      ),
    );
  }
}
