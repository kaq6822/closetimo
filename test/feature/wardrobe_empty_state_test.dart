// 옷장 탭 빈 상태 분기 테스트.
//
// 옷장 자체가 빈 상태(첫 등록 유도)와 검색·필터 무결과 상태는 서로 다른
// 안내 문구를 보여야 한다 (iOS 시뮬레이터 검증에서 발견된 UX 이슈의 회귀 방지).

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/wardrobe/wardrobe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository(this.items);

  final List<Item> items;

  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) {
    final q = query.trim();
    return Stream.value([
      for (final i in items)
        if ((category == null || i.category == category) &&
            (q.isEmpty || i.name.contains(q)))
          i,
    ]);
  }

  @override
  Future<int> create(NewItemDraft draft) async => 0;

  @override
  Future<Item?> get(int id) async => null;

  @override
  Stream<List<Item>> watchAll() => Stream.value(items);

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();

  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();

  @override
  Future<void> update(int id, ItemPatch patch) async {}

  @override
  Future<void> delete(int id) async {}
}

Widget _harness(ItemRepository repo) {
  final router = GoRouter(
    initialLocation: '/wardrobe',
    routes: [
      GoRoute(
        path: '/wardrobe',
        name: 'wardrobe',
        builder: (ctx, st) => const Scaffold(body: WardrobeScreen()),
      ),
      GoRoute(
        path: '/add-item',
        name: 'addItem',
        builder: (ctx, st) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  return ProviderScope(
    overrides: [itemRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      theme: buildClosetimoTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('옷장이 비어 있으면 첫 등록 유도 문구를 보여준다', (tester) async {
    await tester.pumpWidget(_harness(_FakeItemRepository([])));
    await tester.pumpAndSettle();

    expect(
      find.text('아직 등록된 옷이 없어요.\n오른쪽 위 + 버튼으로 첫 옷을 등록해 보세요.'),
      findsOneWidget,
    );
    expect(find.text('검색 결과가 없습니다.'), findsNothing);
  });

  testWidgets('검색 무결과일 때만 검색 결과 없음 문구를 보여준다', (tester) async {
    final repo = _FakeItemRepository([
      Item(
        name: '캐시미어 코트',
        category: Category.outer,
        washCycle: 5,
        createdAt: DateTime(2026, 1, 1),
      )..id = 1,
    ]);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    // 아이템이 있으므로 빈 상태 문구가 없다.
    expect(find.text('캐시미어 코트'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '존재하지않는옷');
    await tester.pumpAndSettle();

    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    expect(
      find.text('아직 등록된 옷이 없어요.\n오른쪽 위 + 버튼으로 첫 옷을 등록해 보세요.'),
      findsNothing,
    );
  });
}
