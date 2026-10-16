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

  /// FR-010d: 착용 날짜를 저장 시각으로 바꾼다. 오늘이면 `now`, 과거면 그날
  /// 12:00, 미래면 [ArgumentError].
  DateTime _resolveWornAt(DateTime? wornOn) {
    final now = _clock.now();
    if (wornOn == null) return now;
    final day = DateTime(wornOn.year, wornOn.month, wornOn.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day.isAfter(today)) {
      throw ArgumentError.value(wornOn, 'wornOn', 'wornOn must not be future');
    }
    if (day == today) return now;
    return DateTime(day.year, day.month, day.day, 12);
  }

  @override
  Future<int?> recordWear(int itemId, {String? note, DateTime? wornOn}) async {
    final normalized = _normalizeNote(note);
    final at = _resolveWornAt(wornOn);
    return _isar.write((isar) {
      final item = isar.items.get(itemId);
      if (item == null) return null;
      return _applyWear(isar, item, at, normalized);
    });
  }

  @override
  Future<WearBatchResult> recordWearBatch(
    Iterable<int> itemIds, {
    DateTime? wornOn,
    String? note,
  }) async {
    final normalized = _normalizeNote(note);
    final at = _resolveWornAt(wornOn);
    final ids = itemIds.toList();
    return _isar.write((isar) {
      final seen = <int>{};
      final created = <int>[];
      var skipped = 0;
      for (final id in ids) {
        final item = seen.add(id) ? isar.items.get(id) : null;
        if (item == null || item.isArchived) {
          skipped++;
          continue;
        }
        created.add(_applyWear(isar, item, at, normalized));
      }
      return WearBatchResult(eventIds: created, skipped: skipped);
    });
  }

  /// FR-010d: [item]에 [at] 시각의 착용 1건을 적용하고 생성한 이벤트 id를 돌려준다.
  /// 쓰기 트랜잭션 안에서만 호출한다.
  int _applyWear(Isar isar, Item item, DateTime at, String? note) {
    final event = WearEvent(
      itemId: item.id,
      kind: EventKind.wear,
      occurredAt: at,
      note: note,
    )..id = isar.wearEvents.autoIncrement();
    if (_inCurrentCycle(at, event.id, _lastWash(isar, item.id))) {
      item.wearSinceWash += 1;
    }
    final last = item.lastWornAt;
    item
      ..totalWears += 1
      ..lastWornAt = last == null || at.isAfter(last) ? at : last;
    // #45 — manual 관리 옷은 횟수로 dirty가 되지 않는다.
    item.status = item.derivedStatus;
    isar.items.put(item);
    isar.wearEvents.put(event);
    return event.id;
  }

  /// 해당 옷의 가장 최근 wash 이벤트. 같은 시각이면 id가 큰(나중에 저장된) 쪽.
  WearEvent? _lastWash(Isar isar, int itemId) => isar.wearEvents
      .where()
      .itemIdEqualTo(itemId)
      .kindEqualTo(EventKind.wash)
      .findAll()
      .fold<WearEvent?>(null, (acc, e) {
        if (acc == null) return e;
        final c = e.occurredAt.compareTo(acc.occurredAt);
        return c > 0 || (c == 0 && e.id > acc.id) ? e : acc;
      });

  /// 현재 세탁 주기 = 가장 최근 wash 이벤트 이후의 기록(FR-010b·010d). 같은 시각이면
  /// id가 큰 이벤트를 이후로 본다. wash 이벤트가 없으면(카운터만 있는 기존 데이터
  /// 포함) 모든 wear를 현재 주기로 간주한다.
  bool _inCurrentCycle(DateTime at, int eventId, WearEvent? lastWash) =>
      lastWash == null ||
      at.isAfter(lastWash.occurredAt) ||
      (at.isAtSameMomentAs(lastWash.occurredAt) && eventId > lastWash.id);

  /// 남은 wear 이벤트 중 최신 시각(없으면 null).
  DateTime? _latestWear(Isar isar, int itemId) => isar.wearEvents
      .where()
      .itemIdEqualTo(itemId)
      .kindEqualTo(EventKind.wear)
      .sortByOccurredAtDesc()
      .findFirst()
      ?.occurredAt;

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
  Future<void> updateWearDate(int eventId, DateTime wornOn) async {
    final at = _resolveWornAt(wornOn);
    _isar.write((isar) {
      final ev = isar.wearEvents.get(eventId);
      if (ev == null) return;
      if (ev.kind != EventKind.wear) {
        throw StateError('updateWearDate only applies to wear events');
      }
      final prev = ev.occurredAt;
      if (prev.year == at.year &&
          prev.month == at.month &&
          prev.day == at.day) {
        return;
      }
      final lastWash = _lastWash(isar, ev.itemId);
      final wasIn = _inCurrentCycle(prev, ev.id, lastWash);
      final nowIn = _inCurrentCycle(at, ev.id, lastWash);
      ev.occurredAt = at;
      isar.wearEvents.put(ev);

      final item = isar.items.get(ev.itemId);
      if (item == null) return;
      if (nowIn && !wasIn) item.wearSinceWash += 1;
      if (wasIn && !nowIn && item.wearSinceWash > 0) item.wearSinceWash -= 1;
      item
        ..lastWornAt = _latestWear(isar, item.id)
        ..status = item.derivedStatus;
      isar.items.put(item);
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
      _removeWear(isar, ev);
    });
  }

  @override
  Future<void> deleteWearEvents(Iterable<int> eventIds) async {
    final ids = eventIds.toList();
    _isar.write((isar) {
      for (final id in ids) {
        final ev = isar.wearEvents.get(id);
        if (ev == null || ev.kind != EventKind.wear) continue;
        _removeWear(isar, ev);
      }
    });
  }

  /// FR-010b: wear 이벤트 [ev]를 지우고 옷의 카운터·`lastWornAt`·상태를 역적용한다.
  /// 쓰기 트랜잭션 안에서만 호출한다. `inLaundry`는 바꾸지 않는다.
  void _removeWear(Isar isar, WearEvent ev) {
    final itemId = ev.itemId;
    isar.wearEvents.delete(ev.id);

    final item = isar.items.get(itemId);
    if (item == null) return;

    final inCurrentCycle = _inCurrentCycle(
      ev.occurredAt,
      ev.id,
      _lastWash(isar, itemId),
    );
    item
      ..wearSinceWash = inCurrentCycle && item.wearSinceWash > 0
          ? item.wearSinceWash - 1
          : item.wearSinceWash
      ..totalWears = item.totalWears > 0 ? item.totalWears - 1 : 0
      ..lastWornAt = _latestWear(isar, itemId)
      ..status = item.derivedStatus;
    isar.items.put(item);
  }
}
