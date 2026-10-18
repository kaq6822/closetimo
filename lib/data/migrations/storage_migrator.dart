import 'package:closetimo_legacy_isar/closetimo_legacy_isar.dart';
import 'package:isar_plus/isar_plus.dart';

import '../../core/utils/clock.dart';
import '../models/item.dart';
import '../models/storage_metadata.dart';
import '../models/user_preferences.dart';
import '../models/wear_event.dart';

typedef LegacySnapshotReader =
    Future<LegacySnapshot?> Function(String directory);

enum MigrationSource {
  fresh,
  legacyV3,
  alreadyMigrated,

  /// 이미 이전된 저장소의 데이터 형식을 현재 버전으로 올렸다.
  upgraded,
}

class MigrationResult {
  const MigrationResult({
    required this.source,
    required this.itemCount,
    required this.eventCount,
  });

  final MigrationSource source;
  final int itemCount;
  final int eventCount;
}

/// legacy Isar 3 데이터를 새 저장소에 한 번만 원자적으로 이전하고,
/// 이미 이전된 저장소는 [StorageMetadata.currentStorageVersion]까지 올린다.
class StorageMigrator {
  const StorageMigrator({this.readLegacySnapshot = LegacyStore.readSnapshot});

  final LegacySnapshotReader readLegacySnapshot;

  Future<MigrationResult> migrateIfNeeded({
    required Isar newStore,
    required String directory,
    required Clock clock,
  }) async {
    final metadata = newStore.storageMetadatas.get(StorageMetadata.singletonId);
    if (metadata != null) {
      final upgraded = _upgradeIfNeeded(newStore, metadata);
      return MigrationResult(
        source: upgraded
            ? MigrationSource.upgraded
            : MigrationSource.alreadyMigrated,
        itemCount: newStore.items.count(),
        eventCount: newStore.wearEvents.count(),
      );
    }

    final snapshot = await readLegacySnapshot(directory);
    if (snapshot == null) {
      final now = clock.now();
      newStore.write((isar) {
        final preferences = UserPreferences.defaults()..firstLaunchedAt = now;
        isar.userPreferences.put(preferences);
        isar.storageMetadatas.put(
          StorageMetadata(
            storageVersion: StorageMetadata.currentStorageVersion,
            migratedAt: now,
            legacyItemCount: 0,
            legacyEventCount: 0,
            source: StorageSource.fresh,
          ),
        );
      });
      return const MigrationResult(
        source: MigrationSource.fresh,
        itemCount: 0,
        eventCount: 0,
      );
    }

    _validateSnapshot(snapshot);
    final items = snapshot.items.map(_convertItem).toList(growable: false);
    final events = snapshot.events.map(_convertEvent).toList(growable: false);
    final preferences = _convertPreferences(snapshot.preferences, clock.now());
    final migratedAt = clock.now();

    newStore.write((isar) {
      isar.items.putAll(items);
      isar.wearEvents.putAll(events);
      isar.userPreferences.put(preferences);
      isar.storageMetadatas.put(
        StorageMetadata(
          storageVersion: StorageMetadata.currentStorageVersion,
          migratedAt: migratedAt,
          legacyItemCount: items.length,
          legacyEventCount: events.length,
          source: StorageSource.legacyV3,
        ),
      );
      if (isar.items.count() != items.length ||
          isar.wearEvents.count() != events.length) {
        throw StateError('Migrated record count does not match legacy data');
      }
    });

    return MigrationResult(
      source: MigrationSource.legacyV3,
      itemCount: items.length,
      eventCount: events.length,
    );
  }

  /// 저장소 버전을 한 단계씩 올린다. 모든 단계와 버전 갱신은 단일 트랜잭션이라
  /// 실패하면 아무것도 바뀌지 않고 다음 실행에서 다시 시도한다.
  static bool _upgradeIfNeeded(Isar store, StorageMetadata metadata) {
    if (metadata.storageVersion >= StorageMetadata.currentStorageVersion) {
      return false;
    }
    store.write((isar) {
      var version = metadata.storageVersion;
      if (version < 2) {
        _upgradeItemsToV2(isar);
        version = 2;
      }
      metadata.storageVersion = version;
      isar.storageMetadatas.put(metadata);
    });
    return true;
  }

