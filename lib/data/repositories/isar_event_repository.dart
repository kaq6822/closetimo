import 'package:isar/isar.dart';

import '../../core/utils/clock.dart';
import '../models/item.dart';
import '../models/wear_event.dart';
import 'event_repository.dart';

class IsarEventRepository implements EventRepository {
  IsarEventRepository({required Isar isar, required Clock clock})
      : _isar = isar,
        _clock = clock;

  final Isar _isar;
  final Clock _clock;

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) {
    return _isar.wearEvents
        .filter()
        .itemIdEqualTo(itemId)
        .sortByOccurredAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<void> recordWear(int itemId) async {
    final now = _clock.now();
    await _isar.writeTxn(() async {
      final item = await _isar.items.get(itemId);
      if (item == null) return;
      item
        ..wearSinceWash += 1
        ..totalWears += 1
        ..lastWornAt = now;
      if (item.wearSinceWash >= item.washCycle) {
        item.status = ItemStatus.dirty;
      }
      await _isar.items.put(item);
      await _isar.wearEvents.put(WearEvent(
        itemId: itemId,
        kind: EventKind.wear,
        occurredAt: now,
      ));
    });
  }
}
