// #36 — 바구니에서 제외된 옷은 선택·세탁 완료 대상에서 빠진다.
// #38 — 세탁 전 착용 기록 삭제는 현재 세탁 주기 횟수를 줄이지 않는다.

import 'dart:async';
import 'dart:io';

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/isar_archive_repository.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/laundry/laundry_screen.dart';
import 'package:closetimo/features/laundry/laundry_selection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

import '../support/isar_plus_test_support.dart';

class _MutableClock implements Clock {
  _MutableClock(this.value);
  DateTime value;

  @override
  DateTime now() => value;
}

class _FakeLaundryRepo implements LaundryRepository {
  _FakeLaundryRepo(this._basket);

  final StreamController<List<Item>> _ctl = StreamController.broadcast();
  List<Item> _basket;
  final List<List<int>> completed = [];

  void emit(List<Item> basket) {
    _basket = basket;
    _ctl.add(basket);
  }

  @override
  Stream<List<Item>> watchBasket() async* {
    yield _basket;
    yield* _ctl.stream;
  }

  @override
  Future<void> toggle(int itemId) async {}

  @override
  Future<int> completeWashFor(List<int> itemIds) async {
    completed.add(itemIds);
    return itemIds.length;
  }
}

Item _item(int id) => Item(
  name: '옷$id',
  category: Category.top,
  washCycle: 3,
  createdAt: DateTime(2026, 1, id),
)..id = id;

