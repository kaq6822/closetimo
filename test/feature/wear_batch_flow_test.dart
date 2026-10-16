// #39 — 여러 벌 착용 기록·날짜 선택·실행 취소·날짜 수정 흐름 위젯 테스트
// (spec FR-008c·FR-010·FR-010c·FR-010e).

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/item_detail/item_detail_screen.dart';
import 'package:closetimo/features/wardrobe/selection/selection_action_bar.dart';
import 'package:closetimo/features/wardrobe/wardrobe_screen.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _now = DateTime(2026, 10, 16, 9);

class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

class _BatchCall {
  _BatchCall(this.ids, this.wornOn, this.note);
  final List<int> ids;
  final DateTime? wornOn;
  final String? note;
}

class _RecordingEventRepo implements EventRepository {
  _RecordingEventRepo({this.timeline = const []});

  final List<WearEvent> timeline;
  final List<_BatchCall> batches = [];
  final List<_BatchCall> singles = [];
  final List<List<int>> undone = [];
  final List<(int, DateTime)> dateEdits = [];
  int skipped = 0;
  bool fail = false;

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(timeline);

  @override
  Future<int?> recordWear(int itemId, {String? note, DateTime? wornOn}) async {
    singles.add(_BatchCall([itemId], wornOn, note));
    return 55;
  }

  @override
  Future<WearBatchResult> recordWearBatch(
    Iterable<int> itemIds, {
    DateTime? wornOn,
    String? note,
  }) async {
    if (fail) throw StateError('disk full');
    final ids = itemIds.toList();
    batches.add(_BatchCall(ids, wornOn, note));
    return WearBatchResult(
      eventIds: [for (var i = 0; i < ids.length - skipped; i++) 100 + i],
      skipped: skipped,
    );
  }

  @override
  Future<void> updateWearDate(int eventId, DateTime wornOn) async =>
      dateEdits.add((eventId, wornOn));

  @override
  Future<void> deleteWearEvents(Iterable<int> eventIds) async =>
      undone.add(eventIds.toList());

  @override
  Future<void> updateEventNote(int eventId, String? note) async {}
  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

class _FakeItemRepo implements ItemRepository {
  _FakeItemRepo(this.items);
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
  Future<Item?> get(int id) async {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<int> create(_) async => 0;
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

class _FakeLaundryRepo implements LaundryRepository {
  @override
  Future<void> toggle(int itemId) async {}
  @override
  Stream<List<Item>> watchBasket() => const Stream.empty();
  @override
  Future<int> completeWashFor(List<int> itemIds) async => 0;
}

Item _item(int id, String name) => Item(
  name: name,
  category: Category.top,
  washCycle: 5,
  createdAt: DateTime(2026, 10, id),
)..id = id;

final _items = [_item(1, '옥스퍼드 셔츠'), _item(2, '데님 팬츠'), _item(3, '울 가디건')];

Widget _app(String initial, _RecordingEventRepo events) {
  final router = GoRouter(
    initialLocation: initial,
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
            ItemDetailScreen(id: int.parse(st.pathParameters['id']!)),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(_FakeItemRepo(_items)),
      eventRepositoryProvider.overrideWithValue(events),
      laundryRepositoryProvider.overrideWithValue(_FakeLaundryRepo()),
      imageStoreProvider.overrideWithValue(ImageStore()),
      clockProvider.overrideWithValue(_FixedClock()),
    ],
    child: MaterialApp.router(
      theme: buildClosetimoTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      locale: const Locale('ko', 'KR'),
      routerConfig: router,
    ),
  );
}

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.8125;
  addTearDown(tester.view.reset);
}

Finder _tile(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(GarmentTile));

/// 셔츠·팬츠를 선택하고 선택 바의 "착용 기록"을 눌러 시트를 연다.
Future<void> _selectTwoAndOpenSheet(WidgetTester tester) async {
  await tester.longPress(_tile('옥스퍼드 셔츠'));
  await tester.pumpAndSettle();
  await tester.tap(_tile('데님 팬츠'));
  await tester.pumpAndSettle();
  expect(find.text('2개 선택'), findsOneWidget);
  await tester.tap(find.text('착용 기록'));
  await tester.pumpAndSettle();
}

Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FR-008c: 선택한 옷을 어제 날짜·메모로 일괄 기록하고 실행 취소한다', (tester) async {
    _phoneViewport(tester);
    final events = _RecordingEventRepo();
    await tester.pumpWidget(_app('/wardrobe', events));
    await tester.pumpAndSettle();

