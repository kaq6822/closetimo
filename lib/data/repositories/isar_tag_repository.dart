import 'package:isar_plus/isar_plus.dart';

import '../models/item.dart';
import '../models/item_tags.dart';
import 'tag_repository.dart';

class IsarTagRepository implements TagRepository {
  IsarTagRepository({required Isar isar}) : _isar = isar;

  final Isar _isar;

  @override
  Future<int> addTag(Set<int> itemIds, String tag) => addTags(itemIds, [tag]);

  @override
  Future<int> removeTag(Set<int> itemIds, String tag) =>
      removeTags(itemIds, [tag]);

  @override
  Future<int> addTags(Set<int> itemIds, Iterable<String> tags) async {
    // 검증을 먼저 끝내 일부만 저장되는 일이 없게 한다.
    final normalized = [for (final t in tags) _require(t)];
    return _rewrite(
      (isar) => isar.items.getAll(itemIds.toList()).nonNulls,
      (current) => normalizeTags([...current, ...normalized]),
    );
  }

  @override
  Future<int> removeTags(Set<int> itemIds, Iterable<String> tags) async {
    final targets = [for (final t in tags) ?normalizeTag(t)];
    if (targets.isEmpty) return 0;
    return _rewrite(
      (isar) => isar.items.getAll(itemIds.toList()).nonNulls,
      (current) => _without(current, targets),
    );
  }

  @override
  Future<int> renameTag(String from, String to) async {
    final target = _require(to);
    final source = normalizeTag(from);
    // 대소문자만 바꾸는 이름 변경은 표기 통일이므로 허용한다.
    if (source == null || source == target) return 0;
    return _rewrite(
      (isar) => isar.items.where().findAll(),
      // 원래 자리에 새 이름을 두고, 이미 있던 같은 태그는 normalizeTags가 합친다.
      (current) => normalizeTags([
        for (final t in current) isSameTag(t, source) ? target : t,
      ]),
    );
  }

  @override
  Future<int> deleteTag(String tag) async {
    final normalized = normalizeTag(tag);
    if (normalized == null) return 0;
    return _rewrite(
      (isar) => isar.items.where().findAll(),
      (current) => _without(current, [normalized]),
    );
  }

  static List<String> _without(List<String> current, List<String> targets) => [
    for (final t in current)
      if (!targets.any((x) => isSameTag(t, x))) t,
  ];

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