  /// v1 → v2(#41·#45). 저장된 ordinal은 그대로 두고 의미만 옮긴다.
  /// - legacy 운동복은 상의/하의로 추정하지 않고 `미분류 + 용도 운동`으로 옮긴다.
  /// - careMode는 필드가 없던 구 데이터가 기본값 wearCycle로 읽히므로 기존
  ///   횟수 기반 동작이 유지된다. careMethod·카운터·상태는 바꾸지 않는다.
  static void _upgradeItemsToV2(Isar isar) {
    final legacy = isar.items
        .where()
        .categoryEqualTo(Category.activewear)
        .findAll();
    if (legacy.isEmpty) return;
    for (final item in legacy) {
      _normalizeLegacyActivewear(item);
    }
    isar.items.putAll(legacy);
  }

  static void _normalizeLegacyActivewear(Item item) {
    if (item.category != Category.activewear) return;
    item
      ..category = Category.uncategorized
      ..purposes = {...item.purposes, ItemPurpose.sport}.toList();
  }

  static void _validateSnapshot(LegacySnapshot snapshot) {
    final itemIds = snapshot.items.map((item) => item.id).toSet();
    if (itemIds.length != snapshot.items.length) {
      throw StateError('Legacy snapshot contains duplicate item IDs');
    }
    final eventIds = snapshot.events.map((event) => event.id).toSet();
    if (eventIds.length != snapshot.events.length) {
      throw StateError('Legacy snapshot contains duplicate event IDs');
    }
    for (final event in snapshot.events) {
      if (!itemIds.contains(event.itemId)) {
        throw StateError(
          'Legacy event ${event.id} references missing item ${event.itemId}',
        );
      }
    }
  }

  static Item _convertItem(LegacyItemData data) {
    final item = Item(
      name: data.name,
      brand: data.brand,
      category: _enumAt(Category.values, data.categoryIndex, 'category'),
      careMethod: _enumAt(
        CareMethod.values,
        data.careMethodIndex,
        'careMethod',
      ),
      status: _enumAt(ItemStatus.values, data.statusIndex, 'status'),
      washCycle: data.washCycle,
      wearSinceWash: data.wearSinceWash,
      totalWears: data.totalWears,
      lastWornAt: data.lastWornAt,
      lastWashedAt: data.lastWashedAt,
      purchasedAt: data.purchasedAt,
      inLaundry: data.inLaundry,
      imagePath: data.imagePath,
      fallbackColor: data.fallbackColor,
      createdAt: data.createdAt,
    )..id = data.id;
    // legacy 원본도 v2 의미로 바로 옮긴다(_upgradeItemsToV2와 같은 규칙).
    _normalizeLegacyActivewear(item);
    return item;
  }

  static WearEvent _convertEvent(LegacyWearEventData data) {
    return WearEvent(
      itemId: data.itemId,
      kind: _enumAt(EventKind.values, data.kindIndex, 'eventKind'),
      occurredAt: data.occurredAt,
      note: data.note,
    )..id = data.id;
  }

  static UserPreferences _convertPreferences(
    LegacyPreferencesData? data,
    DateTime now,
  ) {
    if (data == null) {
      return UserPreferences.defaults()..firstLaunchedAt = now;
    }
    return UserPreferences(
      notifWash: data.notifWash,
      notifWeekly: data.notifWeekly,
      notifUnworn: data.notifUnworn,
      accent: data.accent,
      lastTab: data.lastTab,
      firstLaunchedAt: data.firstLaunchedAt,
    )..id = UserPreferences.singletonId;
  }

  static T _enumAt<T>(List<T> values, int index, String field) {
    if (index < 0 || index >= values.length) {
      throw StateError('Legacy $field enum index is out of range: $index');
    }
    return values[index];
  }
}