    await _selectTwoAndOpenSheet(tester);
    expect(find.text('오늘의 착용'), findsOneWidget);
    expect(find.textContaining('선택한 2벌을 같은 날짜로'), findsOneWidget);
    expect(find.text('2벌 기록'), findsOneWidget);

    await tester.tap(find.text('어제'));
    await tester.pumpAndSettle();
    expect(find.text('어제의 착용'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      '  등산  ',
    );
    await tester.tap(find.text('2벌 기록'));
    await tester.pumpAndSettle();

    expect(events.batches, hasLength(1));
    expect(events.batches.single.ids, unorderedEquals([1, 2]));
    expect(events.batches.single.wornOn, DateTime(2026, 10, 15));
    expect(events.batches.single.note, '등산');
    expect(find.byType(SelectionActionBar), findsNothing);
    expect(find.text('어제의 착용을 2벌 기록했어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '실행 취소'));
    await tester.pumpAndSettle();
    expect(events.undone, [
      [100, 101],
    ]);
    expect(find.text('착용 기록을 취소했어요'), findsOneWidget);
    await _drainToast(tester);
  });

  testWidgets('FR-008c: 제외된 옷 수를 함께 알린다', (tester) async {
    _phoneViewport(tester);
    final events = _RecordingEventRepo()..skipped = 1;
    await tester.pumpWidget(_app('/wardrobe', events));
    await tester.pumpAndSettle();

    await _selectTwoAndOpenSheet(tester);
    await tester.tap(find.text('2벌 기록'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 착용을 1벌 기록했어요 (1벌 제외)'), findsOneWidget);
    await _drainToast(tester);
  });

  testWidgets('FR-008c: 저장에 실패하면 오류를 알리고 선택을 유지한다', (tester) async {
    _phoneViewport(tester);
    final events = _RecordingEventRepo()..fail = true;
    await tester.pumpWidget(_app('/wardrobe', events));
    await tester.pumpAndSettle();

    await _selectTwoAndOpenSheet(tester);
    await tester.tap(find.text('2벌 기록'));
    await tester.pumpAndSettle();
    expect(find.text('착용을 기록하지 못했어요. 선택은 그대로 두었어요.'), findsOneWidget);
    expect(find.text('2개 선택'), findsOneWidget);
    await _drainToast(tester);
  });

  testWidgets('FR-008c: 시트를 닫으면 아무것도 기록하지 않는다', (tester) async {
    _phoneViewport(tester);
    final events = _RecordingEventRepo();
    await tester.pumpWidget(_app('/wardrobe', events));
    await tester.pumpAndSettle();

    await _selectTwoAndOpenSheet(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(events.batches, isEmpty);
    expect(find.text('2개 선택'), findsOneWidget);
  });

  testWidgets('FR-010: 상세 한 벌 기록도 날짜 선택(달력)과 실행 취소를 지원한다', (tester) async {
    _phoneViewport(tester);
    final events = _RecordingEventRepo();
    await tester.pumpWidget(_app('/item/1', events));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('착용 기록하기'));
    await tester.tap(find.text('착용 기록하기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 착용'), findsOneWidget);

    await tester.tap(find.text('날짜 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('10/12의 착용'), findsOneWidget);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(events.singles.single.ids, [1]);
    expect(events.singles.single.wornOn, DateTime(2026, 10, 12));
    expect(find.text('10/12의 착용이 기록되었어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '실행 취소'));
    await tester.pumpAndSettle();
    expect(events.undone, [
      [55],
    ]);
    await _drainToast(tester);
  });

  testWidgets('FR-010c: 타임라인 "기록 관리" 버튼으로 날짜를 수정한다', (tester) async {
    _phoneViewport(tester);
    final events = _RecordingEventRepo(
      timeline: [
        WearEvent(itemId: 1, kind: EventKind.wear, occurredAt: _now)..id = 7,
        WearEvent(
          itemId: 1,
          kind: EventKind.wash,
          occurredAt: DateTime(2026, 10, 10),
        )..id = 6,
      ],
    );
    await tester.pumpWidget(_app('/item/1', events));
    await tester.pumpAndSettle();

    // wash 이벤트에는 관리 버튼이 없다.
    expect(find.byTooltip('기록 관리'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('기록 관리'));
    await tester.tap(find.byTooltip('기록 관리'));
    await tester.pumpAndSettle();
    expect(find.text('메모 편집'), findsOneWidget);
    expect(find.text('기록 삭제'), findsOneWidget);

    await tester.tap(find.text('날짜 수정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(events.dateEdits.single.$1, 7);
    expect(events.dateEdits.single.$2, DateTime(2026, 10, 14));
    expect(find.text('착용 날짜를 10/14로 바꿨어요'), findsOneWidget);
    await _drainToast(tester);
  });
}
