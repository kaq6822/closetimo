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
  Future<void> completeWashFor(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    final now = _clock.now();
    _isar.write((isar) {
      for (final id in itemIds) {
        final item = isar.items.get(id);
        if (item == null) continue;
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
      }
    });
  }
}
