// #49 — 작은 컨트롤의 시각 크기는 유지하고 터치 가능한 영역만 최소
// [ClosetimoSize.minTouchTarget](48dp)로 넓히는 공용 래퍼.
//
// 사용 규칙:
//  - [child]는 시각 컨트롤 자체(아이콘 버튼, 체크 원, 칩 등)이며 자신의
//    InkWell·Semantics를 그대로 가진다. 시각 영역 안의 탭은 child가 받아
//    리플을 그리고, 바깥 여백의 탭만 이 래퍼가 [onTap]으로 전달한다.
//  - 시맨틱(라벨·button·checked·selected)은 child가 책임진다. 래퍼는 시맨틱
//    노드를 만들지 않아 TalkBack이 같은 동작을 두 번 읽지 않는다.
//  - 레이아웃 크기가 최소 48×48로 커지므로 주변 여백은 그만큼 줄여 맞춘다.

import 'package:flutter/widgets.dart';

import '../../app/theme/tokens.dart';

class MinTouchTarget extends StatelessWidget {
  const MinTouchTarget({required this.onTap, required this.child, super.key});

  /// 시각 영역 바깥 여백을 탭했을 때 실행할 동작. null이면 탭을 흡수만 한다.
  final VoidCallback? onTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: ClosetimoSize.minTouchTarget,
          minHeight: ClosetimoSize.minTouchTarget,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}
