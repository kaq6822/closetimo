// go_router 정의. contracts/routes.md의 라우트 트리와 1:1 매핑.
// 각 탭 스크린은 Phase 3~7에서 실제 위젯으로 교체된다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';
import '../core/widgets/top_bar.dart';
import '../core/widgets/toast.dart';
import '../app/theme/tokens.dart';

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
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _MainShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home',
            name: Routes.home,
            builder: (ctx, st) =>
                const _PlaceholderScreen(label: '홈', tab: BottomNavTab.home),
          ),
          GoRoute(
            path: '/wardrobe',
            name: Routes.wardrobe,
            builder: (ctx, st) => _PlaceholderScreen(
              label: '옷장${st.uri.queryParameters['category'] != null ? ' · ${st.uri.queryParameters['category']}' : ''}',
              tab: BottomNavTab.wardrobe,
            ),
          ),
          GoRoute(
            path: '/laundry',
            name: Routes.laundry,
            builder: (ctx, st) => const _PlaceholderScreen(
              label: '세탁 바구니',
              tab: BottomNavTab.laundry,
            ),
          ),
          GoRoute(
            path: '/settings',
            name: Routes.settings,
            builder: (ctx, st) => const _PlaceholderScreen(
              label: '설정',
              tab: BottomNavTab.settings,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        name: Routes.itemDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, st) => _PlaceholderModal(
          title: '옷 상세 (id: ${st.pathParameters['id']})',
        ),
      ),
      GoRoute(
        path: '/add-item',
        name: Routes.addItem,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (ctx, st) => CustomTransitionPage(
          child: const _PlaceholderModal(title: '신규 옷 등록'),
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

class _MainShell extends StatelessWidget {
  const _MainShell({required this.location, required this.child});

  final String location;
  final Widget child;

  BottomNavTab get _current {
    if (location.startsWith('/wardrobe')) return BottomNavTab.wardrobe;
    if (location.startsWith('/laundry')) return BottomNavTab.laundry;
    if (location.startsWith('/settings')) return BottomNavTab.settings;
    return BottomNavTab.home;
  }

  void _onTap(BuildContext context, BottomNavTab t) {
    switch (t) {
      case BottomNavTab.home:
        context.goNamed(Routes.home);
      case BottomNavTab.wardrobe:
        context.goNamed(Routes.wardrobe);
      case BottomNavTab.laundry:
        context.goNamed(Routes.laundry);
      case BottomNavTab.settings:
        context.goNamed(Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNav(
        current: _current,
        onTap: (t) => _onTap(context, t),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label, required this.tab});

  final String label;
  final BottomNavTab tab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(
          rightSlot: TopBarPlusAction(
            onTap: () => context.goNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(ClosetimoSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: ClosetimoSpacing.md),
                  Text(
                    'Phase 2 셸. ${tab.label} 화면은 후속 phase에서 채워진다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ClosetimoSpacing.lg),
                  TextButton(
                    onPressed: () => showClosetimoToast(
                      context,
                      'Phase 2 토스트 ✓',
                    ),
                    child: const Text('토스트 테스트'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
