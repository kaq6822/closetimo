import 'dart:io';

import 'package:closetimo_legacy_isar/closetimo_legacy_isar.dart';

/// iOS 업데이트 설치 검증용 Isar 3 fixture를 지정한 디렉토리에 만든다.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/create_legacy_fixture.dart <directory>',
    );
    exitCode = 64;
    return;
  }

  final directory = Directory(arguments.single)..createSync(recursive: true);
  await LegacyStore.initializeForTests();
  await LegacyStore.writeFixture(
    directory.path,
    LegacySnapshot(
      items: [
        LegacyItemData(
          id: 77,
          name: 'legacy-coat',
          brand: 'legacy-brand',
          categoryIndex: 0,
          careMethodIndex: 0,
          statusIndex: 1,
          washCycle: 3,
          wearSinceWash: 3,
          totalWears: 8,
          lastWornAt: DateTime.utc(2026, 7, 20, 9),
          lastWashedAt: DateTime.utc(2026, 7, 1, 9),
          purchasedAt: DateTime.utc(2025, 1, 1),
          inLaundry: true,
          imagePath: 'items/77.jpg',
          fallbackColor: 0xFF123456,
          createdAt: DateTime.utc(2025, 2, 1),
        ),
      ],
      events: [
        LegacyWearEventData(
          id: 701,
          itemId: 77,
          kindIndex: 0,
          occurredAt: DateTime.utc(2026, 7, 20, 9),
          note: 'legacy-note',
        ),
      ],
      preferences: LegacyPreferencesData(
        id: 0,
        notifWash: false,
        notifWeekly: false,
        notifUnworn: true,
        accent: 'rose',
        lastTab: 'wardrobe',
        firstLaunchedAt: DateTime.utc(2025, 4, 1),
      ),
    ),
  );
  stdout.writeln('${directory.path}/${LegacyStore.databaseName}.isar');
}
