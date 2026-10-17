// #46 — 사용자 태그 정규화·집계, ItemFilter 태그 축, 라우트 쿼리 코덱, 필터 요약.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_tags.dart';
import 'package:closetimo/features/wardrobe/filter_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(
  int id,
  String name, {
  Category category = Category.top,
  List<String> tags = const [],
  List<ItemPurpose> purposes = const [],
  DateTime? archivedAt,
}) => Item(
  name: name,
  category: category,
  washCycle: 5,
  createdAt: DateTime(2026, 10, id),
  tags: tags,
  purposes: purposes,
  archivedAt: archivedAt,
)..id = id;

void main() {
  group('normalizeTag / normalizeTags / parseTagInput', () {
    test('공백을 정리하고 쉼표를 공백으로 바꾸며 빈 값은 null', () {
      expect(normalizeTag('  여름   옷 '), '여름 옷');
      expect(normalizeTag('a,b'), 'a b');
      expect(normalizeTag('   '), isNull);
      expect(normalizeTag(','), isNull);
    });

    test('최대 길이를 넘으면 자른다', () {
      final long = '가' * (maxTagLength + 5);
      expect(normalizeTag(long)!.runes.length, maxTagLength);
    });

    test('대소문자만 다른 중복은 먼저 나온 표기를 남기고 순서를 유지한다', () {
      expect(normalizeTags(['Black', '여름', 'black', ' 여름 ', '']), [
        'Black',
        '여름',
      ]);
    });

    test('쉼표로 여러 태그를 한 번에 입력한다', () {
      expect(parseTagInput('검정, 여름,, 출근 '), ['검정', '여름', '출근']);
      expect(parseTagInput(' , '), isEmpty);
    });
  });

  test('summarizeTags는 많이 쓴 순·이름순으로 집계하고 보관한 옷은 활성 수에서 뺀다', () {
    final usages = summarizeTags([
      _item(1, 'a', tags: ['여름', '검정']),
      _item(2, 'b', tags: ['검정']),
      _item(3, 'c', tags: ['검정', '겨울'], archivedAt: DateTime(2026, 10, 1)),
    ]);
    expect(usages, const [
      TagUsage(name: '검정', itemCount: 3, activeItemCount: 2),
      TagUsage(name: '겨울', itemCount: 1, activeItemCount: 0),
      TagUsage(name: '여름', itemCount: 1, activeItemCount: 1),
    ]);
  });

  test('summarizeTags는 대소문자만 다른 태그를 하나로 모으고 많이 쓴 표기를 이름으로 쓴다', () {
    final usages = summarizeTags([
      _item(1, 'a', tags: ['summer']),
      _item(2, 'b', tags: ['Summer']),
      _item(3, 'c', tags: ['summer']),
    ]);
    expect(usages, const [
      TagUsage(name: 'summer', itemCount: 3, activeItemCount: 3),
    ]);
  });

  test('ItemFilter 태그 조건은 대소문자를 구분하지 않는다', () {
    final upper = _item(1, 'a', tags: ['Summer']);
    final lower = _item(2, 'b', tags: ['summer']);
    const filter = ItemFilter(tags: {'Summer'});
    expect(filter.matches(upper), isTrue);
    expect(filter.matches(lower), isTrue);
  });

  group('ItemFilter.tags', () {
    final shirt = _item(1, '셔츠', tags: ['여름', '흰색']);
    final pants = _item(
      2,
      '반바지',
      category: Category.bottom,
      tags: ['여름'],
      purposes: [ItemPurpose.sport],
    );
    final coat = _item(3, '코트', category: Category.outer, tags: ['겨울']);
    final plain = _item(4, '태그 없는 니트');

    test('같은 축 안은 OR이다', () {
      const f = ItemFilter(tags: {'흰색', '겨울'});
      expect([shirt, pants, coat, plain].where(f.matches), [shirt, coat]);
    });

    test('다른 축과는 AND다', () {
      const f = ItemFilter(
        categories: {Category.top, Category.bottom},
        purposes: {ItemPurpose.sport},
        tags: {'여름'},
      );
      expect([shirt, pants, coat, plain].where(f.matches), [pants]);
    });

    test('태그 축이 비면 태그 없는 옷도 포함한다(태그가 없어도 불이익 없음)', () {
      expect(const ItemFilter().matches(plain), isTrue);
      expect(
        const ItemFilter(categories: {Category.top}).matches(plain),
        isTrue,
      );
    });

    test('검색어는 태그도 부분 일치로 찾는다', () {
      const f = ItemFilter(query: '흰');
      expect([shirt, pants, coat, plain].where(f.matches), [shirt]);
    });

    test('hasScope·equality·copyWith에 반영된다', () {
      const f = ItemFilter(tags: {'a', 'b'});
      expect(f.hasScope, isTrue);
      expect(f.isActive, isTrue);
      expect(f, const ItemFilter(tags: {'b', 'a'}));
      expect(f.hashCode, const ItemFilter(tags: {'b', 'a'}).hashCode);
      expect(f == const ItemFilter(tags: {'a'}), isFalse);
      expect(f.copyWith(tags: {}).hasScope, isFalse);
      expect(f.copyWith(query: 'x').tags, {'a', 'b'});
    });
  });

  group('라우트 쿼리 tag=', () {
    test('왕복 변환이 같은 필터를 만든다', () {
      const f = ItemFilter(
        categories: {Category.top},
        purposes: {ItemPurpose.sport},
        tags: {'여름', '검정 옷'},
      );
      final params = wardrobeQueryParameters(f);
      expect(params['tag'], '검정 옷,여름');
      expect(wardrobeFilterFromQuery(params), f);
    });

    test('빈 값·공백은 무시하고 정규화한다', () {
      expect(wardrobeFilterFromQuery({'tag': ' 여름 ,, '}).tags, {'여름'});
      expect(wardrobeFilterFromQuery({'tag': ''}).tags, isEmpty);
      expect(wardrobeQueryParameters(const ItemFilter()), isEmpty);
    });
  });

  test('필터 요약은 태그 축을 OR로 표기한다', () {
    expect(
      describeItemFilter(
        const ItemFilter(categories: {Category.top}, tags: {'여름', '검정'}),
      ),
      '상의 · 태그: 검정 또는 여름',
    );
  });
}
