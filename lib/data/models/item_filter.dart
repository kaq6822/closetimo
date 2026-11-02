// #37·#41 — 옷장 목록 필터 계약. 영속화하지 않는 in-memory 값 객체다.
// data-model.md §1.4 / contracts/repositories.md §1 참조.

import 'item.dart';
import 'item_attributes.dart';
import 'item_tags.dart';

/// 옷장 목록·홈 카드 이동이 공유하는 필터.
///
/// - 같은 축 안에서는 OR, 축 사이에서는 AND로 결합한다.
/// - 축의 집합이 비어 있으면 해당 축은 제한하지 않는다(전체).
/// - 홈 카드 이동은 [ItemFilter.homeBucket]을 사용하므로 카드 집계와 목록
///   범위가 항상 같다([HomeBucket.categories]).
/// - 보관 축([archive], #44)의 기본값은 [ArchiveScope.active]라 별도 지정이
///   없으면 보관한 옷은 옷장·검색에서 빠진다.
class ItemFilter {
  const ItemFilter({
    this.categories = const {},
    this.purposes = const {},
    this.query = '',
    this.archive = ArchiveScope.active,
    this.readyToWear = false,
    this.tags = const {},
    this.subTypes = const {},
    this.colors = const {},
    this.seasons = const {},
    this.season,
  });

  /// 개별 종류 1개만 보는 필터(옷장 종류 칩).
  factory ItemFilter.category(Category category) =>
      ItemFilter(categories: {category});

  /// 홈 카드 버킷과 같은 범위의 필터(예: '그 외' 합산).
  factory ItemFilter.homeBucket(HomeBucket bucket) =>
      ItemFilter(categories: bucket.categories);

  /// 종류 축. 비어 있으면 전체.
  final Set<Category> categories;

  /// 용도 축. 비어 있으면 전체.
  final Set<ItemPurpose> purposes;

  /// 이름·브랜드·태그 검색어(FR-006, #46, 대소문자 무시).
  final String query;

  /// 보관 축(#44). 기본은 활성 옷만.
  final ArchiveScope archive;

  /// '입을 수 있음'만 남길지(#43). [ItemReadiness.isReadyToWear] 참조.
  /// 검색어처럼 라우트 쿼리에 싣지 않는 화면 State 조건이다.
  final bool readyToWear;

  /// 사용자 태그 축(#46). 비어 있으면 전체. 같은 축 안은 OR(선택한 태그 중
  /// 하나라도 붙은 옷), 다른 축과는 AND다. 태그는 정규화된 표기로 비교한다.
  final Set<String> tags;

  /// 세부 종류 축(005 FR-509). 코드 집합, 비어 있으면 전체.
  final Set<String> subTypes;

  /// 색상 축(005 FR-509). 옷의 색상 중 하나라도 포함되면 통과.
  final Set<String> colors;

  /// 계절 축(005 FR-509). 옷의 계절 중 하나라도 포함되면 통과. 계절을 정하지 않은
  /// 옷은 이 축을 통과하지 못한다(명시적으로 고른 계절만 찾는다).
  final Set<Season> seasons;

  /// '이번 계절' 빠른 조건(005 FR-510). 이 계절을 포함하거나 계절을 정하지 않은 옷.
  /// 화면 State 조건이며 라우트 쿼리에 싣지 않는다.
  final Season? season;

  /// 상세 필터 시트가 다루는 축(세부 종류·색상·계절·용도) 조건 수. 태그는 별도 칩이다.
  int get detailCount =>
      subTypes.length + colors.length + seasons.length + purposes.length;

  /// 검색어를 제외한 조건(종류·용도·보관·입을 수 있음·태그·속성)이 하나라도 걸려 있는지.
  bool get hasScope =>
      categories.isNotEmpty ||
      purposes.isNotEmpty ||
      archive != ArchiveScope.active ||
      readyToWear ||
      tags.isNotEmpty ||
      subTypes.isNotEmpty ||
      colors.isNotEmpty ||
      seasons.isNotEmpty ||
      season != null;

  /// 조건이 하나라도 걸려 있는지(검색어 포함).
  bool get isActive => hasScope || query.trim().isNotEmpty;

  /// 종류 축이 홈 버킷과 정확히 같은 범위이면 그 버킷, 아니면 null.
  /// 단일 종류 버킷(아우터 등)은 개별 종류 필터와 같으므로 [HomeBucket.others]만
  /// 합산 버킷으로 인식한다.
  HomeBucket? get groupBucket {
    if (categories.length < 2) return null;
    for (final bucket in HomeBucket.values) {
      final set = bucket.categories;
      if (set.length == categories.length && set.containsAll(categories)) {
        return bucket;
      }
    }
    return null;
  }

