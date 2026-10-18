import 'package:isar_plus/isar_plus.dart';

import '../../core/utils/clock.dart';
import '../models/item.dart';
import 'archive_repository.dart';
import 'shared_items_watcher.dart';

class IsarArchiveRepository implements ArchiveRepository {
  IsarArchiveRepository({
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
  Stream<List<Item>> watchArchived() {
    // 인덱스 조건 watch는 조건 밖으로 나가는 수정(복원)을 방출하지 않으므로
    // 전체를 구독하고 Dart에서 거른다.
    return _watcher.stream.map((all) {
      final archived = [
        for (final i in all)
          if (i.isArchived) i,
      ]..sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));
      return archived;
    });
  }

  @override
  Future<void> archive(
    int itemId, {
    ArchiveReason reason = ArchiveReason.unspecified,
  }) async {
    final now = _clock.now();
    _isar.write((isar) {
      final item = isar.items.get(itemId);
      if (item == null) return;
      item
        ..archivedAt ??= now
        ..archiveReason = reason
        ..inLaundry = false;
      isar.items.put(item);
    });
  }

  @override
  Future<void> restore(int itemId) async {
    _isar.write((isar) {
      final item = isar.items.get(itemId);
      if (item == null || !item.isArchived) return;
      item
        ..archivedAt = null
        ..archiveReason = ArchiveReason.unspecified;
      isar.items.put(item);
    });
  }
}
