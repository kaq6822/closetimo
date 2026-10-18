// contracts/repositories.md §3 — 착용·세탁 이벤트 기록 및 조회.

import '../models/wear_event.dart';

/// 여러 벌 일괄 착용 기록(FR-008c)의 결과.
class WearBatchResult {
  const WearBatchResult({required this.eventIds, required this.skipped});

  /// 생성된 wear 이벤트 id(입력 순서). 실행 취소(FR-010e)에 그대로 넘긴다.
  final List<int> eventIds;

  /// 중복 id·보관한 옷·존재하지 않는 옷이라 건너뛴 수.
  final int skipped;

  int get recorded => eventIds.length;
}

abstract interface class EventRepository {
  Stream<List<WearEvent>> watchForItem(int itemId);

  /// FR-010 → FR-011: 카운터 갱신 + 상태 재계산 + `WearEvent(kind: wear, note: ...)`
  /// 1건을 단일 트랜잭션에 묶고, 생성한 이벤트 id를 돌려준다(옷이 없으면 `null`).
  ///
  /// [wornOn]은 착용 날짜(달력 날짜, 기본 오늘)이며 FR-010d 규칙으로 시각을
  /// 정하고 현재 세탁 주기 소속을 판정한다. 미래 날짜는 [ArgumentError].
  /// [note]는 단일행 ≤80자. 빈 문자열 또는 공백만으로 채워진 입력은 `null`로
  /// 정규화된다. 길이 초과 시 [ArgumentError].
  Future<int?> recordWear(int itemId, {String? note, DateTime? wornOn});

  /// FR-008c(#39): [itemIds]에 같은 날짜·메모의 착용 기록을 단일 트랜잭션으로
  /// 일괄 생성한다. 중복 id·보관한 옷·존재하지 않는 옷은 건너뛴다.
  Future<WearBatchResult> recordWearBatch(
    Iterable<int> itemIds, {
    DateTime? wornOn,
    String? note,
  });

  /// FR-010a: 기존 wear 이벤트의 메모 본문만 갱신한다. Item의 카운터·상태·날짜는
  /// 변경되지 않으며, `kind == wash` 이벤트에 대한 호출은 [StateError]로 거부한다.
  Future<void> updateEventNote(int eventId, String? note);

  /// FR-010c(#39): wear 이벤트의 착용 날짜를 [wornOn]으로 바꾸고 현재 세탁 주기
  /// 소속 변화에 맞춰 `wearSinceWash`·`lastWornAt`·`status`를 재계산한다.
  /// 같은 날짜면 no-op, 미래 날짜는 [ArgumentError], wash 이벤트는 [StateError].
  Future<void> updateWearDate(int eventId, DateTime wornOn);

  /// FR-010b: wear 이벤트 1건을 삭제하면서 Item의 사이드이펙트를 단일 트랜잭션으로
  /// 역적용한다. `totalWears`를 `max(0, x-1)`로, 현재 세탁 주기의 기록이면
  /// `wearSinceWash`도 `max(0, x-1)`로 감소시키고, `lastWornAt`을 남은 wear 이벤트 중
  /// 최신 `occurredAt`(없으면 `null`)으로 재계산하며, `status`를 `derivedStatus`로
  /// 재평가한다. `inLaundry`는 변경하지 않는다. `kind == wash` 이벤트 삭제는 본
  /// 릴리스 범위 외([StateError]).
  Future<void> deleteWearEvent(int eventId);

  /// FR-010e(#39): 착용 기록 직후 실행 취소. 각 이벤트에 [deleteWearEvent]와 같은
  /// 역적용을 단일 트랜잭션으로 수행하며, 없는 id·wash 이벤트는 건너뛴다.
  Future<void> deleteWearEvents(Iterable<int> eventIds);
}
