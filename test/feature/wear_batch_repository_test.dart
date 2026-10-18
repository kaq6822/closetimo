// #39 — 실제 Isar로 여러 벌 착용 기록·날짜 지정·날짜 수정·실행 취소 규칙을 검증한다
// (spec FR-008c·FR-010c·FR-010d·FR-010e).

import 'dart:io';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_archive_repository.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

import '../support/isar_plus_test_support.dart';

class _MutableClock implements Clock {
  DateTime value = DateTime(2026, 10, 16, 9);
  @override
  DateTime now() => value;
}

void main() {
  setUpAll(initializeIsarPlusForTests);

  late Directory dir;
  late Isar isar;
  late _MutableClock clock;
  late IsarItemRepository items;
  late IsarEventRepository events;
  late IsarLaundryRepository laundry;
  late IsarArchiveRepository archive;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('closetimo_wear_batch');
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: dir.path,
      name: 'wear_batch',
      inspector: false,
    );
    clock = _MutableClock();
    items = IsarItemRepository(
      isar: isar,
      imageStore: ImageStore(overrideRoot: dir),
      clock: clock,
    );
    events = IsarEventRepository(isar: isar, clock: clock);
    laundry = IsarLaundryRepository(isar: isar, clock: clock);
    archive = IsarArchiveRepository(isar: isar, clock: clock);
  });

  tearDown(() {
    if (isar.isOpen) isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<int> create(String name, {int washCycle = 3}) => items.create(
    NewItemDraft(name: name, category: Category.top, washCycle: washCycle),
  );

  Future<Item> get(int id) async => (await items.get(id))!;

  List<WearEvent> wearsOf(int id) => isar.wearEvents
      .where()
      .itemIdEqualTo(id)
      .kindEqualTo(EventKind.wear)
      .findAll();

  /// [id]를 세탁 바구니에 담고 지금 시각으로 세탁 완료한다.
  Future<void> wash(int id) async {
    await laundry.toggle(id);
    await laundry.completeWashFor([id]);
  }

  group('recordWearBatch (FR-008c)', () {
    test('선택한 옷마다 같은 날짜·메모로 1건씩 기록하고 카운터를 갱신한다', () async {
      final a = await create('셔츠', washCycle: 2);
      final b = await create('바지');
      await events.recordWear(a);

      final result = await events.recordWearBatch([a, b], note: ' 출근 ');

      expect(result.recorded, 2);
      expect(result.skipped, 0);
      final shirt = await get(a);
      expect(shirt.totalWears, 2);
      expect(shirt.wearSinceWash, 2);
      expect(shirt.status, ItemStatus.dirty);
      expect(shirt.lastWornAt, clock.value);
      final pants = await get(b);
      expect(pants.totalWears, 1);
      expect(pants.status, ItemStatus.clean);
      final batchEvents = [
        for (final id in result.eventIds) isar.wearEvents.get(id)!,
      ];
      expect(batchEvents.map((e) => e.itemId), [a, b]);
      expect(batchEvents.every((e) => e.note == '출근'), isTrue);
      expect(batchEvents.every((e) => e.occurredAt == clock.value), isTrue);
    });

    test('중복 id·보관한 옷·없는 옷은 제외하고 제외 수를 돌려준다', () async {
      final a = await create('셔츠');
      final archived = await create('코트');
      await archive.archive(archived);

      final result = await events.recordWearBatch([a, a, archived, 999]);

      expect(result.recorded, 1);
      expect(result.skipped, 3);
      expect(wearsOf(a), hasLength(1));
      expect((await get(a)).totalWears, 1);
      expect(wearsOf(archived), isEmpty);
      expect((await get(archived)).totalWears, 0);
    });

    test('미래 날짜·80자 초과 메모는 아무것도 저장하지 않고 거부한다', () async {
      final a = await create('셔츠');
      await expectLater(
        events.recordWearBatch([a], wornOn: DateTime(2026, 10, 17)),
        throwsArgumentError,
      );
      await expectLater(
        events.recordWearBatch([a], note: 'a' * 81),
        throwsArgumentError,
      );
      expect(wearsOf(a), isEmpty);
      expect((await get(a)).totalWears, 0);
    });

    test('manual 관리 옷은 횟수가 쌓여도 dirty가 되지 않는다', () async {
      final a = await items.create(
        const NewItemDraft(
          name: '모자',
          category: Category.accessory,
          washCycle: 1,
          careMode: CareMode.manual,
        ),
      );
      await events.recordWearBatch([a]);
      final hat = await get(a);
      expect(hat.wearSinceWash, 1);
      expect(hat.status, ItemStatus.clean);
    });
  });

  group('착용 날짜(FR-010d)', () {
    test('과거 날짜는 그날 12:00으로 저장하고 lastWornAt을 앞당기지 않는다', () async {
      final a = await create('셔츠');
      await events.recordWear(a);
      final id = await events.recordWear(a, wornOn: DateTime(2026, 10, 14));

      final ev = isar.wearEvents.get(id!)!;
      expect(ev.occurredAt, DateTime(2026, 10, 14, 12));
      final shirt = await get(a);
      expect(shirt.lastWornAt, clock.value);
      expect(shirt.totalWears, 2);
      expect(shirt.wearSinceWash, 2);
    });

    test('가장 최근 세탁 이전 날짜의 기록은 wearSinceWash·상태에 더하지 않는다', () async {
      final a = await create('셔츠', washCycle: 1);
      clock.value = DateTime(2026, 10, 15, 18);
      await wash(a);
      clock.value = DateTime(2026, 10, 16, 9);

      // 10/15 12:00 < 세탁 10/15 18:00 → 세탁 이전 착용.
      await events.recordWear(a, wornOn: DateTime(2026, 10, 15));
      var shirt = await get(a);
      expect(shirt.totalWears, 1);
      expect(shirt.wearSinceWash, 0);
      expect(shirt.status, ItemStatus.clean);

      // 세탁 이후(오늘) 착용은 현재 주기에 더해져 dirty가 된다.
      await events.recordWear(a);
      shirt = await get(a);
      expect(shirt.totalWears, 2);
      expect(shirt.wearSinceWash, 1);
      expect(shirt.status, ItemStatus.dirty);
    });

    test('세탁 이후의 과거 날짜는 현재 주기에 포함된다', () async {
      final a = await create('셔츠');
      clock.value = DateTime(2026, 10, 10, 9);
      await wash(a);
      clock.value = DateTime(2026, 10, 16, 9);

      await events.recordWear(a, wornOn: DateTime(2026, 10, 12));
      expect((await get(a)).wearSinceWash, 1);
    });
  });

  group('updateWearDate (FR-010c)', () {
    test('세탁 이전 날짜로 옮기면 wearSinceWash가 줄고 상태가 clean으로 돌아온다', () async {
      final a = await create('셔츠', washCycle: 1);
      clock.value = DateTime(2026, 10, 15, 18);
      await wash(a);
      clock.value = DateTime(2026, 10, 16, 9);
      final id = await events.recordWear(a);
      expect((await get(a)).status, ItemStatus.dirty);

      await events.updateWearDate(id!, DateTime(2026, 10, 14));

      final shirt = await get(a);
      expect(isar.wearEvents.get(id)!.occurredAt, DateTime(2026, 10, 14, 12));
      expect(shirt.totalWears, 1);
      expect(shirt.wearSinceWash, 0);
      expect(shirt.status, ItemStatus.clean);
      expect(shirt.lastWornAt, DateTime(2026, 10, 14, 12));
    });

    test('세탁 이전 기록을 세탁 이후로 옮기면 wearSinceWash가 늘어난다', () async {
      final a = await create('셔츠', washCycle: 1);
      clock.value = DateTime(2026, 10, 15, 18);
      await wash(a);
      clock.value = DateTime(2026, 10, 16, 9);
      final id = await events.recordWear(a, wornOn: DateTime(2026, 10, 14));
      expect((await get(a)).wearSinceWash, 0);

      await events.updateWearDate(id!, DateTime(2026, 10, 16));

      final shirt = await get(a);
      expect(isar.wearEvents.get(id)!.occurredAt, clock.value);
      expect(shirt.wearSinceWash, 1);
      expect(shirt.status, ItemStatus.dirty);
      expect(shirt.lastWornAt, clock.value);
    });

    test('같은 날짜는 no-op, 미래 날짜는 거부, wash 이벤트는 StateError', () async {
      final a = await create('셔츠');
      final id = await events.recordWear(a);
      await events.updateWearDate(id!, DateTime(2026, 10, 16, 23));
      expect(isar.wearEvents.get(id)!.occurredAt, clock.value);

      await expectLater(
        events.updateWearDate(id, DateTime(2026, 10, 18)),
        throwsArgumentError,
      );

      await wash(a);
      final washId = isar.wearEvents
          .where()
          .itemIdEqualTo(a)
          .kindEqualTo(EventKind.wash)
          .findFirst()!
          .id;
      await expectLater(
        events.updateWearDate(washId, DateTime(2026, 10, 15)),
        throwsStateError,
      );
    });
  });

  group('deleteWearEvents (FR-010e 실행 취소)', () {
    test('일괄 기록을 실행 취소하면 카운터·lastWornAt·상태가 기록 전으로 돌아간다', () async {
      final a = await create('셔츠', washCycle: 2);
      final b = await create('바지');
      clock.value = DateTime(2026, 10, 15, 9);
      await events.recordWear(a);
      clock.value = DateTime(2026, 10, 16, 9);

      final result = await events.recordWearBatch([a, b]);
      expect((await get(a)).status, ItemStatus.dirty);

      await events.deleteWearEvents(result.eventIds);

      final shirt = await get(a);
      expect(shirt.totalWears, 1);
      expect(shirt.wearSinceWash, 1);
      expect(shirt.status, ItemStatus.clean);
      expect(shirt.lastWornAt, DateTime(2026, 10, 15, 9));
      final pants = await get(b);
      expect(pants.totalWears, 0);
      expect(pants.lastWornAt, isNull);
      expect(wearsOf(b), isEmpty);
    });

    test('이미 지운 id·wash 이벤트 id는 건너뛴다', () async {
      final a = await create('셔츠');
      final id = await events.recordWear(a);
      await events.deleteWearEvent(id!);
      await wash(a);
      final washId = isar.wearEvents.where().itemIdEqualTo(a).findFirst()!.id;

      await events.deleteWearEvents([id, washId]);

      expect(isar.wearEvents.get(washId), isNotNull);
      expect((await get(a)).totalWears, 0);
    });
  });
}
