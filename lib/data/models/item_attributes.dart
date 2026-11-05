// 005 — 구조화 속성 카탈로그(세부 종류·색상·소재·패턴)와 정규화·추론 규칙.
// specs/005-attributes-quick-capture/data-model.md §1~4.
//
// 코드 문자열은 저장 값이다. **바꾸거나 다른 의미로 재사용하지 않는다.**
// 라벨·키워드·순서·추천 계절은 자유롭게 고칠 수 있다.

import 'item.dart';

/// 세부 종류 1개. [category]에 종속된다.
class SubTypeDef {
  const SubTypeDef(
    this.code,
    this.label,
    this.category, {
    this.seasons = const {},
    this.keywords = const [],
  });

  final String code;
  final String label;
  final Category category;

  /// 계절이 비어 있을 때 제안할 추천 계절. 비어 있으면 제안하지 않는다.
  final Set<Season> seasons;

  /// 이름 추론 키워드(FR-503). `^`로 시작하면 단어 첫머리에서만 찾는다.
  final List<String> keywords;
}

/// 색상 밝기 계열. 세탁 그룹(FR-512) 판정에 쓴다.
enum ColorTone { light, dark }

/// 색상 1개. [argb]는 스와치 표시·사진 색상 추출 팔레트로 함께 쓴다.
class ColorDef {
  const ColorDef(
    this.code,
    this.label,
    this.argb,
    this.tone, {
    this.keywords = const [],
  });

  final String code;
  final String label;
  final int argb;
  final ColorTone tone;
  final List<String> keywords;
}

/// 소재·패턴처럼 코드·라벨·키워드만 가진 단일 선택 값.
class AttributeDef {
  const AttributeDef(this.code, this.label, {this.keywords = const []});

  final String code;
  final String label;
  final List<String> keywords;
}

/// 한 옷에 붙일 수 있는 최대 색상 수.
const int maxItemColors = 3;

