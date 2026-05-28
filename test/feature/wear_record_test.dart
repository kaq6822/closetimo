// US3 T057/T078 — recordWear/updateEventNote/deleteWearEvent의 사이드이펙트.

import 'package:closetimo_app/data/models/item.dart';
import 'package:closetimo_app/data/models/wear_event.dart';
import 'package:closetimo_app/data/repositories/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryEventRepo implements EventRepository {
  _InMemoryEventRepo(this.items, {DateTime? clock})
      : _now = clock ?? DateTime(2026, 5, 19);

  final Map<int, Item> items;
  final List<WearEvent> events = [];
  DateTime _now;
  int _nextId = 1;

  static const int _noteMaxLength = 80;

  set now(DateTime value) => _now = value;

  String? _normalizeNote(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > _noteMaxLength) {
      throw ArgumentError.value(
        raw,
        'note',
        'note must be at most $_noteMaxLength characters',
      );
    }
    return trimmed;
  }

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) =>
      Stream.value(events.where((e) => e.itemId == itemId).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)));

  @override
  Future<void> recordWear(int itemId, {String? note}) async {
    final normalized = _normalizeNote(note);
    final item = items[itemId];
    if (item == null) return;
    item
      ..wearSinceWash += 1
      ..totalWears += 1
      ..lastWornAt = _now;
    if (item.wearSinceWash >= item.washCycle) {
      item.status = ItemStatus.dirty;
    }
    events.add(WearEvent(
      itemId: itemId,
      kind: EventKind.wear,
      occurredAt: _now,
      note: normalized,
    )..id = _nextId++);
  }

  @override
  Future<void> updateEventNote(int eventId, String? note) async {
    final normalized = _normalizeNote(note);
    final ev = events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw StateError('event not found'),
    );
    if (ev.kind != EventKind.wear) {
      throw StateError('updateEventNote only applies to wear events');
    }
    ev.note = normalized;
  }

  @override
  Future<void> deleteWearEvent(int eventId) async {
    final ev = events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw StateError('event not found'),
    );
    if (ev.kind != EventKind.wear) {
      throw StateError('deleteWearEvent only applies to wear events');
    }
    final itemId = ev.itemId;
    events.removeWhere((e) => e.id == eventId);

    final item = items[itemId];
    if (item == null) return;
    item
      ..wearSinceWash =
          item.wearSinceWash > 0 ? item.wearSinceWash - 1 : 0
      ..totalWears = item.totalWears > 0 ? item.totalWears - 1 : 0;
    final remaining = events
        .where((e) => e.itemId == itemId && e.kind == EventKind.wear)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    item.lastWornAt = remaining.isEmpty ? null : remaining.first.occurredAt;
    if (item.status == ItemStatus.dirty &&
        item.wearSinceWash < item.washCycle) {
      item.status = ItemStatus.clean;
    }
  }
}

