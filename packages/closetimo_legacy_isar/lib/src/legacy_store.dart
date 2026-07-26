import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import 'legacy_snapshot.dart';
import 'models/item.dart';
import 'models/user_preferences.dart';
import 'models/wear_event.dart';

/// 옷장이모의 Isar 3 저장소를 읽기 전용으로 여는 전환 브리지다.
abstract final class LegacyStore {
  static const String databaseName = 'closetimo';

  /// Dart VM 테스트와 fixture 도구에서 구형 native core를 준비한다.
  static Future<void> initializeForTests() {
    return Isar.initializeIsarCore(download: true);
  }

  /// 구형 데이터베이스 파일이 존재하는지 확인한다.
  static bool exists(String directory) {
    return File(p.join(directory, '$databaseName.isar')).existsSync();
  }

  /// 구형 저장소가 있으면 모든 collection을 값 snapshot으로 읽는다.
  static Future<LegacySnapshot?> readSnapshot(String directory) async {
    if (!exists(directory)) return null;

    final isar = await Isar.open(
      [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: directory,
      name: databaseName,
      inspector: false,
    );
    try {
      final items = await isar.items.where().findAll();
      final events = await isar.wearEvents.where().findAll();
      final preferences =
          await isar.userPreferences.get(UserPreferences.singletonId);
      return LegacySnapshot(
        items: items
            .map(
              (item) => LegacyItemData(
                id: item.id,
                name: item.name,
                brand: item.brand,
                categoryIndex: item.category.index,
                careMethodIndex: item.careMethod.index,
                statusIndex: item.status.index,
                washCycle: item.washCycle,
                wearSinceWash: item.wearSinceWash,
                totalWears: item.totalWears,
                lastWornAt: item.lastWornAt,
                lastWashedAt: item.lastWashedAt,
                purchasedAt: item.purchasedAt,
                inLaundry: item.inLaundry,
                imagePath: item.imagePath,
                fallbackColor: item.fallbackColor,
                createdAt: item.createdAt,
              ),
            )
            .toList(growable: false),
        events: events
            .map(
              (event) => LegacyWearEventData(
                id: event.id,
                itemId: event.itemId,
                kindIndex: event.kind.index,
                occurredAt: event.occurredAt,
                note: event.note,
              ),
            )
            .toList(growable: false),
        preferences: preferences == null
            ? null
            : LegacyPreferencesData(
                id: preferences.id,
                notifWash: preferences.notifWash,
                notifWeekly: preferences.notifWeekly,
                notifUnworn: preferences.notifUnworn,
                accent: preferences.accent,
                lastTab: preferences.lastTab,
                firstLaunchedAt: preferences.firstLaunchedAt,
              ),
      );
    } finally {
      await isar.close();
    }
  }

  /// 실제 Isar 3 파일을 사용하는 이전 테스트 fixture를 만든다.
  static Future<void> writeFixture(
    String directory,
    LegacySnapshot snapshot,
  ) async {
    final isar = await Isar.open(
      [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: directory,
      name: databaseName,
      inspector: false,
    );
    try {
      await isar.writeTxn(() async {
        await isar.items.putAll(
          snapshot.items
              .map(
                (data) => Item(
                  name: data.name,
                  brand: data.brand,
                  category: Category.values[data.categoryIndex],
                  careMethod: CareMethod.values[data.careMethodIndex],
                  status: ItemStatus.values[data.statusIndex],
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
                )..id = data.id,
              )
              .toList(growable: false),
        );
        await isar.wearEvents.putAll(
          snapshot.events
              .map(
                (data) => WearEvent(
                  itemId: data.itemId,
                  kind: EventKind.values[data.kindIndex],
                  occurredAt: data.occurredAt,
                  note: data.note,
                )..id = data.id,
              )
              .toList(growable: false),
        );
        final preferences = snapshot.preferences;
        if (preferences != null) {
          await isar.userPreferences.put(
            UserPreferences(
              notifWash: preferences.notifWash,
              notifWeekly: preferences.notifWeekly,
              notifUnworn: preferences.notifUnworn,
              accent: preferences.accent,
              lastTab: preferences.lastTab,
              firstLaunchedAt: preferences.firstLaunchedAt,
            )..id = preferences.id,
          );
        }
      });
    } finally {
      await isar.close();
    }
  }
}
