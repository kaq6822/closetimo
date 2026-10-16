// data-model.md §1 Item 컬렉션. spec.md Key Entities + FR-001~011, 022.

import 'package:isar_plus/isar_plus.dart';

part 'item.g.dart';

@collection
class Item {
  Item({
    required this.name,
    required this.category,
    required this.washCycle,
    required this.createdAt,
    this.brand,
    this.careMethod = CareMethod.unspecified,
    this.careMode = CareMode.wearCycle,
    this.purposes = const [],
    this.archivedAt,
    this.archiveReason = ArchiveReason.unspecified,
    this.status = ItemStatus.clean,
    this.wearSinceWash = 0,
    this.totalWears = 0,
    this.lastWornAt,
    this.lastWashedAt,
    this.purchasedAt,
    this.inLaundry = false,
    this.imagePath,
    this.fallbackColor = 0xFFE5E4DC,
  });

  int id = 0;

  late String name;
  String? brand;

  @Index()
  late Category category;

  /// 관리 방법(#45). 모르면 [CareMethod.unspecified]. 실제 세탁 조건은 옷의
  /// 케어 라벨을 따르며, 앱은 이 값으로 세탁 조건을 추정하지 않는다.
  CareMethod careMethod;

  @Index()
  ItemStatus status;

  /// 착용 횟수 기준 관리 주기(≥ 1). [careMode]가 manual이어도 값은 보존해
  /// 다시 켰을 때 복원한다.
  late int washCycle;
  int wearSinceWash;
  int totalWears;

  @Index()
  DateTime? lastWornAt;

  DateTime? lastWashedAt;
  DateTime? purchasedAt;

  @Index()
  bool inLaundry;
  String? imagePath;
  int fallbackColor;

  @Index()
  late DateTime createdAt;

  // ── 저장소 v2(#41·#45) 추가 필드 ──
  // Isar Plus는 선언 순서로 property index를 부여하므로 새 필드는 항상 클래스
  // 끝에 추가해 기존 필드의 위치를 바꾸지 않는다.

  /// 관리 권장 방식(#45). [CareMode.manual]이면 착용 횟수로 `dirty`가 되지 않고
  /// 사용자가 직접 세탁 바구니에 담는다. 필드가 없는 구 데이터는 constructor
  /// 기본값인 [CareMode.wearCycle]로 읽힌다.
  CareMode careMode;

  /// 선택 용도 축(#41). 종류([category])와 독립이며 비어 있을 수 있다.
  /// 같은 값이 중복되지 않도록 repository가 정규화해 저장한다. 기본값은 불변
  /// 목록이므로 제자리 수정하지 말고 새 목록을 대입한다.
  List<ItemPurpose> purposes;

  // ── 보관(#44) 추가 필드. 필드가 없는 구 데이터는 null(= 활성)로 읽힌다. ──

  /// 보관한 시각. null이 아니면 보관 상태이며 활성 옷장·홈 통계·검색·세탁
  /// 바구니에서 제외된다. 착용·세탁 기록과 카운터는 그대로 유지한다.
  DateTime? archivedAt;

  /// 보관 사유(선택). 보관하지 않았거나 사유를 고르지 않았으면
  /// [ArchiveReason.unspecified]다(Isar Plus는 nullable enum을 지원하지 않는다).
  /// 보관 여부는 이 값이 아니라 [archivedAt]으로 판단한다.
  ArchiveReason archiveReason;
}

/// 보관 사유(#44). ordinal 저장이므로 **끝에만 추가**한다.
/// 두 사유 모두 활성 통계·홈 집계·검색·바구니에서 제외하는 정책은 같고,
/// 의미(다시 꺼낼 예정인지)만 다르다. 둘 다 복원할 수 있다.
/// - [unspecified]: 사유 없음(활성 옷이거나 사유를 고르지 않은 보관).
/// - [seasonal]: 계절이 지나 잠시 넣어 둔 옷. 다시 꺼낼 예정.
/// - [noLongerOwned]: 처분·양도 등으로 더 이상 갖고 있지 않은 옷. 기록 보존용.
enum ArchiveReason { unspecified, seasonal, noLongerOwned }

extension ArchiveReasonLabel on ArchiveReason {
  String get label => switch (this) {
    ArchiveReason.unspecified => '사유 없음',
    ArchiveReason.seasonal => '계절 보관',
    ArchiveReason.noLongerOwned => '더 이상 갖고 있지 않음',
  };
}

/// 보관 상태 규칙(#44).
extension ItemArchiveRules on Item {
  /// 보관 중인지. [Item.archivedAt]이 단일 진실 원천이다.
  bool get isArchived => archivedAt != null;
}