abstract final class ItemAttributes {
  // ── 세부 종류 ──
  static const List<SubTypeDef> subTypes = [
    // 상의
    SubTypeDef(
      'tshirt',
      '티셔츠',
      Category.top,
      seasons: {Season.spring, Season.summer},
      keywords: ['티셔츠', '반팔티', '긴팔티', '티 셔츠', 'tshirt', 't-shirt', 'tee'],
    ),
    SubTypeDef(
      'shirt',
      '셔츠·블라우스',
      Category.top,
      seasons: {Season.spring, Season.summer, Season.autumn},
      keywords: ['셔츠', '블라우스', '남방', 'shirt', 'blouse'],
    ),
    SubTypeDef(
      'knit',
      '니트',
      Category.top,
      seasons: {Season.autumn, Season.winter},
      keywords: ['니트', '스웨터', '터틀넥', '폴라티', 'knit', 'sweater'],
    ),
    SubTypeDef(
      'sweatshirt',
      '맨투맨',
      Category.top,
      seasons: {Season.spring, Season.autumn},
      keywords: ['맨투맨', '스웻셔츠', 'sweatshirt'],
    ),
    SubTypeDef(
      'hoodie',
      '후드티',
      Category.top,
      seasons: {Season.spring, Season.autumn},
      keywords: ['후드티', '후드', '후디', 'hoodie'],
    ),
    SubTypeDef(
      'sleeveless',
      '민소매',
      Category.top,
      seasons: {Season.summer},
      keywords: ['민소매', '나시', '슬리브리스', '탱크탑'],
    ),
    SubTypeDef(
      'polo',
      '폴로',
      Category.top,
      seasons: {Season.spring, Season.summer},
      keywords: ['폴로', '카라티', 'pk티', 'polo'],
    ),
    // 하의
    SubTypeDef(
      'jeans',
      '청바지',
      Category.bottom,
      keywords: ['청바지', '데님 팬츠', '데님팬츠', '데님 바지', 'jeans'],
    ),
    SubTypeDef(
      'slacks',
      '슬랙스',
      Category.bottom,
      keywords: ['슬랙스', '정장바지', '정장 바지', 'slacks'],
    ),
    SubTypeDef(
      'cotton_pants',
      '면바지',
      Category.bottom,
      seasons: {Season.spring, Season.summer, Season.autumn},
      keywords: ['면바지', '치노', '코튼팬츠', '코튼 팬츠', 'chino'],
    ),
    SubTypeDef(
      'shorts',
      '반바지',
      Category.bottom,
      seasons: {Season.summer},
      keywords: ['반바지', '숏팬츠', '쇼츠', 'shorts'],
    ),
    SubTypeDef(
      'skirt',
      '스커트',
      Category.bottom,
      keywords: ['스커트', '치마', 'skirt'],
    ),
    SubTypeDef(
      'jogger',
      '트레이닝 바지',
      Category.bottom,
      keywords: ['트레이닝', '조거', '츄리닝', '트랙팬츠', 'jogger'],
    ),
    SubTypeDef(
      'leggings',
      '레깅스',
      Category.bottom,
      keywords: ['레깅스', 'leggings'],
    ),
    // 아우터
    SubTypeDef(
      'coat',
      '코트',
      Category.outer,
      seasons: {Season.autumn, Season.winter},
      keywords: ['코트', 'coat'],
    ),
    SubTypeDef(
      'padding',
      '패딩',
      Category.outer,
      seasons: {Season.winter},
      keywords: ['패딩', '롱패딩', '숏패딩', '푸퍼', '다운재킷', '다운 재킷', '다운자켓', 'puffer'],
    ),
    SubTypeDef(
      'jacket',
      '재킷',
      Category.outer,
      seasons: {Season.spring, Season.autumn},
      keywords: ['재킷', '자켓', '바람막이', 'jacket'],
    ),
    SubTypeDef(
      'blazer',
      '블레이저',
      Category.outer,
      seasons: {Season.spring, Season.autumn},
      keywords: ['블레이저', '정장 재킷', '정장재킷', 'blazer'],
    ),
    SubTypeDef(
      'jumper',
      '점퍼',
      Category.outer,
      seasons: {Season.spring, Season.autumn},
      keywords: ['점퍼', '집업', '야상', '블루종', 'jumper'],
    ),
    SubTypeDef(
      'cardigan',
      '카디건',
      Category.outer,
      seasons: {Season.spring, Season.autumn},
      keywords: ['카디건', '가디건', 'cardigan'],
    ),
    SubTypeDef(
      'vest',
      '조끼',
      Category.outer,
      seasons: {Season.spring, Season.autumn},
      keywords: ['조끼', '베스트', 'vest'],
    ),
    // 원피스
    SubTypeDef(
      'dress',
      '원피스',
      Category.onepiece,
      keywords: ['원피스', '드레스', 'dress'],
    ),
    SubTypeDef(
      'jumpsuit',
      '점프수트',
      Category.onepiece,
      keywords: ['점프수트', '오버롤', 'jumpsuit'],
    ),
    // 신발
    SubTypeDef(
      'sneakers',
      '운동화',
      Category.shoes,
      keywords: ['운동화', '스니커즈', '스니커', 'sneakers'],
    ),
    SubTypeDef('dress_shoes', '구두', Category.shoes, keywords: ['구두', '펌프스']),
    SubTypeDef(
      'boots',
      '부츠',
      Category.shoes,
      seasons: {Season.autumn, Season.winter},
      keywords: ['부츠', '워커', 'boots'],
    ),
    SubTypeDef(
      'sandals',
      '샌들·슬리퍼',
      Category.shoes,
      seasons: {Season.summer},
      keywords: ['샌들', '슬리퍼', '쪼리', 'sandals', 'slippers'],
    ),
    SubTypeDef('loafers', '로퍼', Category.shoes, keywords: ['로퍼', 'loafers']),
    // 가방
    SubTypeDef(
      'backpack',
      '백팩',
      Category.bag,
      keywords: ['백팩', '배낭', 'backpack'],
    ),
    SubTypeDef('shoulder_bag', '숄더백', Category.bag, keywords: ['숄더백']),
    SubTypeDef(
      'tote_bag',
      '토트백',
      Category.bag,
      keywords: ['토트백', '에코백', 'tote'],
    ),
    SubTypeDef(
      'cross_bag',
      '크로스백',
      Category.bag,
      keywords: ['크로스백', '메신저백', '슬링백'],
    ),
    SubTypeDef('clutch', '클러치', Category.bag, keywords: ['클러치']),
    // 액세서리
    SubTypeDef(
      'hat',
      '모자',
      Category.accessory,
      keywords: ['모자', '볼캡', '비니', '버킷햇', 'beanie'],
    ),
    SubTypeDef(
      'scarf',
      '머플러·스카프',
      Category.accessory,
      seasons: {Season.autumn, Season.winter},
      keywords: ['머플러', '스카프', '목도리', 'scarf'],
    ),
    SubTypeDef('belt', '벨트', Category.accessory, keywords: ['벨트', 'belt']),
    SubTypeDef(
      'gloves',
      '장갑',
      Category.accessory,
      seasons: {Season.winter},
      keywords: ['장갑', 'gloves'],
    ),
    SubTypeDef('socks', '양말', Category.accessory, keywords: ['양말', 'socks']),
    SubTypeDef(
      'jewelry',
      '주얼리',
      Category.accessory,
      keywords: ['목걸이', '반지', '귀걸이', '팔찌', '주얼리'],
    ),
    SubTypeDef('watch', '시계', Category.accessory, keywords: ['시계', 'watch']),
    SubTypeDef(
      'eyewear',
      '안경·선글라스',
      Category.accessory,
      keywords: ['안경', '선글라스', 'sunglasses'],
    ),
    SubTypeDef('tie', '넥타이', Category.accessory, keywords: ['넥타이', '보타이']),
  ];

