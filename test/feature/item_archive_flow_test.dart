// #44 — 보관/복원 UI 플로우. 상세 메뉴의 보관(기록 유지)과 삭제(기록까지 제거)를
// 사용자가 구분하는지, 보관함에서 확인·복원되는지, 설정에서 보관함으로 진입하는지 검증한다.

import 'dart:async';

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/archive_repository.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/preferences_repository.dart';
import 'package:closetimo/features/archive/archive_screen.dart';
import 'package:closetimo/features/item_detail/item_detail_screen.dart';
import 'package:closetimo/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _now = DateTime(2026, 10, 16, 9);

class _FakeItemRepo implements ItemRepository {
  _FakeItemRepo(this.items);
  final Map<int, Item> items;
  final List<int> deleted = [];

  @override
  Future<Item?> get(int id) async => items[id];
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
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  }) => const Stream.empty();
  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();
  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
}

/// 메모리 상의 옷을 직접 바꾸는 보관 repository 대역.
class _FakeArchiveRepo implements ArchiveRepository {
  _FakeArchiveRepo(this.items);
  final Map<int, Item> items;
  final List<(int, ArchiveReason)> archived = [];
  final List<int> restored = [];
  final _changes = StreamController<void>.broadcast();

  List<Item> _snapshot() =>
      items.values.where((i) => i.isArchived).toList()
        ..sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));

  @override
  Stream<List<Item>> watchArchived() async* {
    yield _snapshot();
    await for (final _ in _changes.stream) {
      yield _snapshot();
    }
  }

  @override
  Future<void> archive(
    int itemId, {
    ArchiveReason reason = ArchiveReason.unspecified,
  }) async {
    archived.add((itemId, reason));
    items[itemId]!
      ..archivedAt = _now
      ..archiveReason = reason
      ..inLaundry = false;
    _changes.add(null);
  }

  @override
  Future<void> restore(int itemId) async {
    restored.add(itemId);
    items[itemId]!
      ..archivedAt = null
      ..archiveReason = ArchiveReason.unspecified;
    _changes.add(null);
  }
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

