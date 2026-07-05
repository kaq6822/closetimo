// 002 T014/T015 — ItemRepository.update/delete의 사이드이펙트 회귀.
// 프로젝트 관례(wear_record_test.dart)에 따라 in-memory fake로 contracts/
// repositories.md §1의 트랜잭션 의사코드를 그대로 미러링해 계약을 고정한다.

import 'dart:io';

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// copyTo/delete 호출을 기록하는 가짜 이미지 저장소.
class _FakeImageStore {
  final List<String> copiedForIds = [];
  final List<String> deletedPaths = [];

  Future<String> copyTo(File source, String itemId) async {
    copiedForIds.add(itemId);
    return 'items/$itemId.jpg';
  }

  Future<void> delete(String relativePath) async {
    deletedPaths.add(relativePath);
  }
}

/// contracts/repositories.md §1 update/delete 의사코드를 미러링한 fake.
class _InMemoryItemRepo {
  _InMemoryItemRepo(this.items, this.events, this.imageStore);

  final Map<int, Item> items;
  final List<WearEvent> events;
  final _FakeImageStore imageStore;

  Future<void> update(int id, ItemPatch patch) async {
    final trimmedName = patch.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Item name must be non-empty');
    }
    String? pathToDelete;
    final item = items[id];
    if (item == null) return;
    item
      ..name = trimmedName
      ..brand = patch.brand == null || patch.brand!.trim().isEmpty
          ? null
          : patch.brand!.trim()
      ..category = patch.category
      ..careMethod = patch.careMethod
      ..washCycle = patch.washCycle <= 0 ? 1 : patch.washCycle
      ..purchasedAt = patch.purchasedAt;

    if (patch.newPhoto != null) {
      item.imagePath = await imageStore.copyTo(patch.newPhoto!, '$id');
    } else if (patch.removePhoto) {
      pathToDelete = item.imagePath;
      item.imagePath = null;
    }

    item.status = item.wearSinceWash >= item.washCycle
        ? ItemStatus.dirty
        : ItemStatus.clean;

    if (pathToDelete != null) {
      await imageStore.delete(pathToDelete);
    }
  }

  Future<void> delete(int id) async {
    final item = items[id];
    if (item == null) return;
    final pathToDelete = item.imagePath;
    events.removeWhere((e) => e.itemId == id);
    items.remove(id);
    if (pathToDelete != null) {
      await imageStore.delete(pathToDelete);
    }
  }
}

Item _item({
  required int id,
  String name = '코트',
  int washCycle = 5,
  int wearSinceWash = 0,
  int totalWears = 0,
  ItemStatus status = ItemStatus.clean,
  String? imagePath,
}) =>
    Item(
      name: name,
      category: Category.outer,
      washCycle: washCycle,
      createdAt: DateTime(2026, 1, 1),
      status: status,
      wearSinceWash: wearSinceWash,
      totalWears: totalWears,
      imagePath: imagePath,
    )..id = id;

