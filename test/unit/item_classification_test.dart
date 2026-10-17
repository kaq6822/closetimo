// #37·#41·#45 — 분류(종류·용도·홈 버킷)·필터 계약·관리 상태 규칙 단위 테스트.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(
  Category category, {
  String name = '옷',
  String? brand,
  List<ItemPurpose> purposes = const [],
}) => Item(
  name: name,
  brand: brand,
  category: category,
  purposes: purposes,
  washCycle: 3,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  group('enum ordinal 저장 호환', () {
    // Isar Plus는 enum을 index로 저장한다. 순서가 바뀌면 기존 데이터의 의미가
    // 바뀌므로 저장된 index를 고정값으로 검증한다.
    test('Category index는 기존 값을 유지하고 미분류는 끝에 추가된다', () {
      expect(Category.values.map((c) => c.name), [
        'outer',
        'top',
        'bottom',
        'onepiece',
        'shoes',
        'bag',
        'accessory',
        'activewear',
        'etc',
        'uncategorized',
      ]);
    });

    test('CareMethod·CareMode·ItemPurpose index를 고정한다', () {
      expect(CareMethod.values.map((m) => m.name), [
        'dryClean',
        'machine',
        'handWash',
        'unspecified',
      ]);
      expect(CareMode.values.map((m) => m.name), ['wearCycle', 'manual']);
      expect(ItemPurpose.values.map((p) => p.name), ['sport']);
    });
  });

  group('종류와 홈 버킷', () {
    test('선택 가능한 종류는 미분류를 먼저 두고 legacy 운동복을 제외한다', () {
      expect(Category.selectable.first, Category.uncategorized);
      expect(Category.selectable, isNot(contains(Category.activewear)));
      expect(
        Category.selectable.toSet(),
        Category.values.toSet()..remove(Category.activewear),
      );
    });

    test('홈 버킷은 모든 종류를 빠짐없이 한 번씩 나눈다', () {
      final all = [for (final b in HomeBucket.values) ...b.categories];
      expect(all.length, Category.values.length);
      expect(all.toSet(), Category.values.toSet());
    });

    test("'그 외'는 개별 '기타'와 달리 미분류·신발·가방 등을 합산한다", () {
      expect(HomeBucket.others.label, '그 외');
      expect(Category.etc.label, '기타');
      expect(HomeBucket.others.categories, {
        Category.onepiece,
        Category.shoes,
        Category.bag,
        Category.accessory,
        Category.activewear,
        Category.etc,
        Category.uncategorized,
      });
      expect(HomeBucket.top.categories, {Category.top});
    });
  });

  group('ItemFilter', () {
    test('빈 필터는 모든 옷을 통과시킨다', () {
      const filter = ItemFilter();
      expect(filter.isActive, isFalse);
      for (final c in Category.values) {
        expect(filter.matches(_item(c)), isTrue);
      }
    });

    test('홈 버킷 필터는 버킷 집계 규칙과 같은 옷만 통과시킨다', () {
      for (final bucket in HomeBucket.values) {
        final filter = ItemFilter.homeBucket(bucket);
        for (final c in Category.values) {
          expect(
            filter.matches(_item(c)),
            c.homeBucket == bucket,
            reason: '$bucket / $c',
          );
        }
      }
    });

    test("개별 '기타' 필터는 Category.etc만 통과시킨다", () {
      final filter = ItemFilter.category(Category.etc);
      expect(filter.matches(_item(Category.etc)), isTrue);
      expect(filter.matches(_item(Category.shoes)), isFalse);
      expect(filter.matches(_item(Category.uncategorized)), isFalse);
    });

    test('축 안은 OR, 축 사이는 AND로 결합하고 검색어도 함께 적용한다', () {
      const filter = ItemFilter(
        categories: {Category.top, Category.bottom},
        purposes: {ItemPurpose.sport},
        query: 'nike',
      );
      expect(
        filter.matches(
          _item(
            Category.bottom,
            brand: 'NIKE',
            purposes: const [ItemPurpose.sport],
          ),
        ),
        isTrue,
      );
      expect(
        filter.matches(_item(Category.bottom, brand: 'NIKE')),
        isFalse,
        reason: '용도 불일치',
      );
      expect(
        filter.matches(
          _item(
            Category.shoes,
            brand: 'NIKE',
            purposes: const [ItemPurpose.sport],
          ),
        ),
        isFalse,
        reason: '종류 불일치',
      );
      expect(
        filter.matches(
          _item(
            Category.top,
            brand: 'ZARA',
            purposes: const [ItemPurpose.sport],
          ),
        ),
        isFalse,
        reason: '검색어 불일치',
      );
    });

    test('같은 조건이면 집합 순서와 무관하게 같다', () {
      expect(
        const ItemFilter(categories: {Category.top, Category.bottom}),
        const ItemFilter(categories: {Category.bottom, Category.top}),
      );
      expect(
        ItemFilter.homeBucket(HomeBucket.others).groupBucket,
        HomeBucket.others,
      );
      expect(ItemFilter.category(Category.top).groupBucket, isNull);
    });
  });

  group('옷장 라우트 쿼리 계약', () {
    test('홈 버킷 → 쿼리 → 필터 왕복이 같은 범위를 유지한다', () {
      for (final bucket in HomeBucket.values) {
        final filter = ItemFilter.homeBucket(bucket);
        final query = wardrobeQueryParameters(filter);
        expect(wardrobeFilterFromQuery(query), filter, reason: '$bucket');
      }
      expect(
        wardrobeQueryParameters(ItemFilter.homeBucket(HomeBucket.others)),
        {'group': 'others'},
      );
      expect(wardrobeQueryParameters(ItemFilter.homeBucket(HomeBucket.top)), {
        'category': 'top',
      });
    });

    test('개별 기타·용도·과거 한국어 라벨 쿼리를 해석한다', () {
      expect(
        wardrobeFilterFromQuery({'category': 'etc'}),
        ItemFilter.category(Category.etc),
      );
      expect(
        wardrobeFilterFromQuery({'category': '상의', 'purpose': 'sport'}),
        const ItemFilter(
          categories: {Category.top},
          purposes: {ItemPurpose.sport},
        ),
      );
      expect(
        wardrobeFilterFromQuery({'category': 'unknown'}),
        const ItemFilter(),
      );
      expect(wardrobeQueryParameters(const ItemFilter()), isEmpty);
    });
  });

  group('관리 상태 규칙(#45)', () {
    Item counted({required CareMode mode, required int wears}) => Item(
      name: '셔츠',
      category: Category.top,
      washCycle: 3,
      careMode: mode,
      wearSinceWash: wears,
      createdAt: DateTime(2026, 10, 1),
    );

    test('횟수 기반이면 주기에 도달할 때 dirty다', () {
      expect(
        counted(mode: CareMode.wearCycle, wears: 2).derivedStatus,
        ItemStatus.clean,
      );
      expect(
        counted(mode: CareMode.wearCycle, wears: 3).derivedStatus,
        ItemStatus.dirty,
      );
    });

    test('manual이면 착용 횟수와 무관하게 dirty가 되지 않는다', () {
      final item = counted(mode: CareMode.manual, wears: 10);
      expect(item.tracksWearCycle, isFalse);
      expect(item.derivedStatus, ItemStatus.clean);
    });

    test('새 Item 기본값은 미지정 관리 방법·횟수 기반·용도 없음이다', () {
      final item = _item(Category.uncategorized);
      expect(item.careMethod, CareMethod.unspecified);
      expect(item.careMode, CareMode.wearCycle);
      expect(item.purposes, isEmpty);
      expect(CareMethod.unspecified.label, '미지정');
    });
  });
}