class _FakePrefsRepo implements PreferencesRepository {
  @override
  Stream<UserPreferences> watch() =>
      Stream.value(UserPreferences.defaults()..firstLaunchedAt = _now);
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

Item _coat({DateTime? archivedAt, ArchiveReason? reason}) => Item(
  name: '울 코트',
  category: Category.outer,
  washCycle: 5,
  totalWears: 7,
  inLaundry: archivedAt == null,
  createdAt: DateTime(2026, 1, 1),
  archivedAt: archivedAt,
  archiveReason: reason ?? ArchiveReason.unspecified,
)..id = 1;

Widget _harness({
  required String initialLocation,
  required _FakeItemRepo itemRepo,
  required _FakeArchiveRepo archiveRepo,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/wardrobe',
        name: Routes.wardrobe,
        builder: (ctx, st) =>
            const Scaffold(body: Center(child: Text('WARDROBE'))),
      ),
      GoRoute(
        path: '/settings',
        name: Routes.settings,
        builder: (ctx, st) => const Scaffold(body: SettingsScreen()),
      ),
      GoRoute(
        path: '/archive',
        name: Routes.archive,
        builder: (ctx, st) => const ArchiveScreen(),
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
      itemRepositoryProvider.overrideWithValue(itemRepo),
      archiveRepositoryProvider.overrideWithValue(archiveRepo),
      eventRepositoryProvider.overrideWithValue(_FakeEventRepo()),
      preferencesRepositoryProvider.overrideWithValue(_FakePrefsRepo()),
      clockProvider.overrideWithValue(_FixedClock()),
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

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz_rounded));
  await tester.pumpAndSettle();
}

Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('상세 메뉴는 보관과 삭제를 나란히 보여주고, 보관하면 사유와 함께 기록이 남는다고 안내한다', (
    tester,
  ) async {
    final items = {1: _coat()};
    final archiveRepo = _FakeArchiveRepo(items);
    await tester.pumpWidget(
      _harness(
        initialLocation: '/item/1',
        itemRepo: _FakeItemRepo(items),
        archiveRepo: archiveRepo,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('착용 기록하기'), findsOneWidget);

    await _openMenu(tester);
    expect(find.text('보관하기'), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);
    await tester.tap(find.text('보관하기'));
    await tester.pumpAndSettle();

    expect(find.text('이 옷을 보관할까요?'), findsOneWidget);
    expect(find.textContaining('착용·세탁 기록은 그대로 남아요'), findsOneWidget);
    await tester.tap(find.text('계절 보관'));
    await tester.pump();
    await tester.tap(find.text('보관'));
    await tester.pumpAndSettle();

    expect(archiveRepo.archived, [(1, ArchiveReason.seasonal)]);
    // 보관한 옷의 상세: 착용 기록·바구니 대신 보관 안내와 복원 버튼.
    expect(find.text('보관 중 · 계절 보관 · 2026.10.16 보관'), findsOneWidget);
    expect(find.text('착용 기록하기'), findsNothing);
    expect(find.text('세탁 바구니'), findsNothing);
    expect(find.text('보관함으로 옮겼어요. 기록은 그대로 남아요'), findsOneWidget);
    await _drainToast(tester);

    // 복원 버튼으로 되돌린다.
    final restoreButton = find.widgetWithText(InkWell, '옷장으로 꺼내기');
    await tester.ensureVisible(restoreButton);
    await tester.pumpAndSettle();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    expect(archiveRepo.restored, [1]);
    expect(find.text('착용 기록하기'), findsOneWidget);
    await _drainToast(tester);
  });

  testWidgets('보관 다이얼로그를 취소하면 아무것도 바뀌지 않고, 사유 없이도 보관할 수 있다', (tester) async {
    final items = {1: _coat()};
    final archiveRepo = _FakeArchiveRepo(items);
    await tester.pumpWidget(
      _harness(
        initialLocation: '/item/1',
        itemRepo: _FakeItemRepo(items),
        archiveRepo: archiveRepo,
      ),
    );
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.text('보관하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(archiveRepo.archived, isEmpty);

    await _openMenu(tester);
    await tester.tap(find.text('보관하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보관'));
    await tester.pumpAndSettle();
    expect(archiveRepo.archived, [(1, ArchiveReason.unspecified)]);
    expect(find.text('보관 중 · 2026.10.16 보관'), findsOneWidget);
    await _drainToast(tester);
  });

  testWidgets('삭제 다이얼로그는 기록까지 지워짐을 명시하고 보관을 안내한다', (tester) async {
    final items = {1: _coat()};
    final itemRepo = _FakeItemRepo(items);
    final archiveRepo = _FakeArchiveRepo(items);
    await tester.pumpWidget(
      _harness(
        initialLocation: '/item/1',
        itemRepo: itemRepo,
        archiveRepo: archiveRepo,
      ),
    );
    await tester.pumpAndSettle();

    await _openMenu(tester);
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();

    expect(find.text('이 옷을 삭제할까요?'), findsOneWidget);
    expect(find.textContaining('착용·세탁 기록까지 모두 지워지고'), findsOneWidget);
    expect(find.textContaining('보관하기'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(itemRepo.deleted, isEmpty);
    expect(archiveRepo.archived, isEmpty);
  });

  testWidgets('보관한 옷의 상세 메뉴는 보관하기 대신 옷장으로 꺼내기를 보여준다', (tester) async {
    final items = {
      1: _coat(archivedAt: _now, reason: ArchiveReason.noLongerOwned),
    };
    final archiveRepo = _FakeArchiveRepo(items);
    await tester.pumpWidget(
      _harness(
        initialLocation: '/item/1',
        itemRepo: _FakeItemRepo(items),
        archiveRepo: archiveRepo,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('보관 중 · 더 이상 갖고 있지 않음 · 2026.10.16 보관'), findsOneWidget);

    await _openMenu(tester);
    expect(find.text('보관하기'), findsNothing);
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, '옷장으로 꺼내기'));
    await tester.pumpAndSettle();
    expect(archiveRepo.restored, [1]);
    await _drainToast(tester);
  });

  testWidgets('설정 > 보관함에서 보관한 옷을 확인하고 꺼내면 목록에서 빠진다', (tester) async {
    final items = {1: _coat(archivedAt: _now, reason: ArchiveReason.seasonal)};
    final archiveRepo = _FakeArchiveRepo(items);
    await tester.pumpWidget(
      _harness(
        initialLocation: '/settings',
        itemRepo: _FakeItemRepo(items),
        archiveRepo: archiveRepo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('보관함'), 200);
    await tester.tap(find.text('보관함'));
    await tester.pumpAndSettle();

    expect(find.byType(ArchiveScreen), findsOneWidget);
    expect(find.text('울 코트'), findsOneWidget);
    expect(
      find.textContaining('계절 보관 · 2026.10.16 보관 · 총 착용 7회'),
      findsOneWidget,
    );

    await tester.tap(find.text('꺼내기'));
    await tester.pumpAndSettle();
    expect(archiveRepo.restored, [1]);
    expect(find.text('보관한 옷이 없어요'), findsOneWidget);
    await _drainToast(tester);
  });
}