ItemPatch _patch({
  String name = '겨울 코트',
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

void main() {
  group('update (US1)', () {
    test('스칼라 필드를 갱신하고 파생 필드(카운터·마지막 착용)는 보존한다', () async {
      final item = _item(id: 1, wearSinceWash: 2, totalWears: 9)
        ..lastWornAt = DateTime(2026, 6, 1);
      final store = _FakeImageStore();
      final repo = _InMemoryItemRepo({1: item}, [], store);

      await repo.update(
        1,
        _patch(name: '겨울 코트', brand: 'ZARA', category: Category.top),
      );

      expect(item.name, '겨울 코트');
      expect(item.brand, 'ZARA');
      expect(item.category, Category.top);
      // 파생 필드 보존
      expect(item.wearSinceWash, 2);
      expect(item.totalWears, 9);
      expect(item.lastWornAt, DateTime(2026, 6, 1));
    });

    test('AC3: 세탁 주기를 낮춰 임계 도달하면 clean→dirty 재평가', () async {
      final item = _item(id: 1, washCycle: 10, wearSinceWash: 4);
      final repo = _InMemoryItemRepo({1: item}, [], _FakeImageStore());

      await repo.update(1, _patch(washCycle: 3));

      expect(item.washCycle, 3);
      expect(item.status, ItemStatus.dirty);
    });

    test('AC4: 세탁 주기를 올려 임계 미달이면 dirty→clean 복귀', () async {
      final item =
          _item(id: 1, washCycle: 5, wearSinceWash: 5, status: ItemStatus.dirty);
      final repo = _InMemoryItemRepo({1: item}, [], _FakeImageStore());

      await repo.update(1, _patch(washCycle: 8));

      expect(item.status, ItemStatus.clean);
    });

    test('빈 명칭은 ArgumentError로 거부한다', () async {
      final item = _item(id: 1);
      final repo = _InMemoryItemRepo({1: item}, [], _FakeImageStore());

      expect(() => repo.update(1, _patch(name: '   ')), throwsArgumentError);
    });

    test('빈 브랜드는 null로 정규화한다', () async {
      final item = _item(id: 1)..brand = '기존';
      final repo = _InMemoryItemRepo({1: item}, [], _FakeImageStore());

      await repo.update(1, _patch(brand: '  '));
      expect(item.brand, isNull);
    });

    test('washCycle <= 0은 1로 클램프한다', () async {
      final item = _item(id: 1, washCycle: 5);
      final repo = _InMemoryItemRepo({1: item}, [], _FakeImageStore());

      await repo.update(1, _patch(washCycle: 0));
      expect(item.washCycle, 1);
    });

    test('구매일 편집이 반영된다(FR-002)', () async {
      final item = _item(id: 1);
      final repo = _InMemoryItemRepo({1: item}, [], _FakeImageStore());

      await repo.update(1, _patch(purchasedAt: DateTime(2025, 3, 14)));
      expect(item.purchasedAt, DateTime(2025, 3, 14));
    });

    test('사진 의도: 교체 시 copyTo 호출 + imagePath 갱신', () async {
      final item = _item(id: 1, imagePath: 'items/1.jpg');
      final store = _FakeImageStore();
      final repo = _InMemoryItemRepo({1: item}, [], store);

      await repo.update(1, _patch(newPhoto: File('new.jpg')));

      expect(store.copiedForIds, ['1']);
      expect(item.imagePath, 'items/1.jpg');
      expect(store.deletedPaths, isEmpty);
    });

    test('사진 의도: 제거 시 기존 파일 삭제 + imagePath=null', () async {
      final item = _item(id: 1, imagePath: 'items/1.jpg');
      final store = _FakeImageStore();
      final repo = _InMemoryItemRepo({1: item}, [], store);

      await repo.update(1, _patch(removePhoto: true));

      expect(item.imagePath, isNull);
      expect(store.deletedPaths, ['items/1.jpg']);
    });

    test('사진 의도: 유지 시 imagePath 불변 + 파일 조작 없음', () async {
      final item = _item(id: 1, imagePath: 'items/1.jpg');
      final store = _FakeImageStore();
      final repo = _InMemoryItemRepo({1: item}, [], store);

      await repo.update(1, _patch());

      expect(item.imagePath, 'items/1.jpg');
      expect(store.copiedForIds, isEmpty);
      expect(store.deletedPaths, isEmpty);
    });

    test('미존재 id는 조용히 무시한다', () async {
      final repo = _InMemoryItemRepo({}, [], _FakeImageStore());
      await repo.update(999, _patch()); // no throw
    });

    // NewItemDraft.fromItem prefill 계약(002 T002).
    test('NewItemDraft.fromItem이 편집 가능 필드를 그대로 옮긴다', () {
      final item = _item(id: 1, name: '린넨 셔츠', washCycle: 7)
        ..brand = 'COS'
        ..careMethod = CareMethod.handWash
        ..category = Category.top;
      final draft = NewItemDraft.fromItem(item);

      expect(draft.name, '린넨 셔츠');
      expect(draft.brand, 'COS');
      expect(draft.category, Category.top);
      expect(draft.washCycle, 7);
      expect(draft.careMethod, CareMethod.handWash);
      expect(draft.tempPhoto, isNull);
    });
  });

  group('delete (US2)', () {
    test('SC-004: Item 삭제 시 연관 WearEvent 전량 제거(wear·wash 모두)', () async {
      final item = _item(id: 1);
      final other = _item(id: 2);
      final events = <WearEvent>[
        WearEvent(itemId: 1, kind: EventKind.wear, occurredAt: DateTime(2026, 5, 1))
          ..id = 10,
        WearEvent(itemId: 1, kind: EventKind.wash, occurredAt: DateTime(2026, 5, 2))
          ..id = 11,
        WearEvent(itemId: 2, kind: EventKind.wear, occurredAt: DateTime(2026, 5, 3))
          ..id = 12,
      ];
      final repo = _InMemoryItemRepo({1: item, 2: other}, events, _FakeImageStore());

      await repo.delete(1);

      expect(repo.items.containsKey(1), isFalse);
      // 다른 옷(id=2)과 그 이벤트는 잔존
      expect(repo.items.containsKey(2), isTrue);
      expect(events.where((e) => e.itemId == 1), isEmpty);
      expect(events.where((e) => e.itemId == 2), hasLength(1));
    });

    test('FR-011: 사진이 있으면 파일 삭제를 호출한다', () async {
      final item = _item(id: 1, imagePath: 'items/1.jpg');
      final store = _FakeImageStore();
      final repo = _InMemoryItemRepo({1: item}, [], store);

      await repo.delete(1);

      expect(store.deletedPaths, ['items/1.jpg']);
    });

    test('사진이 없으면 파일 삭제를 호출하지 않는다', () async {
      final item = _item(id: 1);
      final store = _FakeImageStore();
      final repo = _InMemoryItemRepo({1: item}, [], store);

      await repo.delete(1);

      expect(store.deletedPaths, isEmpty);
    });

    test('미존재 id는 조용히 무시한다', () async {
      final repo = _InMemoryItemRepo({}, [], _FakeImageStore());
      await repo.delete(999); // no throw
    });
  });
}
