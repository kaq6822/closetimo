// FR-019 / US5 AC2 — 홈 카테고리 카드 → 옷장 탭 필터 사전 적용 회귀 테스트(#13).
//
// StatefulShellRoute.indexedStack은 옷장 브랜치 State를 보존하므로, 옷장 탭을
// 먼저 연 뒤에 들어온 `?category=` 쿼리가 무시되던 결함을 실제 라우터·셸로 재현한다.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/core/widgets/bottom_nav.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/data/repositories/preferences_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/home/widgets/category_bento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 9, 27, 9);
}

class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository(this.items);

  final List<Item> items;
  final List<int> deleted = [];

  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) => Stream.value([
    for (final i in items)
      if (category == null || i.category == category) i,
  ]);

  @override
  Stream<WardrobeStats> watchStats() => Stream.value(
    WardrobeStats(
      total: items.length,
      clean: items.length,
      dirty: 0,
      perBucket: {
        for (final c in Category.values)
          c: items.where((i) => i.category.homeBucket == c).length,
      },
    ),
  );

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) =>
      Stream.value(const []);

  @override
  Stream<List<Item>> watchAll() => Stream.value(items);

  @override
  Future<Item?> get(int id) async => items.where((i) => i.id == id).firstOrNull;

  @override
  Future<int> create(NewItemDraft draft) async => 0;

  @override
  Future<void> update(int id, ItemPatch patch) async {}

  @override
  Future<void> delete(int id) async => deleted.add(id);
}

class _FakeEventRepository implements EventRepository {
  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(const []);

  @override
  Future<void> recordWear(int itemId, {String? note}) async {}

  @override
  Future<void> updateEventNote(int eventId, String? note) async {}

  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

class _FakeLaundryRepository implements LaundryRepository {
  @override
  Stream<List<Item>> watchBasket() => Stream.value(const []);

  @override
  Future<void> toggle(int itemId) async {}

  @override
  Future<void> completeWashFor(List<int> itemIds) async {}
}

class _FakePreferencesRepository implements PreferencesRepository {
  @override
  Stream<UserPreferences> watch() => Stream.value(UserPreferences.defaults());

  @override
  Future<void> setLastTab(String tab) async {}

  @override
  Future<void> setAccent(String accentKey) async {}

  @override
  Future<void> setNotifWash(bool v) async {}

  @override
  Future<void> setNotifWeekly(bool v) async {}

  @override
  Future<void> setNotifUnworn(bool v) async {}
}

Item _item(int id, String name, Category category) => Item(
  name: name,
  category: category,
  washCycle: 5,
  createdAt: DateTime(2026, 9, 1),
)..id = id;

/// main.dart의 `_RouterApp`과 같은 구성으로 실제 [goRouterProvider]·셸을 띄운다.
/// lastTab을 `/wardrobe`로 두어 "옷장 탭이 먼저 열린" 상태에서 시작한다.
Widget _harness(List<Item> items, {_FakeItemRepository? repo}) {
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(
        repo ?? _FakeItemRepository(items),
      ),
      eventRepositoryProvider.overrideWithValue(_FakeEventRepository()),
      laundryRepositoryProvider.overrideWithValue(_FakeLaundryRepository()),
      preferencesRepositoryProvider.overrideWithValue(
        _FakePreferencesRepository(),
      ),
      preferencesStreamProvider.overrideWith(
        (ref) =>
            Stream.value(UserPreferences(lastTab: BottomNavTab.wardrobe.path)),
      ),
      clockProvider.overrideWithValue(_FixedClock()),
    ],
    child: Consumer(
      // ClosetimoApp처럼 prefs 첫 emit 이후에만 router를 만든다(FR-022 lastTab).
      builder: (context, ref, _) =>
          !ref.watch(preferencesStreamProvider).hasValue
          ? const SizedBox.shrink()
          : MaterialApp.router(
              theme: buildClosetimoTheme(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('ko', 'KR')],
              routerConfig: ref.watch(goRouterProvider),
            ),
    ),
  );
}