  // ── 색상 ── 밝은 계열(light)은 세탁 그룹 '흰옷·밝은색'으로 모인다.
  static const List<ColorDef> colors = [
    ColorDef(
      'black',
      '검정',
      0xFF1E1E1E,
      ColorTone.dark,
      keywords: ['검정', '검은', '블랙', '까만', 'black'],
    ),
    ColorDef(
      'white',
      '흰색',
      0xFFF4F4F2,
      ColorTone.light,
      keywords: ['흰색', '흰', '화이트', '하얀', 'white'],
    ),
    ColorDef(
      'gray',
      '회색',
      0xFF8C8C8C,
      ColorTone.dark,
      keywords: ['회색', '그레이', '차콜', '멜란지', 'gray', 'grey'],
    ),
    ColorDef(
      'ivory',
      '아이보리',
      0xFFEEE6D2,
      ColorTone.light,
      keywords: ['아이보리', '크림', 'ivory', 'cream'],
    ),
    ColorDef(
      'beige',
      '베이지',
      0xFFD3BC9A,
      ColorTone.light,
      keywords: ['베이지', '오트밀', 'beige'],
    ),
    ColorDef(
      'camel',
      '카멜',
      0xFFB98A5A,
      ColorTone.dark,
      keywords: ['카멜', 'camel'],
    ),
    ColorDef(
      'brown',
      '브라운',
      0xFF6B4A33,
      ColorTone.dark,
      keywords: ['브라운', '갈색', '밤색', '초코', 'brown'],
    ),
    ColorDef(
      'navy',
      '네이비',
      0xFF1F2A44,
      ColorTone.dark,
      keywords: ['네이비', '남색', 'navy'],
    ),
    ColorDef(
      'blue',
      '파랑',
      0xFF2F5DA8,
      ColorTone.dark,
      // '블루'는 단독 단어일 때만(블루종·스카이블루 제외).
      keywords: ['파랑', '파란', r'^블루$', '코발트', 'blue'],
    ),
    ColorDef(
      'skyblue',
      '하늘',
      0xFF9DC3E6,
      ColorTone.light,
      keywords: ['하늘', '스카이블루', '연청'],
    ),
    ColorDef(
      'denim',
      '데님',
      0xFF5A7CA5,
      ColorTone.dark,
      keywords: ['데님', '중청', '진청', '청바지', 'denim'],
    ),
    ColorDef(
      'green',
      '초록',
      0xFF3C7A46,
      ColorTone.dark,
      keywords: ['초록', '그린', '녹색', 'green'],
    ),
    ColorDef(
      'khaki',
      '카키',
      0xFF6B6A3C,
      ColorTone.dark,
      keywords: ['카키', '올리브', 'khaki', 'olive'],
    ),
    ColorDef(
      'red',
      '빨강',
      0xFFC0302F,
      ColorTone.dark,
      keywords: ['빨강', '빨간', '레드', 'red'],
    ),
    ColorDef(
      'burgundy',
      '버건디',
      0xFF6A1E2C,
      ColorTone.dark,
      keywords: ['버건디', '와인', 'burgundy'],
    ),
    ColorDef(
      'pink',
      '분홍',
      0xFFEFA3B5,
      ColorTone.light,
      keywords: ['분홍', '핑크', 'pink'],
    ),
    ColorDef(
      'purple',
      '보라',
      0xFF7A5EA6,
      ColorTone.dark,
      keywords: ['보라', '퍼플', '라벤더', 'purple'],
    ),
    ColorDef(
      'yellow',
      '노랑',
      0xFFEFCF4A,
      ColorTone.light,
      keywords: ['노랑', '노란', '옐로', '머스타드', 'yellow'],
    ),
    ColorDef(
      'orange',
      '주황',
      0xFFE4813A,
      ColorTone.dark,
      keywords: ['주황', '오렌지', 'orange'],
    ),
  ];

