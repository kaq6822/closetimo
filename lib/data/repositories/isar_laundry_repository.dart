import 'package:isar_plus/isar_plus.dart';

import '../../core/utils/clock.dart';
import '../models/item.dart';
import '../models/wear_event.dart';
import 'laundry_repository.dart';

class IsarLaundryRepository implements LaundryRepository {
  IsarLaundryRepository({required Isar isar, required Clock clock})
    : _isar = isar,
      _clock = clock;

  final Isar _isar;
  final Clock _clock;

  @override
  Stream<List<Item>> watchBasket() {
    return _isar.items
        .where()
        .inLaundryEqualTo(true)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<void> toggle(int itemId) async {
    _isar.write((isar) {
      final item = isar.items.get(itemId);
      if (item == null) return;
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
