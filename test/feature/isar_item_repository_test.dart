// 002 리뷰 후속 — 실제 Isar 인스턴스로 IsarItemRepository.update/delete를 검증한다.
// item_edit_delete_test.dart는 의사코드를 미러링한 fake를 쓰므로, 이번에 새로
// 도입된 Isar 쿼리 경로(`itemIdEqualTo().idProperty().findAll()` + `deleteAll`)와
// `writeTxn` 원자성은 실행 검증되지 않았다. lib/data/AGENTS.md 규칙("repository
// 로직 변경 시 in-memory Isar 인스턴스로 검증")에 따라 실제 Isar로 cascade·재평가·
// 사진 파일 처리를 직접 확인한다.

import 'dart:io';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class _FixedClock implements Clock {
  const _FixedClock();
  @override
  DateTime now() => _fixedNow;
}

/// 테스트 전역 고정 시각. update/delete는 시각을 기록하지 않으므로 시드 전용이다.
final _fixedNow = DateTime(2026, 7, 1);

void main() {
  // Isar Core 네이티브 바이너리를 테스트 프로세스로 내려받아 로드한다(최초 1회 네트워크).
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late Directory tmpDir;
  late Isar isar;
  late ImageStore imageStore;
  late IsarItemRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('closetimo_isar_test');
    isar = await Isar.open(
      [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: tmpDir.path,
      inspector: false,
    );
    // 사진 파일은 tmpDir을 sandbox 루트로 오버라이드해 path_provider 없이 검증한다.
    imageStore = ImageStore(overrideRoot: tmpDir);
    repo = IsarItemRepository(
      isar: isar,
      imageStore: imageStore,
      clock: const _FixedClock(),
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  Future<int> seedItem({
    String name = '코트',
    int washCycle = 5,
    int wearSinceWash = 0,
    int totalWears = 0,
    ItemStatus status = ItemStatus.clean,
    String? imagePath,
    DateTime? lastWornAt,
  }) async {
    final item = Item(
      name: name,
      category: Category.outer,
      washCycle: washCycle,
      createdAt: _fixedNow,
      status: status,
      wearSinceWash: wearSinceWash,
      totalWears: totalWears,
      imagePath: imagePath,
    )..lastWornAt = lastWornAt;
    return isar.writeTxn(() => isar.items.put(item));
  }

  Future<int> seedEvent(int itemId, EventKind kind) {
    final event = WearEvent(itemId: itemId, kind: kind, occurredAt: _fixedNow);
    return isar.writeTxn(() => isar.wearEvents.put(event));
  }

  group('IsarItemRepository.update (real Isar)', () {
    test('스칼라 갱신 + 파생 필드 보존 + status 재평가(하향→dirty)', () async {
      final id = await seedItem(washCycle: 10, wearSinceWash: 4, totalWears: 9);
      await repo.update(
        id,
        ItemPatch(
          name: '겨울 코트',
          brand: 'ZARA',
          category: Category.top,
          careMethod: CareMethod.handWash,
          washCycle: 3, // wearSinceWash(4) >= 3 → dirty
          purchasedAt: DateTime(2025, 3, 14),
        ),
      );

      final saved = (await isar.items.get(id))!;
      expect(saved.name, '겨울 코트');
      expect(saved.brand, 'ZARA');
      expect(saved.category, Category.top);
      expect(saved.careMethod, CareMethod.handWash);
      expect(saved.washCycle, 3);
      expect(saved.purchasedAt, DateTime(2025, 3, 14));
      // 재평가
      expect(saved.status, ItemStatus.dirty);
      // 파생 필드 보존
      expect(saved.wearSinceWash, 4);
      expect(saved.totalWears, 9);
    });

    test('세탁 주기 상향 → dirty에서 clean으로 복귀', () async {
      final id = await seedItem(
        washCycle: 5,
        wearSinceWash: 5,
        status: ItemStatus.dirty,
      );
      await repo.update(id, _basePatch(washCycle: 8));

      expect((await isar.items.get(id))!.status, ItemStatus.clean);
    });

    test('빈 명칭은 ArgumentError로 거부하고 DB를 변경하지 않는다', () async {
      final id = await seedItem(name: '원본');
      await expectLater(
        repo.update(id, _basePatch(name: '   ')),
        throwsArgumentError,
      );
      expect((await isar.items.get(id))!.name, '원본');
    });

    test('미존재 id는 조용히 무시한다(no-op)', () async {
      await repo.update(999, _basePatch());
      expect(await isar.items.count(), 0);
    });

    test('사진 교체: sandbox 파일이 생성되고 imagePath가 갱신된다', () async {
      final id = await seedItem();
      final src = File('${tmpDir.path}/source.jpg')..writeAsBytesSync([1, 2, 3]);

      await repo.update(id, _basePatch(newPhoto: src));

      final saved = (await isar.items.get(id))!;
      expect(saved.imagePath, 'items/$id.jpg');
      expect(File('${tmpDir.path}/$id.jpg').existsSync(), isTrue);
    });

    test('사진 제거: 기존 파일이 삭제되고 imagePath=null', () async {
      final id = await seedItem(imagePath: 'items/1.jpg');
      final file = File('${tmpDir.path}/1.jpg')..writeAsBytesSync([9]);
      expect(file.existsSync(), isTrue);

      await repo.update(id, _basePatch(removePhoto: true));

      expect((await isar.items.get(id))!.imagePath, isNull);
      expect(file.existsSync(), isFalse); // best-effort 삭제가 실제로 수행됨
    });
  });

  group('IsarItemRepository.delete (real Isar)', () {
    test('SC-004: Item + 연관 WearEvent(wear·wash) 전량 cascade, 타 옷은 잔존',
        () async {
      final target = await seedItem(name: '삭제될 코트');
      final other = await seedItem(name: '남는 셔츠');
      await seedEvent(target, EventKind.wear);
      await seedEvent(target, EventKind.wash);
      await seedEvent(other, EventKind.wear);

      await repo.delete(target);

      // 대상 Item 제거
      expect(await isar.items.get(target), isNull);
      // 대상의 이벤트 전량 제거(실제 itemIdEqualTo 쿼리 경로 검증)
      final targetEvents =
          await isar.wearEvents.filter().itemIdEqualTo(target).findAll();
      expect(targetEvents, isEmpty);
      // 타 옷과 그 이벤트는 온전히 잔존
      expect(await isar.items.get(other), isNotNull);
      final otherEvents =
          await isar.wearEvents.filter().itemIdEqualTo(other).findAll();
      expect(otherEvents, hasLength(1));
    });

    test('FR-011: 이미지 파일도 함께 제거된다', () async {
      final id = await seedItem(imagePath: 'items/1.jpg');
      final file = File('${tmpDir.path}/1.jpg')..writeAsBytesSync([7]);

      await repo.delete(id);

      expect(await isar.items.get(id), isNull);
      expect(file.existsSync(), isFalse);
    });

    test('미존재 id는 조용히 무시한다(no-op)', () async {
      final survivor = await seedItem(name: '생존자');
      await seedEvent(survivor, EventKind.wear);

      await repo.delete(999);

      expect(await isar.items.count(), 1);
      expect(await isar.wearEvents.count(), 1);
    });
  });
}

ItemPatch _basePatch({
  String name = '수정 코트',
  String? brand,
  Category category = Category.outer,
  CareMethod careMethod = CareMethod.machine,
  int washCycle = 5,
  DateTime? purchasedAt,
  File? newPhoto,
  bool removePhoto = false,
}) =>
    ItemPatch(
      name: name,
      brand: brand,
      category: category,
      careMethod: careMethod,
      washCycle: washCycle,
      purchasedAt: purchasedAt,
      newPhoto: newPhoto,
      removePhoto: removePhoto,
    );