/// 옷의 종류(#41). Isar Plus는 enum을 ordinal(index)로 저장하므로 값의 순서를
/// 바꾸거나 중간에 삽입·삭제하지 않고 **끝에만 추가**한다.
///
/// - [uncategorized](미분류): 아직 종류를 정하지 않은 옷. 새 옷의 기본값.
/// - [etc](기타): 다른 종류에 속하지 않는다고 사용자가 정한 옷(개별 종류).
/// - [activewear](운동복): **저장 호환용 legacy 값**. 운동은 종류가 아니라
///   용도([ItemPurpose.sport]) 축이므로 새로 선택할 수 없고, 저장소 v2
///   마이그레이션이 `uncategorized + 용도 운동`으로 옮긴다.
enum Category {
  outer,
  top,
  bottom,
  onepiece,
  shoes,
  bag,
  accessory,
  activewear,
  etc,
  uncategorized;

  /// 등록 폼·옷장 필터에 노출하는 선택 가능한 종류(표시 순서).
  static const List<Category> selectable = [
    uncategorized,
    outer,
    top,
    bottom,
    onepiece,
    shoes,
    bag,
    accessory,
    etc,
  ];
}

extension CategoryLabel on Category {
  String get label => switch (this) {
    Category.outer => '아우터',
    Category.top => '상의',
    Category.bottom => '하의',
    Category.onepiece => '원피스',
    Category.shoes => '신발',
    Category.bag => '가방',
    Category.accessory => '액세서리',
    Category.activewear => '운동복',
    Category.etc => '기타',
    Category.uncategorized => '미분류',
  };

  /// 홈 대시보드 2x2 카드 버킷(FR-019, #37).
  HomeBucket get homeBucket => switch (this) {
    Category.outer => HomeBucket.outer,
    Category.top => HomeBucket.top,
    Category.bottom => HomeBucket.bottom,
    _ => HomeBucket.others,
  };
}

/// 홈 2x2 카드 버킷(#37). 저장하지 않는 집계 전용 값이다.
///
/// [others]('그 외')는 아우터·상의·하의를 **제외한 모든 종류의 합산**이며
/// (원피스·신발·가방·액세서리·기타·미분류, legacy 운동복 포함), 개별 종류인
/// [Category.etc]('기타')와 다르다. 네 버킷의 합은 항상 전체 옷 수와 같다.
enum HomeBucket {
  outer,
  top,
  bottom,
  others;

  /// 이 버킷에 속하는 종류 집합. 홈 집계와 카드 이동 필터가 함께 사용한다.
  Set<Category> get categories => {
    for (final c in Category.values)
      if (c.homeBucket == this) c,
  };

  String get label => switch (this) {
    HomeBucket.outer => Category.outer.label,
    HomeBucket.top => Category.top.label,
    HomeBucket.bottom => Category.bottom.label,
    HomeBucket.others => '그 외',
  };
}

/// 선택 용도 축(#41). 종류와 독립이며 여러 개를 가질 수 있다. ordinal 저장이므로
/// **끝에만 추가**한다. 후속 속성 확장(#46)은 이 enum에 값을 덧붙인다.
enum ItemPurpose { sport }

extension ItemPurposeLabel on ItemPurpose {
  String get label => switch (this) {
    ItemPurpose.sport => '운동',
  };
}

/// 관리 방법. ordinal 저장이므로 **끝에만 추가**한다.
/// [unspecified]('미지정')는 관리 방법을 정하지 않은 옷이다(#45).
enum CareMethod { dryClean, machine, handWash, unspecified }

extension CareMethodLabel on CareMethod {
  String get label => switch (this) {
    CareMethod.dryClean => '드라이클리닝',
    CareMethod.machine => '기계세탁',
    CareMethod.handWash => '핸드워시',
    CareMethod.unspecified => '미지정',
  };

  String get code => switch (this) {
    CareMethod.dryClean => 'DRY CLEAN',
    CareMethod.machine => 'MACHINE',
    CareMethod.handWash => 'HAND WASH',
    CareMethod.unspecified => 'NOT SET',
  };
}

/// 관리 권장 방식(#45). ordinal 저장이므로 **끝에만 추가**한다.
/// - [wearCycle]: 착용 횟수가 [Item.washCycle]에 도달하면 `dirty`(관리 필요).
/// - [manual]: 횟수로 상태를 바꾸지 않는다. 필요할 때 사용자가 직접 바구니에 담는다.
enum CareMode { wearCycle, manual }

enum ItemStatus { clean, dirty }

/// 관리 상태 규칙(FR-011, #45). 모든 repository는 상태를 이 규칙으로 계산한다.
extension ItemCareRules on Item {
  /// 착용 횟수 기준 관리가 적용되는지.
  bool get tracksWearCycle => careMode == CareMode.wearCycle;

  /// 현재 카운터·관리 방식으로 계산한 상태. manual이면 항상 `clean`이다.
  /// (`clean`은 "횟수 기준 관리 권장 없음"이며 실제 청결을 뜻하지 않는다.)
  ItemStatus get derivedStatus => tracksWearCycle && wearSinceWash >= washCycle
      ? ItemStatus.dirty
      : ItemStatus.clean;
}
