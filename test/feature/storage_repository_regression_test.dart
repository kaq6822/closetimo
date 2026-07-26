import 'dart:io';

import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/data/repositories/isar_preferences_repository.dart';
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
  final now = DateTime.utc(2026, 7, 25, 15);

  setUpAll(initializeIsarPlusForTests);

  late Directory directory;
  late Isar isar;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('closetimo_repo_test');
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: directory.path,
      name: 'repository_regression',
      inspector: false,
    );
  });

  tearDown(() {
    if (isar.isOpen) {
      isar.close(deleteFromDisk: true);
    }
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('착용 누적과 세탁 완료가 파생 상태와 이벤트를 함께 갱신한다', () async {
    final item = Item(
      name: '테스트 셔츠',
      category: Category.top,
      washCycle: 2,
      createdAt: now,
    )..id = 7;
    isar.write((isar) => isar.items.put(item));

    final eventRepository = IsarEventRepository(
      isar: isar,
      clock: _FixedClock(now),
    );
    final laundryRepository = IsarLaundryRepository(
      isar: isar,
      clock: _FixedClock(now.add(const Duration(hours: 1))),
    );

    await eventRepository.recordWear(7, note: '  출근  ');
    await eventRepository.recordWear(7);

    var saved = isar.items.get(7)!;
    expect(saved.wearSinceWash, 2);
    expect(saved.totalWears, 2);
    expect(saved.status, ItemStatus.dirty);
    final wears = isar.wearEvents
        .where()
        .itemIdEqualTo(7)
        .kindEqualTo(EventKind.wear)
        .findAll();
    expect(wears, hasLength(2));
    expect(wears.first.note, '출근');

    await laundryRepository.toggle(7);
    expect(isar.items.get(7)!.inLaundry, isTrue);
    await laundryRepository.completeWashFor([7]);

    saved = isar.items.get(7)!;
    expect(saved.status, ItemStatus.clean);
    expect(saved.wearSinceWash, 0);
    expect(saved.totalWears, 2);
    expect(saved.inLaundry, isFalse);
    expect(isar.wearEvents.where().kindEqualTo(EventKind.wash).count(), 1);
  });

  test('설정 변경은 저장소를 다시 열어도 보존된다', () async {
    isar.write((isar) => isar.userPreferences.put(UserPreferences.defaults()));
    final repository = IsarPreferencesRepository(isar: isar);

    await repository.setNotifWash(false);
    await repository.setNotifWeekly(false);
    await repository.setNotifUnworn(true);
    await repository.setAccent('rose');
    await repository.setLastTab('settings');

    isar.close();
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: directory.path,
      name: 'repository_regression',
      inspector: false,
    );

    final saved = isar.userPreferences.get(UserPreferences.singletonId)!;
    expect(saved.notifWash, isFalse);
    expect(saved.notifWeekly, isFalse);
    expect(saved.notifUnworn, isTrue);
    expect(saved.accent, 'rose');
    expect(saved.lastTab, 'settings');
  });
}
