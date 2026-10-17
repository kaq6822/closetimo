// #21·#43 — 옷장 헤더 압축, 검색 지우기, '입을 수 있음' 필터, 타일 빠른 동작,
// 다중 선택 바 위젯 테스트(spec FR-005a·006a·006b·008a·008b).

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/wardrobe/selection/selection_action_bar.dart';
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
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  }) => Stream.value([
    for (final i in items)
      if (filter.matches(i)) i,
  ]);

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

class _FakeEventRepository implements EventRepository {
  final List<int> worn = [];

  @override
  Future<int?> recordWear(int itemId, {String? note, DateTime? wornOn}) async {
    expect(note, isNull);
    worn.add(itemId);
    return worn.length;
  }

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => const Stream.empty();
  @override
  Future<void> updateEventNote(int eventId, String? note) async {}
  @override
  Future<void> deleteWearEvent(int eventId) async {}

  @override
  Future<WearBatchResult> recordWearBatch(
    Iterable<int> itemIds, {
    DateTime? wornOn,
    String? note,
  }) async => const WearBatchResult(eventIds: [], skipped: 0);
  @override
  Future<void> updateWearDate(int eventId, DateTime wornOn) async {}
  @override
  Future<void> deleteWearEvents(Iterable<int> eventIds) async {}
}

class _FakeLaundryRepository implements LaundryRepository {
  final List<int> toggled = [];

  @override
  Future<void> toggle(int itemId) async => toggled.add(itemId);
  @override
  Stream<List<Item>> watchBasket() => const Stream.empty();
  @override
  Future<int> completeWashFor(List<int> itemIds) async => 0;
}

Item _item(
  int id,
  String name, {
  ItemStatus status = ItemStatus.clean,
  bool inLaundry = false,
}) => Item(
  name: name,
  category: Category.top,
  washCycle: 5,
  createdAt: DateTime(2026, 10, id),
  status: status,
  inLaundry: inLaundry,
)..id = id;

final _items = [
  _item(1, '옥스퍼드 셔츠'),
  _item(2, '캐시미어 니트', status: ItemStatus.dirty),
  _item(3, '린넨 셔츠', inLaundry: true),
  _item(4, '울 가디건'),
];

class _Harness {
  final events = _FakeEventRepository();
  final laundry = _FakeLaundryRepository();