  // ── 소재 ──
  static const List<AttributeDef> materials = [
    AttributeDef('cotton', '면', keywords: ['^면', '코튼', '순면', 'cotton']),
    // '울'은 단독 단어(울트라·겨울 제외)이거나 정해진 합성어일 때만.
    AttributeDef(
      'wool',
      '울·니트',
      keywords: [r'^울$', '울코트', '울니트', '모직', '램스울', '메리노', 'wool'],
    ),
    AttributeDef('cashmere', '캐시미어', keywords: ['캐시미어', '캐시미아', 'cashmere']),
    AttributeDef('denim', '데님', keywords: ['데님', '청바지', 'denim']),
    AttributeDef('leather', '가죽', keywords: ['가죽', '레더', '스웨이드', 'leather']),
    AttributeDef('linen', '린넨', keywords: ['린넨', '리넨', 'linen']),
    AttributeDef('silk', '실크', keywords: ['실크', '새틴', 'silk']),
    AttributeDef(
      'synthetic',
      '기능성·합성',
      keywords: ['기능성', '나일론', '폴리', '고어텍스', '플리스'],
    ),
  ];

  // ── 패턴 ──
  static const List<AttributeDef> patterns = [
    AttributeDef('solid', '무지', keywords: [r'^무지$', '솔리드']),
    AttributeDef(
      'stripe',
      '스트라이프',
      keywords: ['스트라이프', '줄무늬', '단가라', 'stripe'],
    ),
    AttributeDef('check', '체크', keywords: ['체크', '깅엄', '타탄', 'check']),
    AttributeDef('dot', '도트', keywords: ['도트', '땡땡이', '물방울', 'dot']),
    AttributeDef('graphic', '그래픽·로고', keywords: ['그래픽', '로고', '프린트']),
    AttributeDef('floral', '플로럴', keywords: ['플로럴', '꽃무늬', '플라워', 'floral']),
  ];

