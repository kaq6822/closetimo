// 005 — 구조화 속성 카탈로그·정규화·이름 추론·세탁 그룹·필터 규칙.

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_attributes.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item({
  String name = '옷',
  Category category = Category.top,
  String? subType,
  List<String> colors = const [],
  List<Season> seasons = const [],
  String? material,
  String? pattern,
  CareMethod careMethod = CareMethod.unspecified,
}) => Item(
  name: name,
  category: category,
  washCycle: 3,
  createdAt: DateTime(2026, 11, 1),
  subType: subType,
  colors: colors,
  seasons: seasons,
  material: material,
  pattern: pattern,
  careMethod: careMethod,
);

void main() {
  group('카탈로그 무결성', () {
    test('코드는 축마다 유일하다', () {
      Set<String> unique(Iterable<String> codes) {
        final list = codes.toList();
        expect(list.toSet().length, list.length);
        return list.toSet();
      }

      unique(ItemAttributes.subTypes.map((s) => s.code));
      unique(ItemAttributes.colors.map((c) => c.code));
      unique(ItemAttributes.materials.map((m) => m.code));
      unique(ItemAttributes.patterns.map((p) => p.code));
    });

    test('선택 가능한 종류마다 세부 종류가 있다(미분류·기타 제외)', () {
      for (final c in Category.selectable) {
        if (c == Category.uncategorized || c == Category.etc) continue;
        expect(ItemAttributes.subTypesOf(c), isNotEmpty, reason: c.name);
      }
    });

    test('Vision 매핑의 세부 종류는 매핑 종류에 속한다', () {
      for (final MapEntry(key: label, value: (category, sub))
          in visionLabelHints.entries) {
        if (sub == null) continue;
        expect(
          ItemAttributes.normalizeSubType(category, sub),
          sub,
          reason: label,
        );
      }
    });
  });

  group('정규화', () {
    test('세부 종류는 종류에 속할 때만 남는다', () {
      expect(ItemAttributes.normalizeSubType(Category.top, 'knit'), 'knit');
      expect(ItemAttributes.normalizeSubType(Category.bottom, 'knit'), isNull);
      expect(ItemAttributes.normalizeSubType(Category.top, 'nope'), isNull);
    });

    test('색상은 알 수 없는 코드·중복을 버리고 3개까지 순서대로 남긴다', () {
      expect(
        ItemAttributes.normalizeColors([
          'navy',
          'x',
          'navy',
          'white',
          'red',
          'black',
        ]),
        ['navy', 'white', 'red'],
      );
    });

    test('계절은 중복을 버리고 enum 순서로 정렬한다', () {
      expect(
        ItemAttributes.normalizeSeasons([
          Season.winter,
          Season.spring,
          Season.winter,
        ]),
        [Season.spring, Season.winter],
      );
    });

    test('applyTo는 종류 기준으로 세부 종류를 정리한다', () {
      final item = _item(category: Category.bottom);
      const ItemAttributeValues(
        subType: 'knit',
        colors: ['black'],
        material: 'wool',
        pattern: 'zebra',
      ).applyTo(item);
      expect(item.subType, isNull);
      expect(item.colors, ['black']);
      expect(item.material, 'wool');
      expect(item.pattern, isNull);
    });
  });

  group('자동 이름(FR-502)', () {
    test('색상 + 세부 종류', () {
      expect(
        autoItemName(
          category: Category.top,
          subType: 'knit',
          colors: ['black', 'white'],
        ),
        '검정 니트',
      );
    });

    test('세부 종류가 없으면 색상 + 종류, 미분류면 옷', () {
      expect(
        autoItemName(category: Category.bottom, colors: ['denim']),
        '데님 하의',
      );
      expect(
        autoItemName(category: Category.uncategorized, colors: ['beige']),
        '베이지 옷',
      );
    });

    test('색상이 없으면 세부 종류 또는 종류', () {
      expect(autoItemName(category: Category.shoes, subType: 'boots'), '부츠');
      expect(autoItemName(category: Category.outer), '아우터');
    });

    test('아무것도 없으면 이름 없는 옷', () {
      expect(autoItemName(category: Category.uncategorized), '이름 없는 옷');
    });

    test('종류와 맞지 않는 세부 종류는 이름에 쓰지 않는다', () {
      expect(autoItemName(category: Category.top, subType: 'jeans'), '상의');
    });
  });

  group('이름 추론(FR-503)', () {
    test('색상·세부 종류·소재를 함께 찾는다', () {
      final hints = inferFromName('베이지 울 코트');
      expect(hints.category, Category.outer);
      expect(hints.subType, 'coat');
      expect(hints.colors, ['beige']);
      expect(hints.material, 'wool');
    });

    test('가장 긴 키워드가 이긴다', () {
      expect(inferFromName('검정 후드티').subType, 'hoodie');
      expect(inferFromName('흰 티셔츠').subType, 'tshirt');
      expect(inferFromName('옥스포드 셔츠').subType, 'shirt');
    });

    test('단어 첫머리 키워드는 다른 단어 속에서 찾지 않는다', () {
      expect(inferFromName('겨울 코트').material, isNull);
      expect(inferFromName('면바지').material, 'cotton');
    });

    test('영문 키워드는 단어 단위로만 찾는다', () {
      expect(inferFromName('Navy Tee').subType, 'tshirt');
      expect(inferFromName('Navy Tee').colors, ['navy']);
      expect(inferFromName('steel').subType, isNull);
    });

    test('색상은 이름에 나온 순서로 모은다', () {
      expect(inferFromName('네이비 화이트 스트라이프 셔츠').colors, ['navy', 'white']);
      expect(inferFromName('네이비 화이트 스트라이프 셔츠').pattern, 'stripe');
    });

    test('다른 단어 속 키워드·꾸밈말을 잘못 잡지 않는다(리뷰 회귀)', () {
      expect(inferFromName('블루종').colors, isEmpty);
      expect(inferFromName('블루종').subType, 'jumper');
      expect(inferFromName('스카이블루 셔츠').colors, ['skyblue']);
      expect(inferFromName('블루 셔츠').colors, ['blue']);
      expect(inferFromName('울트라라이트 패딩').material, isNull);
      expect(inferFromName('울트라라이트 패딩').subType, 'padding');
      expect(inferFromName('울코트').material, 'wool');
      expect(inferFromName('무지개 티셔츠').pattern, isNull);
      expect(inferFromName('무지 티셔츠').pattern, 'solid');
      // 중심 명사(뒤에 나온 키워드)가 이긴다.
      final vest = inferFromName('니트 조끼');
      expect((vest.category, vest.subType), (Category.outer, 'vest'));
      expect(inferFromName('트레이닝 재킷').subType, 'jacket');
      expect(inferFromName('정장 재킷').subType, 'blazer');
      expect(inferFromName('니트 가디건').subType, 'cardigan');
      // 괄호·쉼표도 단어 경계다.
      expect(inferFromName('블랙 니트 (울)').material, 'wool');
      expect(inferFromName('울,캐시미어 코트').material, 'cashmere');
      expect(inferFromName('(블루) 셔츠').colors, ['blue']);
    });

    test('아무 키워드도 없으면 빈 힌트', () {
      expect(inferFromName('엄마가 사준 거').isEmpty, isTrue);
      expect(inferFromName('').isEmpty, isTrue);
    });
  });

  group('세탁 그룹(FR-512)', () {
    test('관리 방법 > 데님 > 밝기 > 미지정 순서로 판정한다', () {
      expect(
        _item(colors: ['white'], careMethod: CareMethod.handWash).washGroup,
        WashGroup.handCare,
      );
      expect(
        _item(category: Category.bottom, subType: 'jeans').washGroup,
        WashGroup.denim,
      );
      expect(_item(colors: ['denim']).washGroup, WashGroup.denim);
      expect(_item(colors: ['ivory', 'black']).washGroup, WashGroup.light);
      expect(_item(colors: ['black', 'white']).washGroup, WashGroup.dark);
      expect(_item(colors: ['red']).washGroup, WashGroup.dark);
      expect(_item().washGroup, WashGroup.unsorted);
    });
  });

  group('필터·검색(FR-509~511)', () {
    final black = _item(
      name: 'a',
      subType: 'knit',
      colors: ['black'],
      seasons: [Season.winter],
    );
    final navy = _item(
      name: 'b',
      subType: 'tshirt',
      colors: ['navy'],
      seasons: [Season.summer],
    );
    final noSeason = _item(name: 'c', colors: ['white']);

    test('같은 축은 OR, 다른 축은 AND', () {
      const f = ItemFilter(colors: {'black', 'navy'}, seasons: {Season.winter});
      expect(f.matches(black), isTrue);
      expect(f.matches(navy), isFalse);
      expect(f.matches(noSeason), isFalse);
      expect(const ItemFilter(subTypes: {'tshirt'}).matches(navy), isTrue);
      expect(f.detailCount, 3);
      expect(const ItemFilter(tags: {'a'}).detailCount, 0);
    });

    test('이번 계절은 계절을 정하지 않은 옷도 남긴다', () {
      const f = ItemFilter(season: Season.winter);
      expect(f.matches(black), isTrue);
      expect(f.matches(navy), isFalse);
      expect(f.matches(noSeason), isTrue);
      expect(f.hasScope, isTrue);
      expect(f.copyWith(clearSeason: true).season, isNull);
    });

    test('검색어는 속성 라벨도 찾는다', () {
      expect(const ItemFilter(query: '검정').matches(black), isTrue);
      expect(const ItemFilter(query: '니트').matches(black), isTrue);
      expect(const ItemFilter(query: '겨울').matches(black), isTrue);
      expect(const ItemFilter(query: '검정').matches(navy), isFalse);
    });

    test('월별 계절', () {
      expect(Season.ofMonth(3), Season.spring);
      expect(Season.ofMonth(8), Season.summer);
      expect(Season.ofMonth(11), Season.autumn);
      expect(Season.ofMonth(12), Season.winter);
      expect(Season.ofMonth(2), Season.winter);
    });
  });

  group('홈 오늘 입은 옷 후보(FR-507)', () {
    Item worn(int id, DateTime? at, {int wears = 0, DateTime? created}) =>
        _item(name: '$id')
          ..id = id
          ..lastWornAt = at
          ..totalWears = wears
          ..createdAt = created ?? DateTime(2026, 1, id);

    test('최근 입은 순(같으면 많이 입은 순) 뒤에 미착용 최근 등록 순, 보관·바구니 제외', () {
      final day = DateTime(2026, 11, 1);
      final items = [
        worn(1, DateTime(2026, 10, 1)),
        worn(2, day, wears: 3),
        worn(3, day, wears: 9),
        worn(4, null, created: DateTime(2026, 5, 1)),
        worn(5, null, created: DateTime(2026, 6, 1)),
        worn(6, day)..archivedAt = DateTime(2026, 10, 2),
        worn(7, day)..inLaundry = true,
      ];
      expect(todayWearCandidates(items).map((i) => i.id), [3, 2, 1, 5, 4]);
      expect(todayWearCandidates(items, limit: 2).map((i) => i.id), [3, 2]);
    });
  });

  test('세탁 그룹 요약은 그룹 순서로 빈 그룹을 빼고 센다', () {
    expect(
      washGroupSummary([
        _item(colors: ['black']),
        _item(colors: ['white']),
        _item(colors: ['navy']),
      ]),
      '흰옷·밝은색 1 · 어두운색·색깔 옷 2',
    );
    expect(washGroupSummary(const []), '');
  });
}
