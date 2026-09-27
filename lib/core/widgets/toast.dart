// FR-023 — 2초 비차단 토스트. Material SnackBar 대신 Overlay 기반으로
// 디자인 패키지의 둥근 알약 + 좌측 체크 스타일을 재현한다.
// 스크린리더가 낭독하도록 live region으로 노출한다(#17).

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

/// 토스트 노출 위치.
enum ToastPlacement {
  /// 하단 탭 위. 탭 화면과, 토스트 직후 탭 화면으로 복귀하는 흐름의 기본값.
  bottom,

  /// 상단바 바로 아래. 하단 탭이 없고 방금 누른 버튼이 화면 하단에 오기 쉬운
  /// 스크롤 화면(옷 상세)에서 버튼을 가리지 않도록 쓴다(#22).
  top,
}

/// 상단 배치 시 SafeArea 기준 오프셋. 우측 슬롯에 48dp 아이콘 버튼을 둔
/// TopBar 높이(8 + 48 + 8)보다 약간 아래에 둔다.
const double _topOffset = ClosetimoSpacing.huge + ClosetimoSpacing.xl;

/// 하단 배치 시 오프셋. 하단 탭(BottomNav, 약 80dp) 위에 뜨도록 한다.
/// 탭 높이에 맞춘 레이아웃 값이라 간격 토큰 조합으로 쪼개지 않는다.
const double _bottomOffset = 100;

void showClosetimoToast(
  BuildContext context,
  String message, {
  ToastPlacement placement = ToastPlacement.bottom,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastBubble(
      message: message,
      placement: placement,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _ToastBubble extends StatefulWidget {
  const _ToastBubble({
    required this.message,
    required this.placement,
    required this.onDismissed,
  });

  final String message;
  final ToastPlacement placement;
  final VoidCallback onDismissed;

  @override
  State<_ToastBubble> createState() => _ToastBubbleState();
}

class _ToastBubbleState extends State<_ToastBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _ctl,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _ctl.forward();
    Future<void>.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      await _ctl.reverse();
      if (!mounted) return;
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final isTop = widget.placement == ToastPlacement.top;
    final bubble = Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClosetimoSpacing.lg,
          vertical: ClosetimoSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: surfaces.containerLowest,
          borderRadius: BorderRadius.circular(ClosetimoRadius.full),
          boxShadow: ClosetimoElevation.ambientShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: ClosetimoColors.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ClosetimoColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Positioned(
      top: isTop ? _topOffset : null,
      bottom: isTop ? null : _bottomOffset,
      left: ClosetimoSpacing.xl,
      right: ClosetimoSpacing.xl,
      // 비차단(FR-023) — 토스트가 버튼 위에 겹쳐도 탭은 아래로 통과한다.
      // IgnorePointer는 포인터만 막고 시맨틱(liveRegion)은 유지한다.
      child: IgnorePointer(
        child: SafeArea(
          top: isTop,
          bottom: !isTop,
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, isTop ? -0.4 : 0.4),
                  end: Offset.zero,
                ).animate(_curve),
                child: bubble,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
