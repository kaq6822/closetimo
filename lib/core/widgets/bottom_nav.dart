// 4탭 하단 네비게이션. go_router StatefulShellRoute의 indexedStack과 연동된다.

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum BottomNavTab { home, wardrobe, laundry, settings }

extension BottomNavTabMeta on BottomNavTab {
  String get label => switch (this) {
    BottomNavTab.home => '홈',
    BottomNavTab.wardrobe => '옷장',
    BottomNavTab.laundry => '세탁',
    BottomNavTab.settings => '설정',
  };

  IconData get icon => switch (this) {
    BottomNavTab.home => Icons.home_rounded,
    BottomNavTab.wardrobe => Icons.checkroom_rounded,
    BottomNavTab.laundry => Icons.local_laundry_service_rounded,
    // #49(UI-15) — 계정 기능이 없으므로 사람 대신 톱니바퀴로 기능을 드러낸다.
    BottomNavTab.settings => Icons.settings_rounded,
  };

  /// 단일 출처화 — go_router path와 활성 탭 판정이 본 게터만 참조한다.
  String get path => switch (this) {
    BottomNavTab.home => '/home',
    BottomNavTab.wardrobe => '/wardrobe',
    BottomNavTab.laundry => '/laundry',
    BottomNavTab.settings => '/settings',
  };

  static BottomNavTab fromLocation(String location) {
    for (final t in BottomNavTab.values) {
      if (location.startsWith(t.path)) return t;
    }
    return BottomNavTab.home;
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({required this.current, required this.onTap, super.key});

  final BottomNavTab current;
  final ValueChanged<BottomNavTab> onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          ClosetimoSpacing.md,
          0,
          ClosetimoSpacing.md,
          ClosetimoSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(vertical: ClosetimoSpacing.space6),
        decoration: BoxDecoration(
          color: surfaces.containerLowest.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(ClosetimoRadius.full),
          boxShadow: ClosetimoElevation.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: BottomNavTab.values.map((t) {
            final active = t == current;
            final color = active
                ? ClosetimoColors.primary
                : ClosetimoColors.muted;
            // #49(UI-15) — 선택 상태를 색·굵기 외에 아이콘 뒤 알약 배경으로도
            // 드러내고, 시맨틱 selected로 TalkBack에 "선택됨"을 전달한다.
            return Semantics(
              container: true,
              button: true,
              selected: active,
              label: t.label,
              excludeSemantics: true,
              onTap: () => onTap(t),
              child: InkWell(
                borderRadius: BorderRadius.circular(ClosetimoRadius.full),
                onTap: () => onTap(t),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: ClosetimoSize.minTouchTarget,
                    minHeight: ClosetimoSize.minTouchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClosetimoSpacing.space10,
                      vertical: ClosetimoSpacing.space4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          key: ValueKey('bottomNavIndicator-${t.name}'),
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: ClosetimoSpacing.space12,
                            vertical: ClosetimoSpacing.space2,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? ClosetimoColors.primarySoft
                                : ClosetimoColors.primarySoft.withValues(
                                    alpha: 0,
                                  ),
                            borderRadius: BorderRadius.circular(
                              ClosetimoRadius.full,
                            ),
                          ),
                          child: Icon(t.icon, size: 22, color: color),
                        ),
                        const SizedBox(height: ClosetimoSpacing.space2),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