Future<void> _tapTab(WidgetTester tester, BottomNavTab tab) async {
  await tester.tap(
    find.descendant(of: find.byType(BottomNav), matching: find.text(tab.label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapHomeCard(WidgetTester tester, Category category) async {
  final card = find.descendant(
    of: find.byType(CategoryBento),
    matching: find.text(category.label),
  );
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

ScrollPosition _wardrobeScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

void main() {
  final items = [
    _item(1, '캐시미어 니트', Category.top),
    _item(2, '셀비지 데님', Category.bottom),
    _item(3, '오버사이즈 코트', Category.outer),
  ];

  testWidgets('옷장 탭을 먼저 연 뒤 홈 상의 카드를 탭하면 상의 필터가 적용된다', (tester) async {
    await tester.pumpWidget(_harness(items));
    await tester.pumpAndSettle();

    // lastTab 복원으로 옷장 탭이 먼저 열려 전체 목록이 보인다.
    expect(find.text('셀비지 데님'), findsOneWidget);
    expect(find.text('캐시미어 니트'), findsOneWidget);

    await _tapTab(tester, BottomNavTab.home);
    await _tapHomeCard(tester, Category.top);

    expect(find.text('캐시미어 니트'), findsOneWidget);
    expect(find.text('셀비지 데님'), findsNothing);
    expect(find.text('오버사이즈 코트'), findsNothing);
  });

  testWidgets('칩으로 필터를 바꾼 뒤 같은 홈 카드를 다시 탭해도 카드 필터가 적용된다', (tester) async {
    await tester.pumpWidget(_harness(items));
    await tester.pumpAndSettle();

    await _tapTab(tester, BottomNavTab.home);
    await _tapHomeCard(tester, Category.top);
    expect(find.text('셀비지 데님'), findsNothing);

    // 옷장 화면에서 칩으로 "하의"로 바꾼다.
    await tester.tap(find.widgetWithText(InkWell, Category.bottom.label));
    await tester.pumpAndSettle();
    expect(find.text('셀비지 데님'), findsOneWidget);
    expect(find.text('캐시미어 니트'), findsNothing);

    // 하단 탭으로 옷장에 돌아오면 사용자가 고른 칩 필터가 유지된다.
    await _tapTab(tester, BottomNavTab.home);
    await _tapTab(tester, BottomNavTab.wardrobe);
    expect(find.text('셀비지 데님'), findsOneWidget);
    expect(find.text('캐시미어 니트'), findsNothing);

    // 같은 상의 카드를 다시 탭하면 상의 필터로 돌아와야 한다.
    await _tapTab(tester, BottomNavTab.home);
    await _tapHomeCard(tester, Category.top);
    expect(find.text('캐시미어 니트'), findsOneWidget);
    expect(find.text('셀비지 데님'), findsNothing);
  });

  testWidgets('홈 카드로 필터가 바뀌면 옷장 스크롤이 맨 위로 돌아간다', (tester) async {
    final many = [
      for (var i = 0; i < 12; i++) _item(10 + i, '하의 $i', Category.bottom),
      _item(99, '캐시미어 니트', Category.top),
    ];
    await tester.pumpWidget(_harness(many));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(_wardrobeScroll(tester).pixels, greaterThan(0));

    await _tapTab(tester, BottomNavTab.home);
    await _tapHomeCard(tester, Category.top);

    expect(_wardrobeScroll(tester).pixels, 0);
    expect(find.text('캐시미어 니트'), findsOneWidget);
  });

  testWidgets('옷장 칩 필터 상태에서 상세 진입 후 삭제하면 필터가 유지된 옷장으로 돌아온다', (tester) async {
    final repo = _FakeItemRepository([
      ...items,
      _item(4, '와이드 슬랙스', Category.bottom),
    ]);
    await tester.pumpWidget(_harness(const [], repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, Category.bottom.label));
    await tester.pumpAndSettle();
    expect(find.text('캐시미어 니트'), findsNothing);

    await tester.ensureVisible(find.text('셀비지 데님'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('셀비지 데님'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(repo.deleted, [2]);
    // FR-012 옷장 복귀 + 하의 칩 필터 유지(전체로 초기화되지 않음).
    expect(find.text('와이드 슬랙스'), findsOneWidget);
    expect(find.text('캐시미어 니트'), findsNothing);
    expect(find.text('오버사이즈 코트'), findsNothing);

    // 토스트 타이머 소진.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
