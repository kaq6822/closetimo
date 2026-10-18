// #53 — 옷 컬렉션 전체 watch는 구독자 수와 무관하게 한 번만 구독하고,
// 늦게 구독한 쪽도 마지막 값을 바로 받는다.

import 'dart:io';

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/shared_items_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

import '../support/isar_plus_test_support.dart';

Item _item(int id) => Item(
  name: '옷$id',
  category: Category.top,
  washCycle: 3,
  createdAt: DateTime(2026, 1, id),
)..id = id;

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 200));

void main() {
  setUpAll(initializeIsarPlusForTests);

  late Directory directory;
  late Isar isar;
  late SharedItemsWatcher watcher;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('closetimo_shared_watch');
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: directory.path,
      name: 'shared_watch',
      inspector: false,
    );
    watcher = SharedItemsWatcher(isar);
  });

  tearDown(() {
    if (isar.isOpen) isar.close(deleteFromDisk: true);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('구독자 모두 같은 변경을 받고 늦게 구독해도 마지막 값을 바로 받는다', () async {
    isar.write((isar) => isar.items.put(_item(1)));
    final a = <int>[];
    final b = <int>[];
    final subA = watcher.stream.listen((l) => a.add(l.length));
    await _settle();

    final subB = watcher.stream.listen((l) => b.add(l.length));
    await _settle();
    expect(b, [1], reason: '늦은 구독자는 마지막 값을 즉시 받는다');

    isar.write((isar) => isar.items.put(_item(2)));
    await _settle();
    expect(a.last, 2);
    expect(b.last, 2);

    await subA.cancel();
    await subB.cancel();
  });

  test('조건 밖으로 나가는 수정도 모든 구독자에게 전달된다', () async {
    isar.write((isar) => isar.items.put(_item(1)..inLaundry = true));
    final inBasket = <int>[];
    final all = <int>[];
    final sub1 = watcher.stream.listen(
      (l) => inBasket.add(l.where((i) => i.inLaundry).length),
    );
    final sub2 = watcher.stream.listen((l) => all.add(l.length));
    await _settle();

    isar.write((isar) => isar.items.put(_item(1)..inLaundry = false));
    await _settle();
    expect(inBasket.last, 0);
    expect(all.last, 1);

    await sub1.cancel();
    await sub2.cancel();
  });

  test('모든 구독이 끝나면 캐시를 버리고 다음 구독에서 최신 상태를 다시 읽는다', () async {
    isar.write((isar) => isar.items.put(_item(1)));
    final first = <int>[];
    final sub = watcher.stream.listen((l) => first.add(l.length));
    await _settle();
    await sub.cancel();

    isar.write((isar) => isar.items.put(_item(2)));
    final second = <int>[];
    final sub2 = watcher.stream.listen((l) => second.add(l.length));
    await _settle();
    expect(second.first, 2);
    await sub2.cancel();
  });
}
