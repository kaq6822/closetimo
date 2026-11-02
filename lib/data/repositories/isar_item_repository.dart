// ItemRepository의 Isar 구현. Phase 3에서는 create만 구현하고,
// Phase 4·5·7에서 나머지 watch/get을 채워간다.

import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:isar_plus/isar_plus.dart';

import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../../features/add_item/new_item_draft.dart';
import '../models/item.dart';
import '../models/item_attributes.dart';
import '../models/item_filter.dart';
import '../models/item_patch.dart';
import '../models/item_tags.dart';
import '../models/wear_event.dart';
import 'item_repository.dart';
import 'shared_items_watcher.dart';

class IsarItemRepository implements ItemRepository {
  IsarItemRepository({
    required Isar isar,
    required ImageStore imageStore,
    required Clock clock,
    SharedItemsWatcher? watcher,
  }) : _isar = isar,
       _imageStore = imageStore,
       _clock = clock,
       _watcher = watcher ?? SharedItemsWatcher(isar);

  final Isar _isar;
  final ImageStore _imageStore;
  final Clock _clock;
  final SharedItemsWatcher _watcher;

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
    draft.attributes.applyTo(item); // 005 — 카탈로그 기준 정규화
    final id = _items.autoIncrement();
    item.id = id;
    // 사진이 있으면 sandbox로 복사하고 상대 경로를 저장.
    if (draft.tempPhoto != null) {
      item.imagePath = await _imageStore.copyTo(draft.tempPhoto!, '$id');
      // 005 FR-513 — 배경 제거본은 원본이 있을 때만 붙인다. 선택 기능이라 복사에
      // 실패해도(예: OS가 임시 파일을 지움) 등록은 원본만으로 계속한다.
      if (draft.tempCutout case final cutout?) {
        item.cutoutPath = await _copyCutoutOrNull(cutout, id);
      }
    }
    _isar.write((isar) => isar.items.put(item));
    return id;
  }

  @override
  Stream<List<Item>> watchAll() {
    return _watcher.stream;
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
    return _watcher.stream.map((all) {
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
    // 005 FR-513 — 새 배경 제거본은 원본이 남는 경우에만 복사한다.
    final keepsPhoto =
        replacementPath != null ||
        (!patch.removePhoto && existing.imagePath != null);
    final newCutoutPath = patch.newCutout != null && keepsPhoto
        ? await _copyCutoutOrNull(patch.newCutout!, id)
        : null;
    // removePhoto 경로에서 txn 밖 파일 삭제를 위해 이전 경로를 보관한다.
    String? pathToDelete;
    String? cutoutToDelete;
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
      // 005 — 종류가 바뀌면 맞지 않는 세부 종류를 지운다(속성을 함께 보내지 않아도).
      (patch.attributes ?? ItemAttributeValues.of(item)).applyTo(item);

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

      // 배경 제거본(005 FR-513): 사진이 바뀌거나 지워지면 이전 제거본은 맞지 않는다.
      final cutoutStale =
          replacementPath != null || patch.removePhoto || patch.removeCutout;
      if (newCutoutPath != null) {
        if (item.cutoutPath != null && item.cutoutPath != newCutoutPath) {
          cutoutToDelete = item.cutoutPath;
        }
        item.cutoutPath = newCutoutPath;
      } else if (cutoutStale && item.cutoutPath != null) {
        cutoutToDelete = item.cutoutPath;
        item.cutoutPath = null;
      }

      // status 재평가(FR-004, #45) — 주기·관리 방식 변경을 반영한다.
      item.status = item.derivedStatus;

      isar.items.put(item);
    });
    if (pathToDelete != null) {
      await _imageStore.delete(pathToDelete!); // best-effort(FR-011)
    }
    if (cutoutToDelete != null) await _imageStore.delete(cutoutToDelete!);
  }

  @override
  Future<void> delete(int id) async {
    String? pathToDelete;
    String? cutoutToDelete;
    _isar.write((isar) {
      final item = isar.items.get(id);
      if (item == null) return; // 미존재 no-op
      pathToDelete = item.imagePath;
      cutoutToDelete = item.cutoutPath;

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
    if (cutoutToDelete != null) await _imageStore.delete(cutoutToDelete!);
  }

  /// 배경 제거본을 sandbox로 복사한다. 실패하면 로그만 남기고 null(원본만 사용).
  Future<String?> _copyCutoutOrNull(File source, int id) async {
    try {
      return await _imageStore.copyCutoutTo(source, '$id');
    } on FileSystemException catch (e) {
      debugPrint('Cutout copy failed for item $id: $e');
      return null;
    }
  }

  /// 용도 목록을 중복 없이 enum 순서로 정규화한다(저장 형태 안정화).
  static List<ItemPurpose> _normalizePurposes(Iterable<ItemPurpose> raw) =>
      raw.toSet().toList()..sort((a, b) => a.index.compareTo(b.index));
}
