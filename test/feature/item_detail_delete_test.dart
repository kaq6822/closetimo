// 002 US2 — 옷 상세 삭제 UI 플로우: 오버플로 메뉴 → 확인 다이얼로그 → delete
// 호출 → 옷장 탭 복귀(FR-012). repository 로직은 item_edit_delete_test에서 별도 검증.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/item_detail/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeItemRepo implements ItemRepository {
  _FakeItemRepo(this.item);
  final Item item;
  final List<int> deleted = [];

  @override
  Future<Item?> get(int id) async => id == item.id ? item : null;

  @override
  Future<void> delete(int id) async => deleted.add(id);

  @override
  Future<int> create(_) async => throw UnimplementedError();
  @override
  Future<void> update(int id, ItemPatch patch) async =>
      throw UnimplementedError();
  @override
  Stream<List<Item>> watchAll() => const Stream.empty();
  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) =>
      const Stream.empty();
  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();
  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
}

class _FakeEventRepo implements EventRepository {
  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(const []);
  @override
  Future<void> recordWear(int itemId, {String? note}) async {}
  @override
  Future<void> updateEventNote(int eventId, String? note) async {}
  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

Widget _harness(_FakeItemRepo itemRepo) {
  final router = GoRouter(
    initialLocation: '/item/1',
    routes: [
      GoRoute(
        path: '/wardrobe',
        name: Routes.wardrobe,
        builder: (ctx, st) =>
            const Scaffold(body: Center(child: Text('WARDROBE'))),
      ),
      GoRoute(
        path: '/item/:id',
        builder: (ctx, st) =>
            ItemDetailScreen(id: int.parse(st.pathParameters['id']!)),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(itemRepo),
      eventRepositoryProvider.overrideWithValue(_FakeEventRepo()),
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

Item _seed() => Item(
      name: '삭제 대상 코트',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 1;

void main() {
  testWidgets('US2 AC1: 오버플로 → 삭제하기 → 확인 → delete + 옷장 탭 복귀',
      (tester) async {
    final repo = _FakeItemRepo(_seed());
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();

    // 확인 다이얼로그
    expect(find.text('이 옷을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(repo.deleted, [1]);
    expect(find.text('WARDROBE'), findsOneWidget); // 옷장 탭 복귀(FR-012)

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('US2 AC2: 삭제 취소 시 아무것도 삭제되지 않고 상세 유지',
      (tester) async {
    final repo = _FakeItemRepo(_seed());
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(repo.deleted, isEmpty);
    expect(find.text('삭제 대상 코트'), findsOneWidget); // 상세 유지
    expect(find.text('WARDROBE'), findsNothing);
  });
}
