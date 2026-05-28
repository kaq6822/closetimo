// contracts/repositories.md §3 — 착용·세탁 이벤트 기록 및 조회.

import '../models/wear_event.dart';

abstract interface class EventRepository {
  Stream<List<WearEvent>> watchForItem(int itemId);

  /// FR-010 → FR-011: wearSinceWash·totalWears 증가 + 자동 dirty 전이 +
  /// `WearEvent(kind: wear, note: ...)` 1건을 단일 트랜잭션에 묶는다.
  ///
  /// [note]는 단일행 ≤80자. 빈 문자열 또는 공백만으로 채워진 입력은 `null`로
  /// 정규화된다. 길이 초과 시 [ArgumentError].
  Future<void> recordWear(int itemId, {String? note});

  /// FR-010a: 기존 wear 이벤트의 메모 본문만 갱신한다. Item의 카운터·상태·날짜는
  /// 변경되지 않으며, `kind == wash` 이벤트에 대한 호출은 [StateError]로 거부한다.
  Future<void> updateEventNote(int eventId, String? note);

  /// FR-010b: wear 이벤트 1건을 삭제하면서 Item의 사이드이펙트를 단일 트랜잭션으로
  /// 역적용한다. `wearSinceWash`·`totalWears`를 각각 `max(0, x-1)`로 감소시키고,
  /// `lastWornAt`을 남은 wear 이벤트 중 최신 `occurredAt`(없으면 `null`)으로 재계산하며,
  /// `wearSinceWash < washCycle`이 되면 `dirty → clean`으로 자동 복귀시킨다.
  /// `inLaundry`는 변경하지 않는다. `kind == wash` 이벤트 삭제는 본 릴리스 범위 외
  /// ([StateError]).
  Future<void> deleteWearEvent(int eventId);
}
