// US3 T057 — 착용 기록 골든 패스: recordWear가 카운터 증가 + 자동 dirty 전이.

import 'package:closetimo_app/data/models/item.dart';
import 'package:closetimo_app/data/models/wear_event.dart';
import 'package:closetimo_app/data/repositories/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryEventRepo implements EventRepository {
  _InMemoryEventRepo(this.items);

  final Map<int, Item> items;
  final List<WearEvent> events = [];

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) =>
      Stream.value(events.where((e) => e.itemId == itemId).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)));

  @override
  Future<void> recordWear(int itemId) async {
    final item = items[itemId];
    if (item == null) return;
    item
      ..wearSinceWash += 1
      ..totalWears += 1
      ..lastWornAt = DateTime(2026, 5, 19);
    if (item.wearSinceWash >= item.washCycle) {
      item.status = ItemStatus.dirty;
    }
    events.add(WearEvent(
      itemId: itemId,
      kind: EventKind.wear,
      occurredAt: DateTime(2026, 5, 19),
    ));
  }
}

void main() {
  test('US3: recordWear가 카운터 증가 + 자동 dirty 전이', () async {
    final item = Item(
      name: '캐시미어 니트',
      category: Category.top,
      washCycle: 3,
      createdAt: DateTime(2026, 1, 1),
    )..id = 1;
    final repo = _InMemoryEventRepo({1: item});

    // 1회: 2/3, clean 유지
    await repo.recordWear(1);
    expect(item.wearSinceWash, 1);
    expect(item.totalWears, 1);
    expect(item.status, ItemStatus.clean);

    // 2회: 2/3, clean 유지
    await repo.recordWear(1);
    expect(item.wearSinceWash, 2);
    expect(item.status, ItemStatus.clean);

    // 3회: 3/3 도달 → dirty 전이
    await repo.recordWear(1);
    expect(item.wearSinceWash, 3);
    expect(item.totalWears, 3);
    expect(item.status, ItemStatus.dirty);

    // 이벤트 3건 기록
    final history = await repo.watchForItem(1).first;
    expect(history, hasLength(3));
    expect(history.every((e) => e.kind == EventKind.wear), isTrue);
  });

  test('US3: 세탁 주기 1인 옷은 1회 착용 즉시 dirty', () async {
    final item = Item(
      name: '실크 블라우스',
      category: Category.top,
      washCycle: 1,
      createdAt: DateTime(2026, 1, 1),
    )..id = 7;
    final repo = _InMemoryEventRepo({7: item});

    await repo.recordWear(7);
    expect(item.status, ItemStatus.dirty);
    expect(item.wearSinceWash, 1);
  });
}