  static final Map<String, SubTypeDef> _subTypeByCode = {
    for (final s in subTypes) s.code: s,
  };
  static final Map<String, ColorDef> _colorByCode = {
    for (final c in colors) c.code: c,
  };
  static final Map<String, AttributeDef> _materialByCode = {
    for (final m in materials) m.code: m,
  };
  static final Map<String, AttributeDef> _patternByCode = {
    for (final p in patterns) p.code: p,
  };

  static SubTypeDef? subType(String? code) =>
      code == null ? null : _subTypeByCode[code];
  static ColorDef? color(String? code) =>
      code == null ? null : _colorByCode[code];
  static AttributeDef? material(String? code) =>
      code == null ? null : _materialByCode[code];
  static AttributeDef? pattern(String? code) =>
      code == null ? null : _patternByCode[code];

  /// [category]의 세부 종류(표시 순서).
  static List<SubTypeDef> subTypesOf(Category category) => [
    for (final s in subTypes)
      if (s.category == category) s,
  ];

  // ── 정규화(저장·복원 공통) ──

  /// [code]가 [category]의 세부 종류일 때만 돌려준다.
  static String? normalizeSubType(Category category, String? code) {
    final def = subType(code);
    return def != null && def.category == category ? def.code : null;
  }

  /// 알 수 없는 코드·중복을 버리고 [maxItemColors]개까지 남긴다(순서 유지).
  static List<String> normalizeColors(Iterable<String> raw) {
    final result = <String>[];
    for (final code in raw) {
      if (_colorByCode.containsKey(code) && !result.contains(code)) {
        result.add(code);
        if (result.length == maxItemColors) break;
      }
    }
    return result;
  }

  /// 중복을 버리고 enum 순서로 정렬한다.
  static List<Season> normalizeSeasons(Iterable<Season> raw) =>
      raw.toSet().toList()..sort((a, b) => a.index.compareTo(b.index));

  static String? normalizeMaterial(String? code) => material(code)?.code;
  static String? normalizePattern(String? code) => pattern(code)?.code;
}

/// 한 옷의 구조화 속성 값 묶음(005). 수정·일괄 변경 요청에 쓰며 저장하지 않는다.
class ItemAttributeValues {
  const ItemAttributeValues({
    this.subType,
    this.colors = const [],
    this.seasons = const [],
    this.material,
    this.pattern,
  });

  factory ItemAttributeValues.of(Item item) => ItemAttributeValues(
    subType: item.subType,
    colors: item.colors,
    seasons: item.seasons,
    material: item.material,
    pattern: item.pattern,
  );

  final String? subType;
  final List<String> colors;
  final List<Season> seasons;
  final String? material;
  final String? pattern;

  /// [item]에 정규화해 적용한다. 세부 종류는 [Item.category]에 맞을 때만 남는다.
  void applyTo(Item item) {
    item
      ..subType = ItemAttributes.normalizeSubType(item.category, subType)
      ..colors = ItemAttributes.normalizeColors(colors)
      ..seasons = ItemAttributes.normalizeSeasons(seasons)
      ..material = ItemAttributes.normalizeMaterial(material)
      ..pattern = ItemAttributes.normalizePattern(pattern);
  }

  @override
  bool operator ==(Object other) =>
      other is ItemAttributeValues &&
      other.subType == subType &&
      other.material == material &&
      other.pattern == pattern &&
      _sameList(other.colors, colors) &&
      _sameList(other.seasons, seasons);

