import 'package:isar_plus/isar_plus.dart';

import '../../core/utils/clock.dart';
import '../models/item.dart';
import '../models/wear_event.dart';
import 'laundry_repository.dart';
import 'shared_items_watcher.dart';

class IsarLaundryRepository implements LaundryRepository {
  IsarLaundryRepository({
    required Isar isar,
    required Clock clock,
    SharedItemsWatcher? watcher,
  }) : _isar = isar,
       _clock = clock,
       _watcher = watcher ?? SharedItemsWatcher(isar);

  final Isar _isar;
  final Clock _clock;
  final SharedItemsWatcher _watcher;

  @override
  Stream<List<Item>> watchBasket() {
    // Isar Plus는 인덱스 조건 쿼리(inLaundryEqualTo)를 watch할 때 옷이 조건 밖으로
    // 나가는 수정(세탁 완료·바구니 제외)을 방출하지 않는다. 전체 옷을 구독하고
    // 조건은 Dart에서 거른다(`isar_item_repository.watchAll`과 같은 방식).
    return _watcher.stream.map(
      (all) => [
        for (final i in all)
          if (i.inLaundry && !i.isArchived) i,
      ],
    );
  }

  @override
  Future<void> toggle(int itemId) async {
    _isar.write((isar) {
      final item = isar.items.get(itemId);
      if (item == null) return;
      // 보관한 옷은 바구니에 담지 않는다(#44). 담겨 있던 값을 빼는 것은 허용.
      if (item.isArchived && !item.inLaundry) return;
      item.inLaundry = !item.inLaundry;
      isar.items.put(item);
    });
  }

  @override
  Future<int> completeWashFor(List<int> itemIds) async {
    if (itemIds.isEmpty) return 0;
    final now = _clock.now();
    return _isar.write((isar) {
      var processed = 0;
      for (final id in itemIds.toSet()) {
        final item = isar.items.get(id);
        // 바구니에 없는 옷은 세탁 완료 대상이 아니다.
        if (item == null || !item.inLaundry) continue;
        item
          ..status = ItemStatus.clean
          ..wearSinceWash = 0
          ..lastWashedAt = now
          ..inLaundry = false;
        isar.items.put(item);
        final event = WearEvent(
          itemId: id,
          kind: EventKind.wash,
          occurredAt: now,
        )..id = isar.wearEvents.autoIncrement();
        isar.wearEvents.put(event);
        processed++;
      }
      return processed;
    });
  }
}
