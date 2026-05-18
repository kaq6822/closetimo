// go_router 정의. contracts/routes.md의 라우트 트리와 1:1 매핑.
// 각 탭 스크린은 Phase 3~7에서 실제 위젯으로 교체된다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';
import '../core/widgets/top_bar.dart';
import '../data/models/item.dart';
import '../features/add_item/add_item_screen.dart';
import '../features/home/home_screen.dart';
import '../features/item_detail/item_detail_screen.dart';
import '../features/laundry/laundry_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/wardrobe/wardrobe_screen.dart';
import '../data/providers/app_providers.dart';

/// 라우트 이름 상수. UI 코드는 문자열 리터럴 대신 본 상수만 사용한다.
abstract final class Routes {
  static const home = 'home';
  static const wardrobe = 'wardrobe';
  static const laundry = 'laundry';
  static const settings = 'settings';
  static const itemDetail = 'itemDetail';
  static const addItem = 'addItem';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellHomeKey = GlobalKey<NavigatorState>();
final _shellWardrobeKey = GlobalKey<NavigatorState>();
final _shellLaundryKey = GlobalKey<NavigatorState>();
final _shellSettingsKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  // FR-022 lastTab 복원: 본 provider 생성 시점은 ClosetimoApp이 prefs를
  // resolve한 후이므로 `valueOrNull`이 거의 항상 hit (한 번만 평가).
  final prefs = ref.read(preferencesStreamProvider).valueOrNull;
  final initial = prefs?.lastTab ?? BottomNavTab.home.path;
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initial,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => _MainShell(navShell: navShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellHomeKey,
            routes: [
              GoRoute(
                path: BottomNavTab.home.path,
                name: Routes.home,
                builder: (ctx, st) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellWardrobeKey,
            routes: [
              GoRoute(
                path: BottomNavTab.wardrobe.path,
                name: Routes.wardrobe,
                builder: (ctx, st) {
                  final raw = st.uri.queryParameters['category'];
                  Category? cat;
                  if (raw != null) {
                    for (final c in Category.values) {
                      if (c.label == raw || c.name == raw) {
                        cat = c;
                        break;
                      }
                    }
                  }
                  return WardrobeScreen(initialCategory: cat);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellLaundryKey,
            routes: [
              GoRoute(
                path: BottomNavTab.laundry.path,
                name: Routes.laundry,
                builder: (ctx, st) => const LaundryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellSettingsKey,
            routes: [
              GoRoute(
                path: BottomNavTab.settings.path,
                name: Routes.settings,
                builder: (ctx, st) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        name: Routes.itemDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, st) {
          final id = int.tryParse(st.pathParameters['id'] ?? '');
          if (id == null) return const _PlaceholderModal(title: '옷 상세');
          return ItemDetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/add-item',
        name: Routes.addItem,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (ctx, st) => CustomTransitionPage(
          child: const AddItemScreen(),
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  const _MainShell({required this.navShell});

  final StatefulNavigationShell navShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(child: navShell),
      bottomNavigationBar: BottomNav(
        current: BottomNavTab.values[navShell.currentIndex],
        onTap: (t) {
          navShell.goBranch(
            t.index,
            initialLocation: t.index == navShell.currentIndex,
          );
          // 탭 전환 시 FR-022에 따라 lastTab을 영속화.
          unawaited(
            ref.read(preferencesRepositoryProvider).setLastTab(t.path),
          );
        },
      ),
    );
  }
}

class _PlaceholderModal extends StatelessWidget {
  const _PlaceholderModal({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              subtitle: title,
              onBack: () => context.pop(),
            ),
            const Expanded(
              child: Center(
                child: Text('Phase 2 모달 placeholder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
