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
        BottomNavTab.settings => 'My',
      };

  IconData get icon => switch (this) {
        BottomNavTab.home => Icons.home_rounded,
        BottomNavTab.wardrobe => Icons.checkroom_rounded,
        BottomNavTab.laundry => Icons.local_laundry_service_rounded,
        BottomNavTab.settings => Icons.person_rounded,
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: surfaces.containerLowest.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(ClosetimoRadius.full),
          boxShadow: ClosetimoElevation.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: BottomNavTab.values.map((t) {
            final active = t == current;
            final color =
                active ? ClosetimoColors.primary : ClosetimoColors.muted;
            return InkWell(
              borderRadius: BorderRadius.circular(ClosetimoRadius.full),
              onTap: () => onTap(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClosetimoSpacing.md,
                  vertical: ClosetimoSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 22, color: color),
                    const SizedBox(height: 4),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