void main() {
  setUpAll(initializeIsarPlusForTests);

  group('#36 선택 상태 동기화', () {
    testWidgets('바구니에서 제외된 항목은 선택에서 빠진다', (tester) async {
      final repo = _FakeLaundryRepo([_item(1), _item(2)]);
      final container = ProviderContainer(
        overrides: [laundryRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildClosetimoTheme(),
            home: const Scaffold(body: LaundryScreen()),
          ),
        ),
      );
      await tester.pump();

      container.read(laundrySelectionProvider.notifier).selectAll([1, 2]);
      await tester.pump();

      // 옷 2가 외부에서 바구니 제외됨.
      repo.emit([_item(1)]);
      await tester.pump();
      await tester.pump();
      expect(container.read(laundrySelectionProvider), {1});

      // 모두 제외되면 선택이 비어 완료 대상이 없다.
      repo.emit([]);
      await tester.pump();
      await tester.pump();
      expect(container.read(laundrySelectionProvider), isEmpty);
      expect(repo.completed, isEmpty);
    });
  });

  group('Isar repository', () {
    late Directory directory;
    late Isar isar;
    final t0 = DateTime.utc(2026, 7, 1, 9);

    setUp(() {
      directory = Directory.systemTemp.createTempSync('closetimo_sync_test');
      isar = Isar.open(
        schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
        directory: directory.path,
        name: 'laundry_sync',
        inspector: false,
      );
    });

    tearDown(() {
      if (isar.isOpen) isar.close(deleteFromDisk: true);
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    // Isar Plus는 인덱스 조건 쿼리 watch가 "조건 밖으로 나가는" 수정을 방출하지 않는다.
    // 실기기에서 세탁 완료 후에도 바구니에 옷이 남던 문제의 원인이다.
    Future<List<int>> collect(
      Stream<List<Item>> stream,
      Future<void> Function() act,
    ) async {
      final lengths = <int>[];
      final sub = stream.listen((l) => lengths.add(l.length));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await act();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
      return lengths;
    }

    test('#52 마지막 세탁은 id가 아니라 시각이 가장 늦은 wash 기준이다', () async {
      isar.write((isar) {
        isar.items.put(_item(1));
        // id는 작지만 시각이 더 늦은 wash(06-25)가 마지막 세탁이다.
        isar.wearEvents.put(
          WearEvent(
            itemId: 1,
            kind: EventKind.wash,
            occurredAt: DateTime(2026, 6, 20),
          )..id = 9,
        );
        isar.wearEvents.put(
          WearEvent(
            itemId: 1,
            kind: EventKind.wash,
            occurredAt: DateTime(2026, 6, 25),
          )..id = 2,
        );
      });
      final events = IsarEventRepository(isar: isar, clock: _MutableClock(t0));

      await events.recordWear(1, wornOn: DateTime(2026, 6, 22));

      // 06-22 착용은 마지막 세탁(06-25) 이전이라 현재 주기에 들어가지 않는다.
      expect(isar.items.get(1)!.wearSinceWash, 0);
      expect(isar.items.get(1)!.totalWears, 1);
    });

    test('#48 세탁 완료로 바구니에서 나가면 watchBasket이 빈 목록을 방출한다', () async {
      isar.write((isar) => isar.items.put(_item(1)..inLaundry = true));
      final repo = IsarLaundryRepository(isar: isar, clock: _MutableClock(t0));

      final lengths = await collect(
        repo.watchBasket(),
        () => repo.completeWashFor([1]),
      );

      expect(lengths.first, 1);
      expect(lengths.last, 0);
    });

    test('#48 보관한 옷은 바구니 목록에서 빠지고 복원하면 보관함에서 빠진다', () async {
      isar.write((isar) => isar.items.put(_item(1)..inLaundry = true));
      final laundry = IsarLaundryRepository(
        isar: isar,
        clock: _MutableClock(t0),
      );
      final archive = IsarArchiveRepository(
        isar: isar,
        clock: _MutableClock(t0),
      );

      final basket = await collect(
        laundry.watchBasket(),
        () => archive.archive(1, reason: ArchiveReason.seasonal),
      );
      expect(basket.last, 0);

      final archived = await collect(
        archive.watchArchived(),
        () => archive.restore(1),
      );
      expect(archived.first, 1);
      expect(archived.last, 0);
    });

    test('#48 보관하면 홈 최근 착용에서 빠진다', () async {
      isar.write((isar) {
        isar.items.put(_item(1)..lastWornAt = t0);
        isar.items.put(_item(2)..lastWornAt = t0.add(const Duration(days: 1)));
      });
      final items = IsarItemRepository(
        isar: isar,
        clock: _MutableClock(t0),
        imageStore: ImageStore(overrideRoot: directory),
      );
      final archive = IsarArchiveRepository(
        isar: isar,
        clock: _MutableClock(t0),
      );

      final recent = <List<int>>[];
      final sub = items.watchRecentlyWorn().listen(
        (l) => recent.add([for (final i in l) i.id]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(recent.first, [2, 1]);
      await archive.archive(2, reason: ArchiveReason.seasonal);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await sub.cancel();

      expect(recent.last, [1]);
    });

    test('#36 completeWashFor는 바구니 밖 항목을 처리하지 않고 처리 수를 반환한다', () async {
      isar.write((isar) {
        isar.items.put(_item(1)..inLaundry = true);
        isar.items.put(_item(2)..inLaundry = false);
      });
      final repo = IsarLaundryRepository(isar: isar, clock: _MutableClock(t0));

      final done = await repo.completeWashFor([1, 2, 99]);

      expect(done, 1);
      expect(isar.items.get(2)!.lastWashedAt, isNull);
      expect(isar.items.get(1)!.lastWashedAt, isNotNull);
      expect(isar.wearEvents.where().kindEqualTo(EventKind.wash).count(), 1);
      expect(await repo.completeWashFor([2]), 0);
    });

    test('#38 세탁 전 기록 삭제는 totalWears만 줄이고 현재 주기는 유지한다', () async {
      isar.write((isar) => isar.items.put(_item(1)));
      final clock = _MutableClock(t0);
      final events = IsarEventRepository(isar: isar, clock: clock);
      final laundry = IsarLaundryRepository(isar: isar, clock: clock);

      await events.recordWear(1); // 세탁 전
      clock.value = t0.add(const Duration(days: 1));
      await laundry.toggle(1);
      await laundry.completeWashFor([1]);
      for (var i = 0; i < 3; i++) {
        clock.value = t0.add(Duration(days: 2 + i));
        await events.recordWear(1);
      }
      expect(isar.items.get(1)!.status, ItemStatus.dirty);

      final before = isar.wearEvents
          .where()
          .itemIdEqualTo(1)
          .kindEqualTo(EventKind.wear)
          .findAll()
          .firstWhere((e) => e.occurredAt.isAtSameMomentAs(t0));
      await events.deleteWearEvent(before.id);

      final item = isar.items.get(1)!;
      expect(item.wearSinceWash, 3);
      expect(item.totalWears, 3);
      expect(item.status, ItemStatus.dirty);
    });

    test('#38 세탁 후 기록 삭제는 현재 주기도 줄이고, 같은 시각은 id 순서로 판정한다', () async {
      isar.write((isar) => isar.items.put(_item(1)));
      final clock = _MutableClock(t0);
      final events = IsarEventRepository(isar: isar, clock: clock);
      final laundry = IsarLaundryRepository(isar: isar, clock: clock);

      await events.recordWear(1); // 같은 시각, wash보다 먼저 저장 → 이전 주기
      await laundry.toggle(1);
      await laundry.completeWashFor([1]);
      await events.recordWear(1); // 같은 시각, wash 이후 저장 → 현재 주기
      final wears =
          isar.wearEvents
              .where()
              .itemIdEqualTo(1)
              .kindEqualTo(EventKind.wear)
              .findAll()
            ..sort((a, b) => a.id.compareTo(b.id));

      await events.deleteWearEvent(wears.last.id);
      expect(isar.items.get(1)!.wearSinceWash, 0);
      expect(isar.items.get(1)!.totalWears, 1);

      await events.deleteWearEvent(wears.first.id);
      expect(isar.items.get(1)!.wearSinceWash, 0);
      expect(isar.items.get(1)!.totalWears, 0);
    });

    test('#38 wash 이벤트가 없는 기존 카운터 데이터는 전부 현재 주기로 본다', () async {
      isar.write((isar) {
        isar.items.put(
          _item(1)
            ..wearSinceWash = 2
            ..totalWears = 2,
        );
        isar.wearEvents.put(
          WearEvent(itemId: 1, kind: EventKind.wear, occurredAt: t0)..id = 1,
        );
      });
      final events = IsarEventRepository(isar: isar, clock: _MutableClock(t0));

      await events.deleteWearEvent(1);

      expect(isar.items.get(1)!.wearSinceWash, 1);
      expect(isar.items.get(1)!.totalWears, 1);
    });
  });
}
