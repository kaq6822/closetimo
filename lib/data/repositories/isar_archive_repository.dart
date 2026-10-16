import 'package:isar_plus/isar_plus.dart';

import '../../core/utils/clock.dart';
import '../models/item.dart';
import 'archive_repository.dart';

class IsarArchiveRepository implements ArchiveRepository {
  IsarArchiveRepository({required Isar isar, required Clock clock})
    : _isar = isar,
      _clock = clock;

  final Isar _isar;
  final Clock _clock;

  @override
  Stream<List<Item>> watchArchived() {
    return _isar.items
        .where()
        .archivedAtIsNotNull()
        .sortByArchivedAtDesc()
        .watch(fireImmediately: true);
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
