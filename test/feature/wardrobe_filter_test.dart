// US2 acceptance — 카테고리·검색·정렬 분기 단위 테스트.

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ItemRepository {
  _FakeRepo(this._items);
  final List<Item> _items;

  @override
  Future<int> create(_) async => throw UnimplementedError();

  @override
  Future<Item?> get(int id) async =>
      _items.where((i) => i.id == id).cast<Item?>().firstOrNull;

  @override
  Stream<List<Item>> watchAll() =>
      Stream.value(List.unmodifiable(_items.reversed));

  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) {
    final q = query.trim().toLowerCase();
    return watchAll().map((items) {
      var arr = items;
      if (category != null) {
        arr = arr.where((i) => i.category == category).toList();
      }
      if (q.isNotEmpty) {
        arr = arr
            .where((i) =>
                i.name.toLowerCase().contains(q) ||
                (i.brand ?? '').toLowerCase().contains(q))
            .toList();
      }
      final sorted = [...arr];
      switch (sort) {
        case WardrobeSort.statusCleanFirst:
          sorted.sort((a, b) {
            final aK = a.status == ItemStatus.clean ? 0 : 1;
            final bK = b.status == ItemStatus.clean ? 0 : 1;
            return aK.compareTo(bK);
          });
        case WardrobeSort.recentlyWorn:
          sorted.sort((a, b) {
            final aT = a.lastWornAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bT = b.lastWornAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bT.compareTo(aT);
          });
        case WardrobeSort.mostWorn:
          sorted.sort((a, b) => b.totalWears.compareTo(a.totalWears));
      }
      return sorted;
    });
  }

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) =>
      const Stream.empty();
  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
}

Item _it({
  required int id,
  required String name,
  String? brand,
  required Category cat,
  ItemStatus status = ItemStatus.clean,
  int totalWears = 0,
}) =>
    Item(
      name: name,
      brand: brand,
      category: cat,
      washCycle: 5,
      createdAt: DateTime(2026, 5, id),
    )
      ..id = id
      ..status = status
      ..totalWears = totalWears;

void main() {
  group('US2 watchFiltered', () {
    final repo = _FakeRepo([
      _it(id: 1, name: '오버사이즈 코트', brand: 'ZARA', cat: Category.outer,
          status: ItemStatus.clean),
      _it(id: 2, name: '캐시미어 니트', brand: '유니클로', cat: Category.top,
          status: ItemStatus.dirty, totalWears: 8),
      _it(id: 3, name: '오가닉 코튼 티셔츠', brand: '무인양품', cat: Category.top,
          totalWears: 3),
      _it(id: 4, name: '셀비지 데님', brand: 'A.P.C.', cat: Category.bottom,
          totalWears: 12),
    ]);

    test('카테고리 필터 — 상의만 남는다', () async {
      final items = await repo
          .watchFiltered(
            category: Category.top,
            sort: WardrobeSort.statusCleanFirst,
          )
          .first;
      expect(items.map((e) => e.id), unorderedEquals([2, 3]));
    });

    test('검색 — 대소문자 무시, name/brand 동시 매칭', () async {
      final byName = await repo
          .watchFiltered(query: '캐시미어', sort: WardrobeSort.mostWorn)
          .first;
      expect(byName.map((e) => e.id), [2]);

      final byBrand = await repo
          .watchFiltered(query: 'zara', sort: WardrobeSort.mostWorn)
          .first;
      expect(byBrand.map((e) => e.id), [1]);
    });

    test('정렬 — 상태순(깨끗 우선)', () async {
      final items = await repo
          .watchFiltered(sort: WardrobeSort.statusCleanFirst)
          .first;
      // 깨끗(1,3,4)이 먼저, 더러움(2)이 뒤에 와야 한다.
      final last = items.last;
      expect(last.id, 2);
    });

    test('정렬 — 착용 빈도순', () async {
      final items =
          await repo.watchFiltered(sort: WardrobeSort.mostWorn).first;
      expect(items.first.id, 4); // 12회
      expect(items[1].id, 2); // 8회
    });

    test('빈 결과', () async {
      final items = await repo
          .watchFiltered(query: '없는검색어zzz', sort: WardrobeSort.mostWorn)
          .first;
      expect(items, isEmpty);
    });
  });
}
