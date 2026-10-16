import 'package:isar_plus/isar_plus.dart';

import '../models/item.dart';
import '../models/item_tags.dart';
import 'tag_repository.dart';

class IsarTagRepository implements TagRepository {
  IsarTagRepository({required Isar isar}) : _isar = isar;

  final Isar _isar;

  @override
  Future<int> addTag(Set<int> itemIds, String tag) async {
    final normalized = _require(tag);
    return _rewrite(
      (isar) => isar.items.getAll(itemIds.toList()).nonNulls,
      (tags) => normalizeTags([...tags, normalized]),
    );
  }

  @override
  Future<int> removeTag(Set<int> itemIds, String tag) async {
    final normalized = normalizeTag(tag);
    if (normalized == null) return 0;
    return _rewrite(
      (isar) => isar.items.getAll(itemIds.toList()).nonNulls,
      (tags) => [
        for (final t in tags)
          if (t != normalized) t,
      ],
    );
  }

  @override
  Future<int> renameTag(String from, String to) async {
    final target = _require(to);
    final source = normalizeTag(from);
    if (source == null || source == target) return 0;
    return _rewrite(
      (isar) => isar.items.where().findAll(),
      // 원래 자리에 새 이름을 두고, 이미 있던 같은 태그는 normalizeTags가 합친다.
      (tags) => normalizeTags([for (final t in tags) t == source ? target : t]),
    );
  }

  @override
  Future<int> deleteTag(String tag) async {
    final normalized = normalizeTag(tag);
    if (normalized == null) return 0;
    return _rewrite(
      (isar) => isar.items.where().findAll(),
      (tags) => [
        for (final t in tags)
          if (t != normalized) t,
      ],
    );
  }

  static String _require(String tag) {
    final normalized = normalizeTag(tag);
    if (normalized == null) throw ArgumentError('Tag must be non-empty');
    return normalized;
  }

  /// [load]한 옷마다 태그를 [transform]하고, 바뀐 옷만 한 트랜잭션에서 저장한다.
  int _rewrite(
    Iterable<Item> Function(Isar isar) load,
    List<String> Function(List<String> tags) transform,
  ) {
    return _isar.write((isar) {
      final changed = <Item>[];
      for (final item in load(isar)) {
        final next = transform(item.tags);
        if (_sameList(next, item.tags)) continue;
        item.tags = next;
        changed.add(item);
      }
      if (changed.isNotEmpty) isar.items.putAll(changed);
      return changed.length;
    });
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
