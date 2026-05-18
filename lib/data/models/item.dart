// data-model.md §1 Item 컬렉션. spec.md Key Entities + FR-001~011, 022.

import 'package:isar/isar.dart';

part 'item.g.dart';

@collection
class Item {
  Item({
    required this.name,
    required this.category,
    required this.washCycle,
    required this.createdAt,
    this.brand,
    this.careMethod = CareMethod.machine,
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

  Id id = Isar.autoIncrement;

  late String name;
  String? brand;

  @Index()
  @enumerated
  late Category category;

  @enumerated
  CareMethod careMethod;

  @Index()
  @enumerated
  ItemStatus status;

  late int washCycle;
  int wearSinceWash;
  int totalWears;

  @Index(type: IndexType.value)
  DateTime? lastWornAt;

  DateTime? lastWashedAt;
  DateTime? purchasedAt;

  @Index()
  bool inLaundry;
  String? imagePath;
  int fallbackColor;

  @Index(type: IndexType.value)
  late DateTime createdAt;
}

/// Isar `@enumerated`는 enum을 ordinal(index)로 저장한다. 새 값을 enum 중간에
/// 삽입하면 기존 데이터가 깨지므로 **끝에만 추가**한다.
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
      };

  /// 홈 대시보드 2x2 카드 매핑(FR-019).
  /// 아우터·상의·하의 외의 모든 카테고리는 "기타" 버킷에 합산된다.
  Category get homeBucket => switch (this) {
        Category.outer || Category.top || Category.bottom => this,
        _ => Category.etc,
      };
}

enum CareMethod { dryClean, machine, handWash }

extension CareMethodLabel on CareMethod {
  String get label => switch (this) {
        CareMethod.dryClean => '드라이클리닝',
        CareMethod.machine => '기계세탁',
        CareMethod.handWash => '핸드워시',
      };

  String get code => switch (this) {
        CareMethod.dryClean => 'DRY CLEAN',
        CareMethod.machine => 'MACHINE',
        CareMethod.handWash => 'HAND WASH',
      };
}

enum ItemStatus { clean, dirty }
