import 'package:isar/isar.dart';

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
        .filter()
        .inLaundryEqualTo(true)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<void> toggle(int itemId) async {
    await _isar.writeTxn(() async {
      final item = await _isar.items.get(itemId);
      if (item == null) return;
      item.inLaundry = !item.inLaundry;
      await _isar.items.put(item);
    });
  }

  @override
  Future<void> completeWashFor(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    final now = _clock.now();
    await _isar.writeTxn(() async {
      for (final id in itemIds) {
        final item = await _isar.items.get(id);
        if (item == null) continue;
        item
          ..status = ItemStatus.clean
          ..wearSinceWash = 0
          ..lastWashedAt = now
          ..inLaundry = false;
        await _isar.items.put(item);
        await _isar.wearEvents.put(WearEvent(
          itemId: id,
          kind: EventKind.wash,
          occurredAt: now,
        ));
      }
    });
  }
}
