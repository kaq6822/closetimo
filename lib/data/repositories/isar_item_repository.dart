// ItemRepository의 Isar 구현. Phase 3에서는 create만 구현하고,
// Phase 4·5·7에서 나머지 watch/get을 채워간다.

import 'package:isar/isar.dart';

import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../../features/add_item/new_item_draft.dart';
import '../models/item.dart';
import '../models/item_patch.dart';
import '../models/wear_event.dart';
import 'item_repository.dart';

class IsarItemRepository implements ItemRepository {
  IsarItemRepository({
    required Isar isar,
    required ImageStore imageStore,
    required Clock clock,
  })  : _isar = isar,
        _imageStore = imageStore,
        _clock = clock;

  final Isar _isar;
  final ImageStore _imageStore;
  final Clock _clock;

  IsarCollection<Item> get _items => _isar.items;

  @override
  Future<int> create(NewItemDraft draft) async {
    final trimmedName = draft.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Item name must be non-empty');
    }
    final now = _clock.now();
    final item = Item(
      name: trimmedName,
      brand: draft.brand.trim().isEmpty ? null : draft.brand.trim(),
      category: draft.category,
      careMethod: draft.careMethod,
      washCycle: draft.washCycle <= 0 ? 1 : draft.washCycle,
      createdAt: now,
      purchasedAt: draft.purchasedAt,
    );
    return _isar.writeTxn(() async {
      final id = await _items.put(item);
      // 사진이 있으면 sandbox로 복사하고 상대 경로를 저장.
      if (draft.tempPhoto != null) {
        final relPath = await _imageStore.copyTo(draft.tempPhoto!, '$id');
        item.imagePath = relPath;
        await _items.put(item);
      }
      return id;
    });
  }

  @override
  Stream<List<Item>> watchAll() {
    return _items
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) {
    final q = query.trim().toLowerCase();
    return watchAll().map((items) {
      var arr = items;
      if (category != null) {
        arr = arr.where((i) => i.category == category).toList();
      }
      if (q.isNotEmpty) {
        arr = arr.where((i) {
          final name = i.name.toLowerCase();
          final brand = (i.brand ?? '').toLowerCase();
          return name.contains(q) || brand.contains(q);
        }).toList();
      }
      final sorted = [...arr];
      switch (sort) {
        case WardrobeSort.statusCleanFirst:
          sorted.sort((a, b) {
            final aKey = a.status == ItemStatus.clean ? 0 : 1;
            final bKey = b.status == ItemStatus.clean ? 0 : 1;
            return aKey.compareTo(bKey);
          });
        case WardrobeSort.recentlyWorn:
          sorted.sort((a, b) {
            final aT = a.lastWornAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bT = b.lastWornAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bT.compareTo(aT);
          });
        case WardrobeSort.mostWorn:
          sorted.sort((a, b) => b.totalWears.compareTo(a.totalWears));
      }
      return sorted;
    });
  }

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) {
    return _items
        .filter()
        .lastWornAtIsNotNull()
        .sortByLastWornAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  @override
  Stream<WardrobeStats> watchStats() {
    return watchAll().map((items) {
      final perBucket = <Category, int>{
        Category.outer: 0,
        Category.top: 0,
        Category.bottom: 0,
        Category.etc: 0,
      };
      var clean = 0;
      var dirty = 0;
      for (final i in items) {
        if (i.status == ItemStatus.clean) {
          clean++;
        } else {
          dirty++;
        }
        final bucket = i.category.homeBucket;
        perBucket[bucket] = (perBucket[bucket] ?? 0) + 1;
      }
      return WardrobeStats(
        total: items.length,
        clean: clean,
        dirty: dirty,
        perBucket: perBucket,
      );
    });
  }

  @override
  Future<Item?> get(int id) {
    return _items.get(id);
  }

  @override
  Future<void> update(int id, ItemPatch patch) async {
    final trimmedName = patch.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Item name must be non-empty');
    }
    // removePhoto 경로에서 txn 밖 파일 삭제를 위해 이전 경로를 보관한다.
    String? pathToDelete;
    await _isar.writeTxn(() async {
      final item = await _items.get(id);
      if (item == null) return; // 미존재 no-op(FR: id 미존재 시 무시)
      item
        ..name = trimmedName
        ..brand =
            patch.brand == null || patch.brand!.trim().isEmpty
                ? null
                : patch.brand!.trim()
        ..category = patch.category
        ..careMethod = patch.careMethod
        ..washCycle = patch.washCycle <= 0 ? 1 : patch.washCycle
        ..purchasedAt = patch.purchasedAt;

      // 사진 3-way 의도(data-model.md §3): 교체 > 제거 > 유지.
      if (patch.newPhoto != null) {
        item.imagePath = await _imageStore.copyTo(patch.newPhoto!, '$id');
      } else if (patch.removePhoto) {
        pathToDelete = item.imagePath;
        item.imagePath = null;
      }

      // status 재평가(FR-004) — wearSinceWash/washCycle 불변식을 다시 맞춘다.
      item.status = item.wearSinceWash >= item.washCycle
          ? ItemStatus.dirty
          : ItemStatus.clean;

      await _items.put(item);
    });
    if (pathToDelete != null) {
      await _imageStore.delete(pathToDelete!); // best-effort(FR-011)
    }
  }

  @override
  Future<void> delete(int id) async {
    String? pathToDelete;
    await _isar.writeTxn(() async {
      final item = await _items.get(id);
      if (item == null) return; // 미존재 no-op
      pathToDelete = item.imagePath;

      // 연관 WearEvent 전량 제거(kind 무관) — orphan 방지(SC-004, FR-010).
      final eventIds = await _isar.wearEvents
          .filter()
          .itemIdEqualTo(id)
          .idProperty()
          .findAll();
      await _isar.wearEvents.deleteAll(eventIds);

      await _items.delete(id);
    });
    if (pathToDelete != null) {
      await _imageStore.delete(pathToDelete!); // best-effort(FR-011)
    }
  }
}
