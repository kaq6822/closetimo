// #37·#41 — 옷장 목록 필터 계약. 영속화하지 않는 in-memory 값 객체다.
// data-model.md §1.4 / contracts/repositories.md §1 참조.

import 'item.dart';

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

  /// 이름·브랜드 검색어(FR-006, 대소문자 무시).
  final String query;

  /// 보관 축(#44). 기본은 활성 옷만.
  final ArchiveScope archive;

  /// 검색어를 제외한 조건(종류·용도)이 하나라도 걸려 있는지.
  bool get hasScope =>
      categories.isNotEmpty ||
      purposes.isNotEmpty ||
      archive != ArchiveScope.active;

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

  bool matches(Item item) {
    if (!archive.includes(item)) return false;
    if (categories.isNotEmpty && !categories.contains(item.category)) {
      return false;
    }
    if (purposes.isNotEmpty && !item.purposes.any(purposes.contains)) {
      return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final name = item.name.toLowerCase();
      final brand = (item.brand ?? '').toLowerCase();
      if (!name.contains(q) && !brand.contains(q)) return false;
    }
    return true;
  }

  ItemFilter copyWith({
    Set<Category>? categories,
    Set<ItemPurpose>? purposes,
    String? query,
    ArchiveScope? archive,
  }) => ItemFilter(
    categories: categories ?? this.categories,
    purposes: purposes ?? this.purposes,
    query: query ?? this.query,
    archive: archive ?? this.archive,
  );

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.query == query &&
      other.archive == archive &&
      _sameSet(other.categories, categories) &&
      _sameSet(other.purposes, purposes);

  @override
  int get hashCode => Object.hash(
    query,
    archive,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(purposes),
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
