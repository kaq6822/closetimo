// #37·#41·#45 — 실제 Isar로 분류 집계·필터 범위와 관리 방식 규칙을 검증한다.

import 'dart:io';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

import '../support/isar_plus_test_support.dart';

class _FixedClock implements Clock {
  const _FixedClock();
  @override
  DateTime now() => DateTime(2026, 10, 16, 9);
}

void main() {
  setUpAll(initializeIsarPlusForTests);

  late Directory dir;
  late Isar isar;
  late IsarItemRepository items;
  late IsarEventRepository events;
  late IsarLaundryRepository laundry;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('closetimo_classification');
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: dir.path,
      name: 'classification',
      inspector: false,
    );
    items = IsarItemRepository(
      isar: isar,
      imageStore: ImageStore(overrideRoot: dir),
      clock: const _FixedClock(),
    );
    events = IsarEventRepository(isar: isar, clock: const _FixedClock());
    laundry = IsarLaundryRepository(isar: isar, clock: const _FixedClock());
  });

  tearDown(() {
    if (isar.isOpen) isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<int> create(
    String name,
    Category category, {
    List<ItemPurpose> purposes = const [],
    CareMode careMode = CareMode.wearCycle,
    int washCycle = 2,
  }) => items.create(
    NewItemDraft(
      name: name,
      category: category,
      purposes: purposes,
      careMode: careMode,
      washCycle: washCycle,
    ),
  );

  ItemPatch patchOf(Item item, {CareMode? careMode, int? washCycle}) =>
      ItemPatch(
        name: item.name,
        category: item.category,
        careMethod: item.careMethod,
        washCycle: washCycle ?? item.washCycle,
        careMode: careMode ?? item.careMode,
        purposes: item.purposes,
      );

  group('#37 홈 집계와 카드 이동 목록 범위', () {
    test('신발·가방만 있어도 그 외 카드 수와 이동 목록 수가 같다', () async {
      await create('러닝화', Category.shoes);
      await create('토트백', Category.bag);

      final stats = await items.watchStats().first;
      final listed = await items
          .watchFiltered(
            filter: ItemFilter.homeBucket(HomeBucket.others),
            sort: WardrobeSort.statusCleanFirst,
          )
          .first;

      expect(stats.perBucket[HomeBucket.others], 2);
      expect(listed, hasLength(2));
      // 개별 '기타' 필터에는 나오지 않는다.
      final etcOnly = await items
          .watchFiltered(
            filter: ItemFilter.category(Category.etc),
            sort: WardrobeSort.statusCleanFirst,
          )
          .first;
      expect(etcOnly, isEmpty);
    });

    test('모든 버킷의 카드 수 합은 전체 수이고 각 버킷 목록 수와 같다', () async {
      final categories = [
        Category.outer,
        Category.top,
        Category.top,
        Category.bottom,
        Category.onepiece,
        Category.accessory,
        Category.etc,
        Category.uncategorized,
      ];
      for (var i = 0; i < categories.length; i++) {
        await create('옷 $i', categories[i]);
      }

      final stats = await items.watchStats().first;
      expect(stats.perBucket.keys.toSet(), HomeBucket.values.toSet());
      expect(stats.perBucket.values.fold<int>(0, (a, b) => a + b), stats.total);
      for (final bucket in HomeBucket.values) {
        final listed = await items
            .watchFiltered(
              filter: ItemFilter.homeBucket(bucket),
              sort: WardrobeSort.statusCleanFirst,
            )
            .first;
        expect(listed.length, stats.perBucket[bucket], reason: '$bucket');
      }
      expect(stats.perBucket[HomeBucket.top], 2);
      expect(stats.perBucket[HomeBucket.others], 4);
    });
  });

  group('#41 종류·용도', () {
    test('기본 draft는 미분류·관리 방법 미지정·횟수 기반으로 저장된다', () async {
      final id = await items.create(const NewItemDraft(name: '새 옷'));
      final saved = isar.items.get(id)!;
      expect(saved.category, Category.uncategorized);
      expect(saved.careMethod, CareMethod.unspecified);
      expect(saved.careMode, CareMode.wearCycle);
      expect(saved.purposes, isEmpty);
      // 미분류는 아우터로 집계되지 않는다.
      final stats = await items.watchStats().first;
      expect(stats.perBucket[HomeBucket.outer], 0);
      expect(stats.perBucket[HomeBucket.others], 1);
    });

    test('용도는 중복 없이 저장되고 종류와 독립적으로 거른다', () async {
      final sportTop = await create(
        '운동 티',
        Category.top,
        purposes: const [ItemPurpose.sport, ItemPurpose.sport],
      );
      await create('니트', Category.top);
      expect(isar.items.get(sportTop)!.purposes, [ItemPurpose.sport]);

      final listed = await items
          .watchFiltered(
            filter: const ItemFilter(
              categories: {Category.top},
              purposes: {ItemPurpose.sport},
            ),
            sort: WardrobeSort.statusCleanFirst,
          )
          .first;
      expect(listed.map((i) => i.name), ['운동 티']);
    });

    test('update는 용도를 전체 교체한다', () async {
      final id = await create(
        '운동 티',
        Category.top,
        purposes: const [ItemPurpose.sport],
      );
      final item = isar.items.get(id)!;
      await items.update(
        id,
        ItemPatch(
          name: item.name,
          category: Category.top,
          careMethod: item.careMethod,
          washCycle: item.washCycle,
          careMode: item.careMode,
          purposes: const [],
        ),
      );
      expect(isar.items.get(id)!.purposes, isEmpty);
    });
  });

  group('#45 관리 방식', () {
    test('manual 옷은 착용을 기록해도 카운터만 늘고 dirty가 되지 않는다', () async {
      final id = await create('가방', Category.bag, careMode: CareMode.manual);
      await events.recordWear(id);
      await events.recordWear(id);
      await events.recordWear(id);

      final saved = isar.items.get(id)!;
      expect(saved.wearSinceWash, 3);
      expect(saved.totalWears, 3);
      expect(saved.status, ItemStatus.clean);
    });

    test('주기 미적용이어도 바구니에 담고 세탁 완료할 수 있다', () async {
      final id = await create('니트', Category.top, careMode: CareMode.manual);
      await events.recordWear(id);

      await laundry.toggle(id);
      expect(isar.items.get(id)!.inLaundry, isTrue);
      expect(isar.items.get(id)!.status, ItemStatus.clean);

      await laundry.completeWashFor([id]);
      final saved = isar.items.get(id)!;
      expect(saved.inLaundry, isFalse);
      expect(saved.wearSinceWash, 0);
      expect(saved.totalWears, 1);
      expect(saved.lastWashedAt, isNotNull);
    });

    test('dirty 옷을 manual로 바꾸면 clean, 다시 켜면 보존된 주기로 재평가된다', () async {
      final id = await create('셔츠', Category.top, washCycle: 2);
      await events.recordWear(id);
      await events.recordWear(id);
      expect(isar.items.get(id)!.status, ItemStatus.dirty);

      await items.update(
        id,
        patchOf(isar.items.get(id)!, careMode: CareMode.manual),
      );
      var saved = isar.items.get(id)!;
      expect(saved.careMode, CareMode.manual);
      expect(saved.status, ItemStatus.clean);
      expect(saved.washCycle, 2);
      expect(saved.wearSinceWash, 2);

      await items.update(id, patchOf(saved, careMode: CareMode.wearCycle));
      saved = isar.items.get(id)!;
      expect(saved.status, ItemStatus.dirty);
    });
  });
}
