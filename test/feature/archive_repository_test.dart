// #44 — 실제 Isar로 보관·복원 규칙과 활성 통계·검색·바구니 제외 정책을 검증한다.

import 'dart:io';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_archive_repository.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
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
    dir = Directory.systemTemp.createTempSync('closetimo_archive');
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: dir.path,
      name: 'archive',
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

  Future<int> create(String name, Category category, {int washCycle = 2}) =>
      items.create(
        NewItemDraft(name: name, category: category, washCycle: washCycle),
      );

  Future<List<String>> names(ItemFilter filter) async =>
      (await items
              .watchFiltered(filter: filter, sort: WardrobeSort.mostWorn)
              .first)
          .map((i) => i.name)
          .toList();

  test('보관하면 기록을 유지한 채 옷장·검색·통계·최근 착용·바구니에서 빠진다', () async {
    final coat = await create('울 코트', Category.outer);
    await create('린넨 셔츠', Category.top);
    await events.recordWear(coat, note: '출근');
    await events.recordWear(coat);
    await laundry.toggle(coat);
    expect((await laundry.watchBasket().first).map((i) => i.id), [coat]);

    clock.value = DateTime(2026, 10, 17, 8);
    await archive.archive(coat, reason: ArchiveReason.seasonal);

    final stored = (await items.get(coat))!;
    expect(stored.isArchived, isTrue);
    expect(stored.archivedAt, DateTime(2026, 10, 17, 8));
    expect(stored.archiveReason, ArchiveReason.seasonal);
    expect(stored.inLaundry, isFalse, reason: '보관 시 바구니에서 자동 제외');
    // 기록·카운터·상태 보존.
    expect(stored.totalWears, 2);
    expect(stored.wearSinceWash, 2);
    expect(stored.status, ItemStatus.dirty);
    expect(await events.watchForItem(coat).first, hasLength(2));

    // 기본 옷장·검색에서 제외.
    expect(await names(const ItemFilter()), ['린넨 셔츠']);
    expect(await names(const ItemFilter(query: '코트')), isEmpty);
    expect(await names(ItemFilter.homeBucket(HomeBucket.outer)), isEmpty);

    // 활성 통계·홈 카드 집계에서 제외.
    final stats = await items.watchStats().first;
    expect(stats.total, 1);
    expect(stats.dirty, 0);
    expect(stats.perBucket[HomeBucket.outer], 0);
    expect(stats.perBucket[HomeBucket.top], 1);

    // 최근 입은 옷·바구니에서 제외.
    expect(await items.watchRecentlyWorn().first, isEmpty);
    expect(await laundry.watchBasket().first, isEmpty);

    // 보관함·보관 범위 필터에는 나타난다.
    expect((await archive.watchArchived().first).map((i) => i.id), [coat]);
    expect(await names(const ItemFilter(archive: ArchiveScope.archived)), [
      '울 코트',
    ]);
    expect(
      await names(const ItemFilter(archive: ArchiveScope.all)),
      unorderedEquals(['울 코트', '린넨 셔츠']),
    );
  });

  test('보관한 옷은 바구니에 담을 수 없다', () async {
    final id = await create('니트', Category.top);
    await archive.archive(id);
    await laundry.toggle(id);
    expect((await items.get(id))!.inLaundry, isFalse);
    expect(await laundry.watchBasket().first, isEmpty);
    expect(await laundry.completeWashFor([id]), 0);
  });

  test('복원하면 기록·카운터를 유지한 채 활성 옷장으로 돌아온다', () async {
    final id = await create('데님', Category.bottom, washCycle: 5);
    await events.recordWear(id);
    await laundry.toggle(id);
    await archive.archive(id, reason: ArchiveReason.noLongerOwned);

    await archive.restore(id);

    final restored = (await items.get(id))!;
    expect(restored.isArchived, isFalse);
    expect(restored.archiveReason, ArchiveReason.unspecified);
    expect(restored.totalWears, 1);
    expect(restored.inLaundry, isFalse, reason: '바구니에는 자동으로 다시 담지 않는다');
    expect(await events.watchForItem(id).first, hasLength(1));
    expect(await names(const ItemFilter()), ['데님']);
    expect((await items.watchStats().first).total, 1);
    expect((await items.watchRecentlyWorn().first).map((i) => i.id), [id]);
    expect(await archive.watchArchived().first, isEmpty);
  });

  test('다시 보관하면 처음 보관 시각을 유지하고 사유만 바꾼다', () async {
    final id = await create('패딩', Category.outer);
    await archive.archive(id, reason: ArchiveReason.seasonal);
    clock.value = DateTime(2026, 12, 1);
    await archive.archive(id, reason: ArchiveReason.noLongerOwned);

    final item = (await items.get(id))!;
    expect(item.archivedAt, DateTime(2026, 10, 16, 9));
    expect(item.archiveReason, ArchiveReason.noLongerOwned);
  });

  test('보관함은 최근 보관 순이며 미존재 id는 무시한다', () async {
    final a = await create('A', Category.top);
    final b = await create('B', Category.top);
    await archive.archive(a);
    clock.value = DateTime(2026, 10, 18);
    await archive.archive(b);
    await archive.archive(999);
    await archive.restore(999);

    expect((await archive.watchArchived().first).map((i) => i.id), [b, a]);
  });

  test('삭제는 보관과 달리 옷과 기록을 모두 제거한다', () async {
    final id = await create('셔츠', Category.top);
    await events.recordWear(id);
    await archive.archive(id);

    await items.delete(id);

    expect(await items.get(id), isNull);
    expect(await events.watchForItem(id).first, isEmpty);
    expect(await archive.watchArchived().first, isEmpty);
  });
}
