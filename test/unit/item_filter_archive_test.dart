// #44 — ItemFilter 보관 축. 기본값은 활성만이며 다른 축과 AND로 결합한다.

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(String name, {DateTime? archivedAt}) => Item(
  name: name,
  category: Category.top,
  washCycle: 3,
  createdAt: DateTime(2026),
  archivedAt: archivedAt,
);

void main() {
  final active = _item('셔츠');
  final archived = _item('코트', archivedAt: DateTime(2026, 10, 16));

  test('기본 필터는 보관한 옷을 제외한다', () {
    const filter = ItemFilter();
    expect(filter.archive, ArchiveScope.active);
    expect(filter.matches(active), isTrue);
    expect(filter.matches(archived), isFalse);
    expect(filter.hasScope, isFalse);
    expect(filter.isActive, isFalse);
  });

  test('archived·all 범위와 다른 축의 AND 결합', () {
    const onlyArchived = ItemFilter(archive: ArchiveScope.archived);
    expect(onlyArchived.matches(active), isFalse);
    expect(onlyArchived.matches(archived), isTrue);
    expect(onlyArchived.hasScope, isTrue);

    const all = ItemFilter(archive: ArchiveScope.all);
    expect(all.matches(active), isTrue);
    expect(all.matches(archived), isTrue);

    expect(
      const ItemFilter(
        archive: ArchiveScope.archived,
        query: '셔츠',
      ).matches(archived),
      isFalse,
    );
    expect(ItemFilter.category(Category.top).matches(archived), isFalse);
  });

  test('copyWith·동등성에 보관 축이 반영된다', () {
    const base = ItemFilter();
    final moved = base.copyWith(archive: ArchiveScope.archived);
    expect(moved.archive, ArchiveScope.archived);
    expect(moved == base, isFalse);
    expect(moved.copyWith(query: 'a').archive, ArchiveScope.archived);
    expect(moved, equals(const ItemFilter(archive: ArchiveScope.archived)));
    expect(
      moved.hashCode,
      const ItemFilter(archive: ArchiveScope.archived).hashCode,
    );
  });

  test('ArchiveReason ordinal은 끝에만 추가한다', () {
    expect(ArchiveReason.unspecified.index, 0);
    expect(ArchiveReason.seasonal.index, 1);
    expect(ArchiveReason.noLongerOwned.index, 2);
  });
}
