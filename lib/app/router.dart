// go_router 정의. contracts/routes.md의 라우트 트리와 1:1 매핑.
// 각 탭 스크린은 Phase 3~7에서 실제 위젯으로 교체된다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';
import '../core/widgets/top_bar.dart';
import '../data/models/item.dart';
import '../data/models/item_filter.dart';
import '../data/models/item_tags.dart';
import '../features/add_item/add_item_screen.dart';
import '../features/archive/archive_screen.dart';
import '../features/home/home_screen.dart';
import '../features/item_detail/item_detail_screen.dart';
import '../features/laundry/laundry_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tags/tag_manage_screen.dart';
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
  static const editItem = 'editItem';

  /// 보관함(#44). 설정 > 옷 관리에서 push로 진입한다.
  static const archive = 'archive';

  /// 태그 관리(#46). 설정 > 옷 관리에서 push로 진입한다.
  static const tags = 'tags';
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
  final initial = initialLocationForLastTab(prefs?.lastTab);
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
                builder: (ctx, st) => WardrobeScreen(
                  initialFilter: wardrobeFilterFromQuery(
                    st.uri.queryParameters,
                  ),
                ),
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
        pageBuilder: (ctx, st) => _slideUpPage(const AddItemScreen()),
      ),
      GoRoute(
        path: '/item/:id/edit',
        name: Routes.editItem,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (ctx, st) {
          final id = int.tryParse(st.pathParameters['id'] ?? '');
          if (id == null) {
            return _slideUpPage(const _PlaceholderModal(title: '옷 수정'));
          }
          return _slideUpPage(AddItemScreen(editId: id));
        },
      ),
      GoRoute(
        path: '/archive',
        name: Routes.archive,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, st) => const ArchiveScreen(),
      ),
      GoRoute(
        path: '/tags',
        name: Routes.tags,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, st) => const TagManageScreen(),
      ),
    ],
  );
});

/// `/wardrobe` 쿼리 → 옷장 필터(contracts/routes.md §1, #37·#41).
///
/// - `category=<Category.name>`: 개별 종류 1개(예: `etc`는 개별 '기타'만).
///   과거 링크 호환을 위해 한국어 라벨도 받는다.
/// - `group=<HomeBucket.name>`: 홈 카드 합산 범위(예: `others` = '그 외').
///   `category`와 함께 오면 `group`이 우선한다.
/// - `purpose=<ItemPurpose.name>[,…]`: 용도 축(OR).
/// - `tag=<태그>[,…]`: 사용자 태그 축(OR, #46). 태그에는 쉼표가 없다(정규화 규칙).
/// 알 수 없는 값은 무시한다(전체).
ItemFilter wardrobeFilterFromQuery(Map<String, String> query) {
  var categories = <Category>{};
  final group = query['group'];
  final rawCategory = query['category'];
  if (group != null) {
    for (final b in HomeBucket.values) {
      if (b.name == group) categories = b.categories;
    }
  } else if (rawCategory != null) {
    for (final c in Category.values) {
      if (c.name == rawCategory || c.label == rawCategory) {
        categories = {c};
        break;
      }
    }
  }
  final purposes = <ItemPurpose>{
    for (final raw in (query['purpose'] ?? '').split(','))
      for (final p in ItemPurpose.values)
        if (p.name == raw) p,
  };
  final tags = normalizeTags((query['tag'] ?? '').split(',')).toSet();
  return ItemFilter(categories: categories, purposes: purposes, tags: tags);
}

/// 옷장 필터 → `/wardrobe` 쿼리. [wardrobeFilterFromQuery]의 역방향이며
/// 검색어는 URL에 싣지 않는다. 홈 버킷과 같은 다중 종류는 `group`으로 표현한다.
Map<String, String> wardrobeQueryParameters(ItemFilter filter) {
  final params = <String, String>{};
  final group = filter.groupBucket;
  if (group != null) {
    params['group'] = group.name;
  } else if (filter.categories.length == 1) {
    params['category'] = filter.categories.single.name;
  }
  if (filter.purposes.isNotEmpty) {
    final names = filter.purposes.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    params['purpose'] = names.map((p) => p.name).join(',');
  }
  if (filter.tags.isNotEmpty) {
    params['tag'] = (filter.tags.toList()..sort()).join(',');
  }
  return params;
}

/// 과거 버전이 탭 이름만 저장한 경우와 손상된 값을 안전한 경로로 정규화한다.
String initialLocationForLastTab(String? lastTab) {
  if (lastTab == null || lastTab.isEmpty) {
    return BottomNavTab.home.path;
  }
  final candidate = lastTab.startsWith('/') ? lastTab : '/$lastTab';
  final isKnownTab = BottomNavTab.values.any((tab) => tab.path == candidate);
  return isKnownTab ? candidate : BottomNavTab.home.path;
}

/// 하단에서 밀려 올라오는 slide-up transition 페이지(등록·수정 모달 공용).
CustomTransitionPage<void> _slideUpPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, anim, secondaryAnim, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

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
          unawaited(ref.read(preferencesRepositoryProvider).setLastTab(t.path));
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
            TopBar(subtitle: title, onBack: () => context.pop()),
            const Expanded(
              child: Center(child: Text('Phase 2 모달 placeholder')),
            ),
          ],
        ),
      ),
    );
  }
}
