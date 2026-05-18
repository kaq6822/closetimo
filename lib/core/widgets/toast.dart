// FR-023 — 2초 비차단 토스트. Material SnackBar 대신 Overlay 기반으로
// 디자인 패키지의 둥근 알약 + 좌측 체크 스타일을 재현한다.

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

void showClosetimoToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final entry = OverlayEntry(
    builder: (ctx) => _ToastBubble(message: message),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2200), entry.remove);
}

class _ToastBubble extends StatefulWidget {
  const _ToastBubble({required this.message});

  final String message;

  @override
  State<_ToastBubble> createState() => _ToastBubbleState();
}

class _ToastBubbleState extends State<_ToastBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _ctl,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(_curve),
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
            ),
          ),
        ),
      ),
    );
  }
}