  Widget build(List<Item> items) {
    final router = GoRouter(
      initialLocation: '/wardrobe',
      routes: [
        GoRoute(
          path: '/wardrobe',
          name: Routes.wardrobe,
          builder: (ctx, st) => Scaffold(
            body: WardrobeScreen(
              initialFilter: wardrobeFilterFromQuery(st.uri.queryParameters),
            ),
          ),
        ),
        GoRoute(
          path: '/item/:id',
          name: Routes.itemDetail,
          builder: (ctx, st) =>
              const Scaffold(body: Center(child: Text('DETAIL'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(_FakeItemRepository(items)),
        eventRepositoryProvider.overrideWithValue(events),
        laundryRepositoryProvider.overrideWithValue(laundry),
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
}

/// QA 기기(Galaxy A23, 1080×2408)와 같은 384×856dp 뷰포트.
void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.8125;
  addTearDown(tester.view.reset);
}

int _gridCount(WidgetTester tester) {
  final delegate =
      tester.widget<SliverGrid>(find.byType(SliverGrid)).delegate
          as SliverChildBuilderDelegate;
  return delegate.childCount!;
}

Finder _tile(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(GarmentTile));

Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('#21: 휴대폰 첫 화면에 첫 줄 타일이 하단 탭 위로 온전히 보인다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_Harness().build(_items));
    await tester.pumpAndSettle();

    // 하단 탭(약 80dp)을 제외한 영역 안에 첫 타일이 들어와야 한다.
    final first = tester.getRect(find.byType(GarmentTile).first);
    expect(first.bottom, lessThanOrEqualTo(856 - 80));
    // 종류 칩은 여러 줄 Wrap이 아니라 한 줄 가로 스크롤이다.
    expect(
      find.ancestor(
        of: find.text(Category.outer.label),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('#21: 검색어가 있으면 지우기 버튼이 보이고 누르면 검색이 해제된다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_Harness().build(_items));
    await tester.pumpAndSettle();
    expect(find.byTooltip('검색어 지우기'), findsNothing);

    await tester.enterText(find.byType(TextField), '가디건');
    await tester.pumpAndSettle();
    expect(_gridCount(tester), 1);

    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.byTooltip('검색어 지우기'), findsNothing);
    expect(_gridCount(tester), 4);
  });

  testWidgets('#43: 입을 수 있음은 관리 권장·바구니 옷을 빼고 상태 기준 안내를 보인다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_Harness().build(_items));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, '입을 수 있음'));
    await tester.pumpAndSettle();

    expect(_gridCount(tester), 2);
    expect(find.text('옥스퍼드 셔츠'), findsOneWidget);
    expect(find.text('울 가디건'), findsOneWidget);
    expect(find.text('캐시미어 니트'), findsNothing);
    expect(find.text('린넨 셔츠'), findsNothing);
    // 실제 오염 감지를 암시하지 않는 안내.
    expect(find.textContaining('기록된 상태 기준'), findsOneWidget);
    expect(
      tester.getSemantics(find.widgetWithText(InkWell, '입을 수 있음')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );

    await tester.tap(find.widgetWithText(InkWell, '입을 수 있음'));
    await tester.pumpAndSettle();
    expect(_gridCount(tester), 4);
    expect(find.textContaining('기록된 상태 기준'), findsNothing);
  });

  testWidgets('#43: 빠른 동작 — 착용 기록은 메모 없이 즉시 기록한다', (tester) async {
    _phoneViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build(_items));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('옥스퍼드 셔츠 빠른 동작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('착용 기록'));
    await tester.pumpAndSettle();

    expect(h.events.worn, [1]);
    expect(find.text('오늘의 착용이 기록되었어요'), findsOneWidget);
    // 상세로 이동하지 않는다.
    expect(find.text('DETAIL'), findsNothing);
    await _drainToast(tester);
  });

  testWidgets('#43: 빠른 동작 — 바구니 담기/빼기 문구가 현재 상태를 따른다', (tester) async {
    _phoneViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build(_items));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('옥스퍼드 셔츠 빠른 동작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('세탁 바구니에 담기'));
    await tester.pumpAndSettle();
    expect(h.laundry.toggled, [1]);
    expect(find.text('세탁 바구니에 담겼어요'), findsOneWidget);
    await _drainToast(tester);

    await tester.ensureVisible(find.byTooltip('린넨 셔츠 빠른 동작'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('린넨 셔츠 빠른 동작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('세탁 바구니에서 빼기'));
    await tester.pumpAndSettle();
    expect(h.laundry.toggled, [1, 3]);
    expect(find.text('세탁 바구니에서 제외됐어요'), findsOneWidget);
    await _drainToast(tester);
  });

  testWidgets('#43: 길게 눌러 다중 선택 — 선택 수·필터 조건·초기화·모두 선택', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_Harness().build(_items));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionActionBar), findsNothing);

    await tester.longPress(_tile('옥스퍼드 셔츠'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionActionBar), findsOneWidget);
    expect(find.text('1개 선택'), findsOneWidget);
    expect(find.text('필터: 전체'), findsOneWidget);
    // 선택 모드에서는 빠른 동작 대신 선택 표시가 보인다.
    expect(find.byTooltip('옥스퍼드 셔츠 빠른 동작'), findsNothing);

    // 선택 모드의 탭은 상세 이동이 아니라 선택 토글이다.
    await tester.tap(_tile('캐시미어 니트'));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsNothing);
    expect(find.text('2개 선택'), findsOneWidget);

    await tester.tap(find.text('선택 초기화'));
    await tester.pumpAndSettle();
    expect(find.text('0개 선택'), findsOneWidget);

    await tester.tap(find.text('모두 선택'));
    await tester.pumpAndSettle();
    expect(find.text('4개 선택'), findsOneWidget);

    await tester.tap(find.byTooltip('선택 종료'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectionActionBar), findsNothing);
  });

  testWidgets('#43: 필터를 바꾸면 조건 요약이 갱신되고 숨은 옷은 선택에서 빠진다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_Harness().build(_items));
    await tester.pumpAndSettle();

    await tester.longPress(_tile('옥스퍼드 셔츠'));
    await tester.pumpAndSettle();
    await tester.tap(_tile('캐시미어 니트'));
    await tester.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, '입을 수 있음'));
    await tester.pumpAndSettle();
    expect(find.text('필터: 입을 수 있음'), findsOneWidget);
    // dirty인 캐시미어 니트는 목록에서 사라져 선택에서도 빠진다.
    expect(find.text('1개 선택'), findsOneWidget);
  });

  testWidgets('#43: 선택한 옷 중 바구니에 없는 옷만 담고 선택을 끝낸다', (tester) async {
    _phoneViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build(_items));
    await tester.pumpAndSettle();

    await tester.longPress(_tile('옥스퍼드 셔츠'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('바구니에 담기'));
    await tester.pumpAndSettle();

    // 이미 바구니에 있는 린넨 셔츠(3)는 토글하지 않는다.
    expect(h.laundry.toggled, unorderedEquals([1, 2, 4]));
    expect(find.text('3점을 세탁 바구니에 담았어요'), findsOneWidget);
    expect(find.byType(SelectionActionBar), findsNothing);
    await _drainToast(tester);
  });

  testWidgets('#43: 선택 모드에서 시스템 뒤로 가기는 선택만 끝낸다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(_Harness().build(_items));
    await tester.pumpAndSettle();

    await tester.longPress(_tile('옥스퍼드 셔츠'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(SelectionActionBar), findsNothing);
    expect(find.byType(GarmentTile), findsWidgets);
  });

  testWidgets('#43: 선택이 0개면 선택 대상 액션은 비활성이다', (tester) async {
    _phoneViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build(_items));
    await tester.pumpAndSettle();

    await tester.longPress(_tile('옥스퍼드 셔츠'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택 초기화'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('바구니에 담기'));
    await tester.pumpAndSettle();
    expect(h.laundry.toggled, isEmpty);
    expect(find.byType(SelectionActionBar), findsOneWidget);
  });
}
