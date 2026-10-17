// ItemRepository의 Isar 구현. Phase 3에서는 create만 구현하고,
// Phase 4·5·7에서 나머지 watch/get을 채워간다.

import 'package:isar_plus/isar_plus.dart';

import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../../features/add_item/new_item_draft.dart';
import '../models/item.dart';
import '../models/item_filter.dart';
import '../models/item_patch.dart';
import '../models/item_tags.dart';
import '../models/wear_event.dart';
import 'item_repository.dart';

class IsarItemRepository implements ItemRepository {
  IsarItemRepository({
    required Isar isar,
    required ImageStore imageStore,
    required Clock clock,
  }) : _isar = isar,
       _imageStore = imageStore,
       _clock = clock;

  final Isar _isar;
  final ImageStore _imageStore;
  final Clock _clock;

  IsarCollection<int, Item> get _items => _isar.items;

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
      careMode: draft.careMode,
      purposes: _normalizePurposes(draft.purposes),
      washCycle: draft.washCycle <= 0 ? 1 : draft.washCycle,
      createdAt: now,
      purchasedAt: draft.purchasedAt,
      tags: normalizeTags(draft.tags),
    );
    final id = _items.autoIncrement();
    item.id = id;
    // 사진이 있으면 sandbox로 복사하고 상대 경로를 저장.
    if (draft.tempPhoto != null) {
      item.imagePath = await _imageStore.copyTo(draft.tempPhoto!, '$id');
    }
    _isar.write((isar) => isar.items.put(item));
    return id;
  }

  @override
  Stream<List<Item>> watchAll() {
    return _items.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  @override
  Stream<List<Item>> watchFiltered({
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  }) {
    return watchAll().map((items) {
      final sorted = items.where(filter.matches).toList();
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
    // 보관한 옷은 홈 최근 착용에서 제외한다(#44).
    // 인덱스 조건 watch는 조건 밖으로 나가는 수정(보관)을 방출하지 않으므로
    // 전체를 구독하고 Dart에서 거른다.
    return _items
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((all) {
          final worn = [
            for (final i in all)
              if (i.lastWornAt != null && !i.isArchived) i,
          ]..sort((a, b) => b.lastWornAt!.compareTo(a.lastWornAt!));
          return worn.take(limit).toList();
        });
  }

  @override
  Stream<WardrobeStats> watchStats() {
    return watchAll().map((items) {
      final perBucket = <HomeBucket, int>{
        for (final b in HomeBucket.values) b: 0,
      };
      var clean = 0;
      var dirty = 0;
      // 보관한 옷은 활성 통계·홈 카드 집계에서 제외한다(#44). 기본
      // ItemFilter(활성만)와 같은 범위라 perBucket과 목록 수가 일치한다.
      final active = items.where((i) => !i.isArchived).toList();
      for (final i in active) {
        if (i.status == ItemStatus.clean) {
          clean++;
        } else {
          dirty++;
        }
        final bucket = i.category.homeBucket;
        perBucket[bucket] = perBucket[bucket]! + 1;
      }
      return WardrobeStats(
        total: active.length,
        clean: clean,
        dirty: dirty,
        perBucket: perBucket,
      );
    });
  }

  @override
  Future<Item?> get(int id) async => _items.get(id);

  @override
  Future<void> update(int id, ItemPatch patch) async {
    final trimmedName = patch.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Item name must be non-empty');
    }
    final existing = _items.get(id);
    if (existing == null) return;
    final replacementPath = patch.newPhoto == null
        ? null
        : await _imageStore.copyTo(patch.newPhoto!, '$id');
    // removePhoto 경로에서 txn 밖 파일 삭제를 위해 이전 경로를 보관한다.
    String? pathToDelete;
    _isar.write((isar) {
      final item = isar.items.get(id);
      if (item == null) return; // 미존재 no-op(FR: id 미존재 시 무시)
      item
        ..name = trimmedName
        ..brand = patch.brand == null || patch.brand!.trim().isEmpty
            ? null
            : patch.brand!.trim()
        ..category = patch.category
        ..careMethod = patch.careMethod
        ..careMode = patch.careMode
        ..purposes = _normalizePurposes(patch.purposes)
        ..washCycle = patch.washCycle <= 0 ? 1 : patch.washCycle
        ..purchasedAt = patch.purchasedAt;
      if (patch.tags case final tags?) item.tags = normalizeTags(tags);

      // 사진 3-way 의도(data-model.md §3): 교체 > 제거 > 유지.
      if (replacementPath != null) {
        // 복원된 사진(`items/{id}_r….jpg`, #40)처럼 경로가 바뀌면 이전 파일이
        // 고아로 남지 않도록 지운다. 같은 경로면 copyTo가 이미 덮어썼다.
        if (item.imagePath != null && item.imagePath != replacementPath) {
          pathToDelete = item.imagePath;
        }
        item.imagePath = replacementPath;
      } else if (patch.removePhoto) {
        pathToDelete = item.imagePath;
        item.imagePath = null;
      }

      // status 재평가(FR-004, #45) — 주기·관리 방식 변경을 반영한다.
      item.status = item.derivedStatus;

      isar.items.put(item);
    });
    if (pathToDelete != null) {
      await _imageStore.delete(pathToDelete!); // best-effort(FR-011)
    }
  }

  @override
  Future<void> delete(int id) async {
    String? pathToDelete;
    _isar.write((isar) {
      final item = isar.items.get(id);
      if (item == null) return; // 미존재 no-op
      pathToDelete = item.imagePath;

      // 연관 WearEvent 전량 제거(kind 무관) — orphan 방지(SC-004, FR-010).
      final eventIds = isar.wearEvents
          .where()
          .itemIdEqualTo(id)
          .idProperty()
          .findAll();
      isar.wearEvents.deleteAll(eventIds);

      isar.items.delete(id);
    });
    if (pathToDelete != null) {
      await _imageStore.delete(pathToDelete!); // best-effort(FR-011)
    }
  }

  /// 용도 목록을 중복 없이 enum 순서로 정규화한다(저장 형태 안정화).
  static List<ItemPurpose> _normalizePurposes(Iterable<ItemPurpose> raw) =>
      raw.toSet().toList()..sort((a, b) => a.index.compareTo(b.index));
}
