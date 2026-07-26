import 'package:isar_plus/isar_plus.dart';

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

  static const int _noteMaxLength = 80;

  String? _normalizeNote(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > _noteMaxLength) {
      throw ArgumentError.value(
        raw,
        'note',
        'note must be at most $_noteMaxLength characters',
      );
    }
    return trimmed;
  }

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) {
    return _isar.wearEvents
        .where()
        .itemIdEqualTo(itemId)
        .sortByOccurredAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<void> recordWear(int itemId, {String? note}) async {
    final normalized = _normalizeNote(note);
    final now = _clock.now();
    _isar.write((isar) {
      final item = isar.items.get(itemId);
      if (item == null) return;
      item
        ..wearSinceWash += 1
        ..totalWears += 1
        ..lastWornAt = now;
      if (item.wearSinceWash >= item.washCycle) {
        item.status = ItemStatus.dirty;
      }
      isar.items.put(item);
      final event = WearEvent(
        itemId: itemId,
        kind: EventKind.wear,
        occurredAt: now,
        note: normalized,
      )..id = isar.wearEvents.autoIncrement();
      isar.wearEvents.put(event);
    });
  }

  @override
  Future<void> updateEventNote(int eventId, String? note) async {
    final normalized = _normalizeNote(note);
    _isar.write((isar) {
      final ev = isar.wearEvents.get(eventId);
      if (ev == null) return;
      if (ev.kind != EventKind.wear) {
        throw StateError('updateEventNote only applies to wear events');
      }
      ev.note = normalized;
      isar.wearEvents.put(ev);
    });
  }

  @override
  Future<void> deleteWearEvent(int eventId) async {
    _isar.write((isar) {
      final ev = isar.wearEvents.get(eventId);
      if (ev == null) return;
      if (ev.kind != EventKind.wear) {
        throw StateError('deleteWearEvent only applies to wear events');
      }
      final itemId = ev.itemId;
      isar.wearEvents.delete(eventId);

      final item = isar.items.get(itemId);
      if (item == null) return;

      item
        ..wearSinceWash = item.wearSinceWash > 0 ? item.wearSinceWash - 1 : 0
        ..totalWears = item.totalWears > 0 ? item.totalWears - 1 : 0;

      final remaining = isar.wearEvents
          .where()
          .itemIdEqualTo(itemId)
          .kindEqualTo(EventKind.wear)
          .sortByOccurredAtDesc()
          .findFirst();
      item.lastWornAt = remaining?.occurredAt;

      if (item.status == ItemStatus.dirty &&
          item.wearSinceWash < item.washCycle) {
        item.status = ItemStatus.clean;
      }

      isar.items.put(item);
    });
  }
}