void main() {
  test('US3 AC1: recordWear가 카운터 증가 + 자동 dirty 전이', () async {
    final item = Item(
      name: '캐시미어 니트',
      category: Category.top,
      washCycle: 3,
      createdAt: DateTime(2026, 1, 1),
    )..id = 1;
    final repo = _InMemoryEventRepo({1: item});

    await repo.recordWear(1);
    expect(item.wearSinceWash, 1);
    expect(item.totalWears, 1);
    expect(item.status, ItemStatus.clean);

    await repo.recordWear(1);
    expect(item.wearSinceWash, 2);
    expect(item.status, ItemStatus.clean);

    await repo.recordWear(1);
    expect(item.wearSinceWash, 3);
    expect(item.totalWears, 3);
    expect(item.status, ItemStatus.dirty);

    final history = await repo.watchForItem(1).first;
    expect(history, hasLength(3));
    expect(history.every((e) => e.kind == EventKind.wear), isTrue);
    expect(history.every((e) => e.note == null), isTrue);
  });

  test('US3 AC3: 세탁 주기 1인 옷은 1회 착용 즉시 dirty', () async {
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

  test('US3 AC2: recordWear가 note를 저장하고 trim/빈 입력을 null로 정규화', () async {
    final item = Item(
      name: '데님 자켓',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 2;
    final repo = _InMemoryEventRepo({2: item});

    repo.now = DateTime(2026, 5, 19);
    await repo.recordWear(2, note: '오피스 미팅, 따뜻함');
    repo.now = DateTime(2026, 5, 20);
    await repo.recordWear(2, note: '   ');
    repo.now = DateTime(2026, 5, 21);
    await repo.recordWear(2, note: '');
    repo.now = DateTime(2026, 5, 22);
    await repo.recordWear(2);

    // watchForItem은 occurredAt DESC 정렬 — 최신이 [0]
    final events = await repo.watchForItem(2).first;
    expect(events, hasLength(4));
    expect(events[0].note, isNull);
    expect(events[1].note, isNull);
    expect(events[2].note, isNull);
    expect(events[3].note, '오피스 미팅, 따뜻함');
  });

  test('80자 초과 note는 ArgumentError로 거부되고 카운터도 변동 없음', () async {
    final item = Item(
      name: '롱코트',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 3;
    final repo = _InMemoryEventRepo({3: item});

    expect(
      () => repo.recordWear(3, note: 'a' * 81),
      throwsArgumentError,
    );
    expect(item.totalWears, 0);
  });

  test('US3 AC6: updateEventNote는 메모만 갱신하고 Item 카운터는 그대로', () async {
    final item = Item(
      name: '울 자켓',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 4;
    final repo = _InMemoryEventRepo({4: item});

    await repo.recordWear(4, note: '오피스 미팅');
    final ev = (await repo.watchForItem(4).first).single;

    await repo.updateEventNote(ev.id, '외부 행사, 약간 더웠음');

    expect(item.wearSinceWash, 1);
    expect(item.totalWears, 1);
    final updated = (await repo.watchForItem(4).first).single;
    expect(updated.note, '외부 행사, 약간 더웠음');
  });

  test('updateEventNote가 wash 이벤트에 대해 StateError를 던진다', () async {
    final item = Item(
      name: '캐시미어 코트',
      category: Category.outer,
      washCycle: 3,
      createdAt: DateTime(2026, 1, 1),
    )..id = 5;
    final repo = _InMemoryEventRepo({5: item});
    final washEvent = WearEvent(
      itemId: 5,
      kind: EventKind.wash,
      occurredAt: DateTime(2026, 5, 1),
    )..id = 100;
    repo.events.add(washEvent);

    expect(
      () => repo.updateEventNote(100, '시도'),
      throwsStateError,
    );
  });

  test('US3 AC7: deleteWearEvent가 카운터 -1 + lastWornAt 재계산 + dirty→clean 복귀',
      () async {
    final item = Item(
      name: '런닝 셔츠',
      category: Category.activewear,
      washCycle: 2,
      createdAt: DateTime(2026, 1, 1),
    )..id = 6;
    final repo = _InMemoryEventRepo({6: item});

    repo.now = DateTime(2026, 5, 1);
    await repo.recordWear(6);
    repo.now = DateTime(2026, 5, 5);
    await repo.recordWear(6); // 임계 도달 → dirty

    expect(item.status, ItemStatus.dirty);
    expect(item.wearSinceWash, 2);
    expect(item.lastWornAt, DateTime(2026, 5, 5));

    final latest = (await repo.watchForItem(6).first).first; // 5/5
    await repo.deleteWearEvent(latest.id);

    expect(item.wearSinceWash, 1);
    expect(item.totalWears, 1);
    expect(item.status, ItemStatus.clean); // 자동 복귀
    expect(item.lastWornAt, DateTime(2026, 5, 1)); // 남은 wear의 최신값
  });

  test('마지막 wear 이벤트를 삭제하면 lastWornAt이 null', () async {
    final item = Item(
      name: '면 티셔츠',
      category: Category.top,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 8;
    final repo = _InMemoryEventRepo({8: item});

    await repo.recordWear(8);
    final ev = (await repo.watchForItem(8).first).single;
    await repo.deleteWearEvent(ev.id);

    expect(item.wearSinceWash, 0);
    expect(item.totalWears, 0);
    expect(item.lastWornAt, isNull);
    expect((await repo.watchForItem(8).first), isEmpty);
  });

  test('카운터가 0인 상태에서 deleteWearEvent를 호출해도 음수가 되지 않는다', () async {
    final item = Item(
      name: '울 머플러',
      category: Category.accessory,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 9;
    final repo = _InMemoryEventRepo({9: item});

    // 카운터를 0으로 둔 채 이벤트만 직접 주입(데이터 불일치 시나리오 가드)
    final ev = WearEvent(
      itemId: 9,
      kind: EventKind.wear,
      occurredAt: DateTime(2026, 5, 1),
    )..id = 200;
    repo.events.add(ev);

    await repo.deleteWearEvent(200);
    expect(item.wearSinceWash, 0);
    expect(item.totalWears, 0);
  });

  test('deleteWearEvent가 wash 이벤트에 대해 StateError를 던진다', () async {
    final item = Item(
      name: '플리스',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 10;
    final repo = _InMemoryEventRepo({10: item});
    final washEvent = WearEvent(
      itemId: 10,
      kind: EventKind.wash,
      occurredAt: DateTime(2026, 5, 1),
    )..id = 300;
    repo.events.add(washEvent);

    expect(
      () => repo.deleteWearEvent(300),
      throwsStateError,
    );
  });
}