  /// 선택한 태그 중 하나라도 옷에 붙어 있는가(대소문자 무시).
  bool _hasAnyTag(Item item) =>
      item.tags.any((t) => tags.any((wanted) => isSameTag(t, wanted)));

  bool matches(Item item) {
    if (!archive.includes(item)) return false;
    if (readyToWear && !item.isReadyToWear) return false;
    if (categories.isNotEmpty && !categories.contains(item.category)) {
      return false;
    }
    if (purposes.isNotEmpty && !item.purposes.any(purposes.contains)) {
      return false;
    }
    if (tags.isNotEmpty && !_hasAnyTag(item)) return false;
    if (subTypes.isNotEmpty && !subTypes.contains(item.subType)) return false;
    if (colors.isNotEmpty && !item.colors.any(colors.contains)) return false;
    if (seasons.isNotEmpty && !item.seasons.any(seasons.contains)) {
      return false;
    }
    if (season case final s?
        when item.seasons.isNotEmpty && !item.seasons.contains(s)) {
      return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final name = item.name.toLowerCase();
      final brand = (item.brand ?? '').toLowerCase();
      // #46 — 태그도 검색어로 찾는다(이름·브랜드·태그 중 하나라도 포함).
      // 005 FR-511 — 세부 종류·색상·소재·패턴·계절 라벨도 찾는다.
      if (!name.contains(q) &&
          !brand.contains(q) &&
          !item.tags.any((t) => t.toLowerCase().contains(q)) &&
          !attributeSearchLabels(item).any((l) => l.contains(q))) {
        return false;
      }
    }
    return true;
  }

  ItemFilter copyWith({
    Set<Category>? categories,
    Set<ItemPurpose>? purposes,
    String? query,
    ArchiveScope? archive,
    bool? readyToWear,
    Set<String>? tags,
    Set<String>? subTypes,
    Set<String>? colors,
    Set<Season>? seasons,
    Season? season,
    bool clearSeason = false,
  }) => ItemFilter(
    categories: categories ?? this.categories,
    purposes: purposes ?? this.purposes,
    query: query ?? this.query,
    archive: archive ?? this.archive,
    readyToWear: readyToWear ?? this.readyToWear,
    tags: tags ?? this.tags,
    subTypes: subTypes ?? this.subTypes,
    colors: colors ?? this.colors,
    seasons: seasons ?? this.seasons,
    season: clearSeason ? null : (season ?? this.season),
  );

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.query == query &&
      other.archive == archive &&
      other.readyToWear == readyToWear &&
      other.season == season &&
      _sameSet(other.categories, categories) &&
      _sameSet(other.purposes, purposes) &&
      _sameSet(other.tags, tags) &&
      _sameSet(other.subTypes, subTypes) &&
      _sameSet(other.colors, colors) &&
      _sameSet(other.seasons, seasons);

  @override
  int get hashCode => Object.hash(
    query,
    archive,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(purposes),
    readyToWear,
    Object.hashAllUnordered(tags),
    Object.hashAllUnordered(subTypes),
    Object.hashAllUnordered(colors),
    Object.hashAllUnordered(seasons),
    season,
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}

/// 보관 상태 축(#44). 영속화하지 않는다.
enum ArchiveScope {
  /// 활성(보관하지 않은) 옷만. [ItemFilter]의 기본값.
  active,

  /// 보관한 옷만(보관함 화면).
  archived,

  /// 보관 여부와 무관하게 전체.
  all;

  bool includes(Item item) => switch (this) {
    ArchiveScope.active => !item.isArchived,
    ArchiveScope.archived => item.isArchived,
    ArchiveScope.all => true,
  };
}

/// '입을 수 있음' 판정(#43, spec FR-005a). **앱이 기록한 상태만** 본다.
///
/// - `status == clean`: 착용 횟수 기준 관리 권장(`dirty`) 전. 실제 청결을 뜻하지
///   않는다(data-model.md §1.2).
/// - `!inLaundry`: 세탁 바구니에 담겨 있지 않음.
/// - `!isArchived`: 보관한 옷(#44)은 제외한다.
extension ItemReadiness on Item {
  bool get isReadyToWear =>
      status == ItemStatus.clean && !inLaundry && !isArchived;
}
