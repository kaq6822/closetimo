import 'dart:io';

import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/migrations/storage_migrator.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/storage_metadata.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo_legacy_isar/closetimo_legacy_isar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

import '../support/isar_plus_test_support.dart';

class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final migratedAt = _FixedClock(DateTime.utc(2026, 7, 25, 12));

  setUpAll(() async {
    await initializeIsarPlusForTests();
    await LegacyStore.initializeForTests();
  });

  late Directory directory;
  late Isar newStore;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('closetimo_migration_test');
    newStore = Isar.open(
      schemas: [
        ItemSchema,
        WearEventSchema,
        UserPreferencesSchema,
        StorageMetadataSchema,
      ],
      directory: directory.path,
      name: 'closetimo_plus_test',
      inspector: false,
    );
  });

  tearDown(() {
    if (newStore.isOpen) {
      newStore.close(deleteFromDisk: true);
    }
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('실제 Isar 3 데이터를 모든 값과 ID를 보존해 한 번만 이전한다', () async {
    final createdAt = DateTime.utc(2025, 1, 2, 3, 4);
    final wornAt = DateTime.utc(2026, 7, 1, 9);
    final washedAt = DateTime.utc(2026, 6, 20, 10);
    final purchasedAt = DateTime.utc(2024, 12, 31);
    final launchedAt = DateTime.utc(2025, 4, 1);
    final snapshot = LegacySnapshot(
      items: [
        LegacyItemData(
          id: 41,
          name: '리넨 재킷',
          brand: 'Closetimo',
          categoryIndex: Category.outer.index,
          careMethodIndex: CareMethod.dryClean.index,
          statusIndex: ItemStatus.dirty.index,
          washCycle: 4,
          wearSinceWash: 5,
          totalWears: 12,
          lastWornAt: wornAt,
          lastWashedAt: washedAt,
          purchasedAt: purchasedAt,
          inLaundry: true,
          imagePath: 'items/41.jpg',
          fallbackColor: 0xFF123456,
          createdAt: createdAt,
        ),
        LegacyItemData(
          id: 99,
          name: '흰 셔츠',
          categoryIndex: Category.top.index,
          careMethodIndex: CareMethod.machine.index,
          statusIndex: ItemStatus.clean.index,
          washCycle: 2,
          wearSinceWash: 0,
          totalWears: 1,
          inLaundry: false,
          fallbackColor: 0xFFE5E4DC,
          createdAt: createdAt.add(const Duration(days: 1)),
        ),
      ],
      events: [
        LegacyWearEventData(
          id: 301,
          itemId: 41,
          kindIndex: EventKind.wear.index,
          occurredAt: wornAt,
          note: '저녁 약속',
        ),
        LegacyWearEventData(
          id: 302,
          itemId: 41,
          kindIndex: EventKind.wash.index,
          occurredAt: washedAt,
        ),
      ],
      preferences: LegacyPreferencesData(
        id: 0,
        notifWash: false,
        notifWeekly: true,
        notifUnworn: true,
        accent: 'rose',
        lastTab: 'laundry',
        firstLaunchedAt: launchedAt,
      ),
    );
    await LegacyStore.writeFixture(directory.path, snapshot);

    const migrator = StorageMigrator();
    final first = await migrator.migrateIfNeeded(
      newStore: newStore,
      directory: directory.path,
      clock: migratedAt,
    );
    final second = await migrator.migrateIfNeeded(
      newStore: newStore,
      directory: directory.path,
      clock: migratedAt,
    );

    expect(first.source, MigrationSource.legacyV3);
    expect(first.itemCount, 2);
    expect(first.eventCount, 2);
    expect(second.source, MigrationSource.alreadyMigrated);
    expect(newStore.items.count(), 2);
    expect(newStore.wearEvents.count(), 2);

    final item = newStore.items.get(41)!;
    expect(item.name, '리넨 재킷');
    expect(item.brand, 'Closetimo');
    expect(item.category, Category.outer);
    expect(item.careMethod, CareMethod.dryClean);
    expect(item.status, ItemStatus.dirty);
    expect(item.washCycle, 4);
    expect(item.wearSinceWash, 5);
    expect(item.totalWears, 12);
    expect(item.lastWornAt?.toUtc(), wornAt);
    expect(item.lastWashedAt?.toUtc(), washedAt);
    expect(item.purchasedAt?.toUtc(), purchasedAt);
    expect(item.inLaundry, isTrue);
    expect(item.imagePath, 'items/41.jpg');
    expect(item.fallbackColor, 0xFF123456);
    expect(item.createdAt.toUtc(), createdAt);

    final event = newStore.wearEvents.get(301)!;
    expect(event.itemId, 41);
    expect(event.kind, EventKind.wear);
    expect(event.occurredAt.toUtc(), wornAt);
    expect(event.note, '저녁 약속');

    final preferences = newStore.userPreferences.get(
      UserPreferences.singletonId,
    )!;
    expect(preferences.notifWash, isFalse);
    expect(preferences.notifWeekly, isTrue);
    expect(preferences.notifUnworn, isTrue);
    expect(preferences.accent, 'rose');
    expect(preferences.lastTab, 'laundry');
    expect(preferences.firstLaunchedAt?.toUtc(), launchedAt);

    final metadata = newStore.storageMetadatas.get(
      StorageMetadata.singletonId,
    )!;
    expect(metadata.storageVersion, StorageMetadata.currentStorageVersion);
    expect(metadata.source, StorageSource.legacyV3);
    expect(metadata.legacyItemCount, 2);
    expect(metadata.legacyEventCount, 2);
    expect(metadata.migratedAt.toUtc(), migratedAt.value);
    expect(LegacyStore.exists(directory.path), isTrue);
  });

  test('legacy 파일이 없으면 기본 설정과 fresh 표식을 만든다', () async {
    final result = await const StorageMigrator().migrateIfNeeded(
      newStore: newStore,
      directory: directory.path,
      clock: migratedAt,
    );

    expect(result.source, MigrationSource.fresh);
    expect(newStore.items.count(), 0);
    expect(newStore.wearEvents.count(), 0);
    final preferences = newStore.userPreferences.get(
      UserPreferences.singletonId,
    )!;
    expect(preferences.firstLaunchedAt?.toUtc(), migratedAt.value);
    expect(
      newStore.storageMetadatas.get(StorageMetadata.singletonId)!.source,
      StorageSource.fresh,
    );
  });

  test('잘못된 관계는 부분 기록 없이 실패하고 올바른 snapshot으로 재시도한다', () async {
    final invalid = LegacySnapshot(
      items: const [],
      events: [
        LegacyWearEventData(
          id: 1,
          itemId: 404,
          kindIndex: EventKind.wear.index,
          occurredAt: migratedAt.value,
        ),
      ],
    );
    final invalidMigrator = StorageMigrator(
      readLegacySnapshot: (_) async => invalid,
    );

    await expectLater(
      invalidMigrator.migrateIfNeeded(
        newStore: newStore,
        directory: directory.path,
        clock: migratedAt,
      ),
      throwsStateError,
    );
    expect(newStore.items.count(), 0);
    expect(newStore.wearEvents.count(), 0);
    expect(newStore.storageMetadatas.get(StorageMetadata.singletonId), isNull);

    final valid = LegacySnapshot(
      items: [
        LegacyItemData(
          id: 404,
          name: '복구된 옷',
          categoryIndex: Category.etc.index,
          careMethodIndex: CareMethod.handWash.index,
          statusIndex: ItemStatus.clean.index,
          washCycle: 1,
          wearSinceWash: 0,
          totalWears: 0,
          inLaundry: false,
          fallbackColor: 0,
          createdAt: migratedAt.value,
        ),
      ],
      events: invalid.events,
    );
    final retried =
        await StorageMigrator(
          readLegacySnapshot: (_) async => valid,
        ).migrateIfNeeded(
          newStore: newStore,
          directory: directory.path,
          clock: migratedAt,
        );

    expect(retried.source, MigrationSource.legacyV3);
    expect(newStore.items.get(404), isNotNull);
    expect(newStore.wearEvents.get(1)!.itemId, 404);
  });
}
