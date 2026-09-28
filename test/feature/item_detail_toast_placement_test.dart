// #22 회귀 — 옷 상세에서 "세탁 바구니"를 누른 뒤 뜨는 토스트가 방금 누른 버튼을
// 가리지 않아야 한다. 하단 고정(bottom: 100) 토스트는 기기 높이·스크롤에 따라
// 버튼이 화면 하단 띠에 올 때 버튼을 덮었다. 스크롤 없이도 버튼이 그 띠에 오는
// 뷰포트(384×720dp)에서 겹침을 검증한다.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/widgets/soft_button.dart';
import 'package:closetimo/core/widgets/top_bar.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/item_detail/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeItemRepo implements ItemRepository {
  _FakeItemRepo(this.item);
  final Item item;

  @override
  Future<Item?> get(int id) async => id == item.id ? item : null;

  @override
  Future<int> create(_) async => throw UnimplementedError();
  @override
  Future<void> update(int id, ItemPatch patch) async =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) async => throw UnimplementedError();
  @override
  Stream<List<Item>> watchAll() => const Stream.empty();
  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) => const Stream.empty();
  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();
  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
}

class _FakeEventRepo implements EventRepository {
  _FakeEventRepo(this.events);
  final List<WearEvent> events;

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(events);
  @override
  Future<void> recordWear(int itemId, {String? note}) async {}
  @override
  Future<void> updateEventNote(int eventId, String? note) async {}
  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

class _FakeLaundryRepo implements LaundryRepository {
  _FakeLaundryRepo(this.item);
  final Item item;

  @override
  Stream<List<Item>> watchBasket() => const Stream.empty();
  @override
  Future<void> toggle(int itemId) async => item.inLaundry = !item.inLaundry;
  @override
  Future<void> completeWashFor(List<int> itemIds) async {}
}

Widget _harness(Item item, List<WearEvent> events) {
  final router = GoRouter(
    initialLocation: '/item/1',
    routes: [
      GoRoute(
        path: '/item/:id',
        builder: (ctx, st) =>
            ItemDetailScreen(id: int.parse(st.pathParameters['id']!)),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(_FakeItemRepo(item)),
      eventRepositoryProvider.overrideWithValue(_FakeEventRepo(events)),
      laundryRepositoryProvider.overrideWithValue(_FakeLaundryRepo(item)),
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

/// 상세 화면을 A23 뷰포트(384×856dp, 상태바 24dp·내비바 48dp)로 띄운다.
/// [historyCount]만큼 착용 기록을 두면 버튼을 화면 위쪽까지 스크롤할 수 있다.
Future<Item> _pumpDetail(WidgetTester tester, {int historyCount = 0}) async {
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.8125;
  tester.view.padding = const FakeViewPadding(top: 67.5, bottom: 135);
  addTearDown(tester.view.reset);

  final item = Item(
    name: '울 코트',
    category: Category.outer,
    washCycle: 5,
    createdAt: DateTime(2026, 1, 1),
  )..id = 1;
  final events = [
    for (var i = 0; i < historyCount; i++)
      WearEvent(
        itemId: 1,
        kind: EventKind.wear,
        occurredAt: DateTime(2026, 5, 20 - i),
      )..id = i + 1,
  ];
  await tester.pumpWidget(_harness(item, events));
  await tester.pumpAndSettle();
  return item;
}

/// 버튼을 눌러 토스트를 띄우고, 토스트가 버튼·상단바를 가리지 않는지 검증한다.
Future<void> _tapAndExpectToastClear(WidgetTester tester, Finder button) async {
  // 누른 뒤 라벨이 "바구니에서 제외"로 바뀌므로 위치를 미리 잡아 둔다.
  final buttonRect = tester.getRect(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300)); // 등장 애니메이션 완료

  final toast = find.ancestor(
    of: find.text('세탁 바구니에 담겼어요'),
    matching: find.byType(Container),
  );
  expect(toast, findsWidgets);
  final toastRect = tester.getRect(toast.first);
  final topBarRect = tester.getRect(find.byType(TopBar));
  expect(
    toastRect.overlaps(buttonRect),
    isFalse,
    reason: 'toast $toastRect must not cover the tapped button $buttonRect',
  );
  expect(
    toastRect.top,
    greaterThanOrEqualTo(topBarRect.bottom),
    reason: 'toast $toastRect must not cover the top bar $topBarRect',
  );

  // 2초 후 자동 dismiss까지 흘려보낸다(타이머 누수 방지).
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

final _laundryButton = find.widgetWithText(SoftButton, '세탁 바구니');

void main() {
  testWidgets('#22: 버튼이 화면 하단 띠(QA 관찰 위치)에 있을 때 토스트가 가리지 않는다', (tester) async {
    await _pumpDetail(tester);
    // QA(F-12)에서 겹친 위치: 버튼 중심이 화면 하단(내비바 위)에서 약 120dp.
    const safeBottom = 856.0 - 48;
    final dy = tester.getCenter(_laundryButton).dy - (safeBottom - 120);
    await tester.drag(find.byType(SingleChildScrollView), Offset(0, -dy));
    await tester.pumpAndSettle();
    expect(tester.getCenter(_laundryButton).dy, closeTo(safeBottom - 120, 1));

    await _tapAndExpectToastClear(tester, _laundryButton);
  });

  testWidgets('#22: 버튼을 상단바 바로 아래로 스크롤해 토스트가 겹쳐도 버튼을 다시 누를 수 있다', (
    tester,
  ) async {
    final item = await _pumpDetail(tester, historyCount: 12);
    // 버튼 윗변을 상단바 바로 아래로 올린다 → 상단 토스트 띠와 겹친다.
    final topBarBottom = tester.getRect(find.byType(TopBar)).bottom;
    final dy = tester.getRect(_laundryButton).top - (topBarBottom + 2);
    await tester.drag(find.byType(SingleChildScrollView), Offset(0, -dy));
    await tester.pumpAndSettle();
    final buttonCenter = tester.getCenter(_laundryButton);

    await tester.tap(_laundryButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 토스트 표시 중
    expect(item.inLaundry, isTrue);
    final toastRect = tester.getRect(
      find
          .ancestor(
            of: find.text('세탁 바구니에 담겼어요'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      toastRect.contains(buttonCenter),
      isTrue,
      reason: 'precondition: toast $toastRect covers button $buttonCenter',
    );

    // 토스트는 비차단이어야 한다 — 덮인 버튼을 다시 누르면 토글된다.
    await tester.tapAt(buttonCenter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(item.inLaundry, isFalse);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