  @override
  int get hashCode => Object.hash(
    subType,
    material,
    pattern,
    Object.hashAll(colors),
    Object.hashAll(seasons),
  );

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 사용자가 이름을 비웠을 때 쓰는 이름(FR-002 #42).
const String untitledItemName = '이름 없는 옷';

/// 자동 이름(FR-502). `{대표 색상} {세부 종류}`, 세부 종류가 없으면 `{대표 색상} {종류}`
/// (미분류면 `옷`), 색상이 없으면 `{세부 종류}`. 아무것도 없으면 [untitledItemName].
String autoItemName({
  required Category category,
  String? subType,
  List<String> colors = const [],
}) {
  final color = colors.isEmpty ? null : ItemAttributes.color(colors.first);
  final sub = ItemAttributes.normalizeSubType(category, subType);
  final kind = sub != null
      ? ItemAttributes.subType(sub)!.label
      : switch (category) {
          Category.uncategorized || Category.etc => null,
          _ => category.label,
        };
  if (color == null) return kind ?? untitledItemName;
  return '${color.label} ${kind ?? '옷'}';
}

/// 이름에서 찾은 속성 제안(FR-503). 저장하지 않는다.
class NameHints {
  const NameHints({
    this.category,
    this.subType,
    this.colors = const [],
    this.material,
    this.pattern,
  });

  final Category? category;
  final String? subType;
  final List<String> colors;
  final String? material;
  final String? pattern;

  bool get isEmpty =>
      category == null &&
      subType == null &&
      colors.isEmpty &&
      material == null &&
      pattern == null;
}

/// 이름 문자열에서 카탈로그 키워드를 찾는다(FR-503).
///
/// - 같은 축 안에서 더 긴 일치에 포함된 일치는 버린다(`티셔츠` ⊃ `셔츠`, `정장 재킷` ⊃ `재킷`).
/// - 세부 종류·소재·패턴은 이름에서 **가장 뒤에 나온** 키워드를 쓴다. 한국어 옷 이름은
///   꾸밈말 뒤에 중심 명사가 온다(`니트 조끼` → 조끼, `트레이닝 재킷` → 재킷).
/// - 색상은 이름에 나온 순서로 여러 개를 모은다.
NameHints inferFromName(String name) {
  final text = name.toLowerCase().trim();
  if (text.isEmpty) return const NameHints();

  final sub = _lastHit(_hits(text, ItemAttributes.subTypes, (d) => d.keywords));
  final colorHits = _hits(text, ItemAttributes.colors, (d) => d.keywords)
    ..sort((a, b) => a.start.compareTo(b.start));
  return NameHints(
    category: sub?.category,
    subType: sub?.code,
    colors: ItemAttributes.normalizeColors([
      for (final h in colorHits) h.def.code,
    ]),
    material: _lastHit(
      _hits(text, ItemAttributes.materials, (d) => d.keywords),
    )?.code,
    pattern: _lastHit(
      _hits(text, ItemAttributes.patterns, (d) => d.keywords),
    )?.code,
  );
}

class _Hit<T> {
  _Hit(this.def, this.start, this.end);

  final T def;
  final int start;
  final int end;

  int get length => end - start;

  /// [other]가 이 일치를 감싸는 더 긴 일치인지.
  bool insideOf(_Hit<T> other) =>
      other.start <= start && end <= other.end && other.length > length;
}

/// 한 축의 모든 키워드 일치. 더 긴 일치에 포함된 일치는 뺀다.
List<_Hit<T>> _hits<T>(
  String text,
  Iterable<T> defs,
  List<String> Function(T) keywordsOf,
) {
  final all = [
    for (final d in defs)
      for (final k in keywordsOf(d))
        for (final (start, end) in _keywordSpans(text, k)) _Hit(d, start, end),
  ];
  return [
    for (final h in all)
      if (!all.any(h.insideOf)) h,
  ];
}

/// 가장 뒤에 나온 일치(같은 위치면 더 긴 일치)의 값.
T? _lastHit<T>(List<_Hit<T>> hits) {
  if (hits.isEmpty) return null;
  return hits
      .reduce(
        (a, b) =>
            b.start > a.start || (b.start == a.start && b.length > a.length)
            ? b
            : a,
      )
      .def;
}

/// [keyword]의 일치 구간 `[start, end)`. `^`는 단어 첫머리, `$`는 단어 끝에서만 찾고,
/// 영문 키워드는 항상 단어 단위로 찾는다. 붙여 쓴 합성어(`블루셔츠`)는 단어 경계가 없어
/// 앵커 키워드로 찾지 않는다(`블루종`·`울트라` 오인을 막기 위한 선택).
Iterable<(int, int)> _keywordSpans(String text, String keyword) sync* {
  var k = keyword.toLowerCase();
  final atStart = k.startsWith('^');
  if (atStart) k = k.substring(1);
  final atEnd = k.endsWith(r'$');
  if (atEnd) k = k.substring(0, k.length - 1);
  final ascii = RegExp(r'^[a-z0-9 \-]+$').hasMatch(k);
  // 단어 경계는 글자(한글·영문·숫자)가 아닌 것으로 본다. 공백뿐 아니라 괄호·쉼표도 경계다.
  const letter = '[가-힣a-z0-9]';
  final before = ascii ? '(?<![a-z0-9])' : (atStart ? '(?<!$letter)' : '');
  final after = ascii ? '(?![a-z0-9])' : (atEnd ? '(?!$letter)' : '');
  for (final m in RegExp('$before${RegExp.escape(k)}$after').allMatches(text)) {
    yield (m.start, m.end);
  }
}

/// 검색어 비교용 속성 라벨(FR-511). 세부 종류·색상·소재·패턴·계절 라벨을 모은다.
Iterable<String> attributeSearchLabels(Item item) sync* {
  final sub = ItemAttributes.subType(item.subType);
  if (sub != null) yield sub.label;
  for (final c in item.colors) {
    final def = ItemAttributes.color(c);
    if (def != null) yield def.label;
  }
  final material = ItemAttributes.material(item.material);
  if (material != null) yield material.label;
  final pattern = ItemAttributes.pattern(item.pattern);
  if (pattern != null) yield pattern.label;
  for (final s in item.seasons) {
    yield s.label;
  }
}

/// 세탁 그룹(FR-512). 저장하지 않으며 표시 순서는 enum 순서다.
enum WashGroup {
  handCare,
  denim,
  light,
  dark,
  unsorted;

  String get label => switch (this) {
    WashGroup.handCare => '손세탁·드라이',
    WashGroup.denim => '데님',
    WashGroup.light => '흰옷·밝은색',
    WashGroup.dark => '어두운색·색깔 옷',
    WashGroup.unsorted => '색상 미지정',
  };
}

extension ItemWashGroup on Item {
  /// data-model.md §4 판정 순서.
  WashGroup get washGroup {
    if (careMethod == CareMethod.handWash ||
        careMethod == CareMethod.dryClean) {
      return WashGroup.handCare;
    }
    if (subType == 'jeans' ||
        material == 'denim' ||
        (colors.isNotEmpty && colors.first == 'denim')) {
      return WashGroup.denim;
    }
    final primary = colors.isEmpty ? null : ItemAttributes.color(colors.first);
    if (primary == null) return WashGroup.unsorted;
    return primary.tone == ColorTone.light ? WashGroup.light : WashGroup.dark;
  }
}

/// 바구니 옷의 세탁 그룹 요약(예: `흰옷·밝은색 2 · 어두운색·색깔 옷 3`). 빈 그룹은 뺀다.
String washGroupSummary(Iterable<Item> items) {
  final counts = <WashGroup, int>{};
  for (final i in items) {
    counts[i.washGroup] = (counts[i.washGroup] ?? 0) + 1;
  }
  return [
    for (final g in WashGroup.values)
      if (counts[g] != null) '${g.label} ${counts[g]}',
  ].join(' · ');
}

/// 홈 "오늘 입은 옷" 후보(FR-507). 보관·바구니에 담긴 옷은 빼고, 입은 옷은 최근 입은 순
/// (같으면 많이 입은 순), 입은 적 없는 옷은 최근 등록 순으로 뒤에 붙인다.
List<Item> todayWearCandidates(Iterable<Item> items, {int limit = 12}) {
  final active = [
    for (final i in items)
      if (!i.isArchived && !i.inLaundry) i,
  ];
  final worn =
      [
        for (final i in active)
          if (i.lastWornAt != null) i,
      ]..sort((a, b) {
        final byDate = b.lastWornAt!.compareTo(a.lastWornAt!);
        return byDate != 0 ? byDate : b.totalWears.compareTo(a.totalWears);
      });
  final fresh = [
    for (final i in active)
      if (i.lastWornAt == null) i,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return [...worn, ...fresh].take(limit).toList();
}

/// 사진 분류 라벨 → (종류, 세부 종류) 매핑(FR-514, data-model.md §3).
/// iOS Vision 식별자와 Android ML Kit 라벨(소문자·밑줄)을 함께 둔다.
const Map<String, (Category, String?)> visionLabelHints = {
  'jeans': (Category.bottom, 'jeans'),
  'hoodie': (Category.top, 'hoodie'),
  'jacket': (Category.outer, 'jacket'),
  'suit': (Category.outer, 'blazer'),
  'sneaker': (Category.shoes, 'sneakers'),
  'boot': (Category.shoes, 'boots'),
  'sandal': (Category.shoes, 'sandals'),
  'shoes': (Category.shoes, null),
  'footwear': (Category.shoes, null),
  'backpack': (Category.bag, 'backpack'),
  'bag': (Category.bag, null),
  'purse': (Category.bag, null),
  'hat': (Category.accessory, 'hat'),
  'baseball_hat': (Category.accessory, 'hat'),
  'sunhat': (Category.accessory, 'hat'),
  'cowboy_hat': (Category.accessory, 'hat'),
  'scarf': (Category.accessory, 'scarf'),
  'glove': (Category.accessory, 'gloves'),
  'sock': (Category.accessory, 'socks'),
  'sunglasses': (Category.accessory, 'eyewear'),
  'jewelry': (Category.accessory, 'jewelry'),
  'watch': (Category.accessory, 'watch'),
  'necktie': (Category.accessory, 'tie'),
  'bowtie': (Category.accessory, 'tie'),
  // Android ML Kit Image Labeling 기본 모델 라벨. jeans·jacket·hat·scarf·sunglasses·bag는
  // 위와 같은 키를 쓴다.
  'sneakers': (Category.shoes, 'sneakers'),
  'shoe': (Category.shoes, null),
  'shorts': (Category.bottom, 'shorts'),
  'leggings': (Category.bottom, 'leggings'),
  'dress': (Category.onepiece, 'dress'),
  'gown': (Category.onepiece, 'dress'),
  'outerwear': (Category.outer, null),
  'blazer': (Category.outer, 'blazer'),
  'jersey': (Category.top, null),
  'cap': (Category.accessory, 'hat'),
  'beanie': (Category.accessory, 'hat'),
  'tie': (Category.accessory, 'tie'),
  'handbag': (Category.bag, null),
  'glasses': (Category.accessory, 'eyewear'),
  'necklace': (Category.accessory, 'jewelry'),
  'bracelet': (Category.accessory, 'jewelry'),
  'bangle': (Category.accessory, 'jewelry'),
  'jewellery': (Category.accessory, 'jewelry'),
};

/// 사진 분류 라벨 → 소재 코드(Android ML Kit). 신뢰도 기준은 [visionHintMinConfidence].
const Map<String, String> visionMaterialHints = {
  'denim': 'denim',
  'wool': 'wool',
  'leather': 'leather',
  'cotton': 'cotton',
};

/// 사진 분류 힌트에 쓰는 최소 신뢰도(FR-514).
const double visionHintMinConfidence = 0.6;
