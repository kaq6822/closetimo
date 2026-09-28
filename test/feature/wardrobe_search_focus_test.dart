// #14 회귀 — 옷장 검색창에 포커스를 둔 채 옷 상세로 들어갔다가 돌아오면
// Navigator가 이전 포커스를 복원해 키보드가 다시 올라왔다(QA F-04).
// 복귀 후 검색창에 포커스가 없고 키보드도 뜨지 않아야 한다.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/widgets/top_bar.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/wardrobe/wardrobe_screen.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
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
        if (q.isEmpty || i.name.contains(q)) i,
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
        name: Routes.wardrobe,
        builder: (ctx, st) => const Scaffold(body: WardrobeScreen()),
      ),
      GoRoute(
        path: '/item/:id',
        name: Routes.itemDetail,
        builder: (ctx, st) =>
            const Scaffold(body: Center(child: Text('DETAIL'))),
      ),
      GoRoute(
        path: '/add-item',
        name: Routes.addItem,
        builder: (ctx, st) => const Scaffold(body: Center(child: Text('ADD'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(repo),
      imageStoreProvider.overrideWithValue(ImageStore()),
    ],
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

EditableText _searchField(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText).first);

Future<void> _searchThenPushAndBack(
  WidgetTester tester, {
  required Finder target,
  required String routeText,
}) async {
  // 휴대폰 뷰포트(384×856dp) — 기본 800×600에선 타일이 화면 밖이다.
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.8125;
  addTearDown(tester.view.reset);

  final repo = _FakeItemRepository([
    Item(
      name: '울 코트',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 1,
  ]);
  await tester.pumpWidget(_harness(repo));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, '코트');
  await tester.pumpAndSettle();
  expect(_searchField(tester).focusNode.hasFocus, isTrue);
  expect(tester.testTextInput.isVisible, isTrue);

  // QA 절차: 키보드만 닫고(포커스는 남음) 다른 화면으로 push.
  tester.testTextInput.hide();
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(find.text(routeText), findsOneWidget);

  // Android 시스템 back.
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byType(GarmentTile), findsOneWidget);

  expect(_searchField(tester).focusNode.hasFocus, isFalse);
  expect(tester.testTextInput.isVisible, isFalse);
}

void main() {
  testWidgets('#14: 검색 후 옷 상세에서 돌아오면 검색창 포커스·키보드가 복원되지 않는다', (tester) async {
    await _searchThenPushAndBack(
      tester,
      target: find.byType(GarmentTile),
      routeText: 'DETAIL',
    );
  });

  testWidgets('#14: 검색 후 + (옷 등록)에서 돌아와도 키보드가 다시 뜨지 않는다', (tester) async {
    await _searchThenPushAndBack(
      tester,
      target: find.byType(TopBarPlusAction),
      routeText: 'ADD',
    );
  });
}
