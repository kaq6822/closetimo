// US4 T063 — 세탁 바구니 일괄 완료 처리 검증.

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryLaundryRepo implements LaundryRepository {
  _InMemoryLaundryRepo(this.items);

  final Map<int, Item> items;
  final List<WearEvent> events = [];

  @override
  Stream<List<Item>> watchBasket() => Stream.value(
        items.values.where((i) => i.inLaundry).toList(),
      );

  @override
  Future<void> toggle(int itemId) async {
    final i = items[itemId];
    if (i != null) i.inLaundry = !i.inLaundry;
  }

  @override
  Future<void> completeWashFor(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    final now = DateTime(2026, 5, 19);
    for (final id in itemIds) {
      final i = items[id];
      if (i == null) continue;
      i
        ..status = ItemStatus.clean
        ..wearSinceWash = 0
        ..lastWashedAt = now
        ..inLaundry = false;
      events.add(WearEvent(
        itemId: id,
        kind: EventKind.wash,
        occurredAt: now,
      ));
    }
  }
}

Item _mk(int id, {int wearSinceWash = 3, int washCycle = 3, bool inLaundry = true}) {
  return Item(
    name: '옷 $id',
    category: Category.top,
    washCycle: washCycle,
    createdAt: DateTime(2026, 1, id),
  )
    ..id = id
    ..wearSinceWash = wearSinceWash
    ..status = ItemStatus.dirty
    ..inLaundry = inLaundry;
}

void main() {
  test('US4: 선택된 옷만 세탁 완료 → clean + 0/N로 초기화, 바구니 제거', () async {
    final repo = _InMemoryLaundryRepo({
      1: _mk(1),
      2: _mk(2),
      3: _mk(3),
    });

    // 3점 모두 바구니에 있는 초기 상태
    var basket = await repo.watchBasket().first;
    expect(basket.map((e) => e.id).toSet(), {1, 2, 3});

    // 1, 2번만 세탁 완료
    await repo.completeWashFor([1, 2]);

    // 1, 2번은 clean + 바구니 제거, 3번은 그대로
    expect(repo.items[1]!.status, ItemStatus.clean);
    expect(repo.items[1]!.wearSinceWash, 0);
    expect(repo.items[1]!.inLaundry, isFalse);
    expect(repo.items[2]!.status, ItemStatus.clean);
    expect(repo.items[3]!.status, ItemStatus.dirty);
    expect(repo.items[3]!.inLaundry, isTrue);

    // 세탁 이벤트 2건 기록
    expect(repo.events, hasLength(2));
    expect(repo.events.every((e) => e.kind == EventKind.wash), isTrue);

    basket = await repo.watchBasket().first;
    expect(basket.map((e) => e.id).toSet(), {3});
  });

  test('US4: 빈 ID 리스트는 무동작', () async {
    final repo = _InMemoryLaundryRepo({1: _mk(1)});
    await repo.completeWashFor([]);
    expect(repo.events, isEmpty);
    expect(repo.items[1]!.status, ItemStatus.dirty);
  });

  test('US4: toggle은 status를 변경하지 않는다', () async {
    final repo = _InMemoryLaundryRepo({1: _mk(1, inLaundry: false)});
    await repo.toggle(1);
    expect(repo.items[1]!.inLaundry, isTrue);
    expect(repo.items[1]!.status, ItemStatus.dirty); // 변화 없음
  });
}
