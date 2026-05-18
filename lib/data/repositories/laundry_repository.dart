// contracts/repositories.md §2 — 세탁 바구니 토글 및 일괄 세탁 완료.

import '../models/item.dart';

abstract interface class LaundryRepository {
  Stream<List<Item>> watchBasket();

  /// FR-012 — Item.inLaundry 반전. status는 변경하지 않는다.
  Future<void> toggle(int itemId);

  /// FR-016 — 선택된 옷들을 status=clean, wearSinceWash=0,
  /// lastWashedAt=now, inLaundry=false로 갱신 + WearEvent(kind: wash) 기록.
  Future<void> completeWashFor(List<int> itemIds);
}
