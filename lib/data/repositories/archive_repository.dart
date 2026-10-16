// contracts/repositories.md §2a — 옷 보관·복원(#44).
// LaundryRepository가 Item.inLaundry를 다루듯 Item.archivedAt·archiveReason을 다룬다.

import '../models/item.dart';

abstract interface class ArchiveRepository {
  /// 보관한 옷만 최근 보관 순으로 내보낸다(보관함 화면).
  Stream<List<Item>> watchArchived();

  /// 옷을 보관한다. `archivedAt = now`, `archiveReason = reason`으로 기록하고
  /// 세탁 바구니에서 뺀다(`inLaundry = false`). 착용·세탁 기록, 카운터, 상태,
  /// 사진은 그대로 둔다. 이미 보관한 옷이면 보관 시각은 유지하고 사유만 바꾼다.
  /// `itemId` 미존재 시 no-op.
  Future<void> archive(
    int itemId, {
    ArchiveReason reason = ArchiveReason.unspecified,
  });

  /// 보관을 해제해 활성 옷장으로 되돌린다. `archivedAt = null`,
  /// `archiveReason = unspecified`. 기록·카운터·상태는 보관 전 그대로이며
  /// 바구니에는 자동으로 다시 담지 않는다. `itemId` 미존재 시 no-op.
  Future<void> restore(int itemId);
}
