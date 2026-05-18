// contracts/repositories.md §3 — 착용·세탁 이벤트 기록 및 조회.

import '../models/wear_event.dart';

abstract interface class EventRepository {
  Stream<List<WearEvent>> watchForItem(int itemId);

  /// FR-010 → FR-011: wearSinceWash·totalWears 증가 + 자동 dirty 전이 +
  /// WearEvent(kind: wear) 1건을 단일 트랜잭션에 묶는다.
  Future<void> recordWear(int itemId);
}
