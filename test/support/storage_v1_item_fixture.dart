// 저장소 v1(#41·#45 이전) Item 스키마의 테스트 고정본.
//
// 마이그레이션 테스트가 "구 앱이 디스크에 쓴 데이터"를 재현하도록, 변경 직전
// 커밋(e0c0530)의 `lib/data/models/item.g.dart` 직렬화 코드를 이름만 바꿔
// 옮겨 두었다(쿼리 확장 제외). 컬렉션 이름은 'Item'으로 동일하다.
// 앱 코드에서 사용하지 않는다. 이 파일은 build_runner 대상이 아니다.

// ignore_for_file: type=lint, invalid_use_of_protected_member, non_constant_identifier_names

import 'package:closetimo/data/models/item.dart'
    show Category, CareMethod, ItemStatus;
import 'package:isar_plus/isar_plus.dart';

/// v1 Item 필드 집합(careMode·purposes 없음).
class ItemV1 {
  ItemV1({
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

  int id = 0;
  String name;
  String? brand;
  Category category;
  CareMethod careMethod;
  ItemStatus status;
  int washCycle;
  int wearSinceWash;
  int totalWears;
  DateTime? lastWornAt;
  DateTime? lastWashedAt;
  DateTime? purchasedAt;
  bool inLaundry;
  String? imagePath;
  int fallbackColor;
  DateTime createdAt;
}

extension GetItemV1Collection on Isar {
  IsarCollection<int, ItemV1> get itemsV1 => this.collection();
}

final ItemV1Schema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Item',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'name', type: IsarType.string),
      IsarPropertySchema(name: 'brand', type: IsarType.string),
      IsarPropertySchema(
        name: 'category',
        type: IsarType.byte,

        enumMap: {
          "outer": 0,
          "top": 1,
          "bottom": 2,
          "onepiece": 3,
          "shoes": 4,
          "bag": 5,
          "accessory": 6,
          "activewear": 7,
          "etc": 8,
        },
      ),
      IsarPropertySchema(
        name: 'careMethod',
        type: IsarType.byte,

        enumMap: {"dryClean": 0, "machine": 1, "handWash": 2},
      ),
      IsarPropertySchema(
        name: 'status',
        type: IsarType.byte,

        enumMap: {"clean": 0, "dirty": 1},
      ),
      IsarPropertySchema(name: 'washCycle', type: IsarType.long),
      IsarPropertySchema(name: 'wearSinceWash', type: IsarType.long),
      IsarPropertySchema(name: 'totalWears', type: IsarType.long),
      IsarPropertySchema(name: 'lastWornAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'lastWashedAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'purchasedAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'inLaundry', type: IsarType.bool),
      IsarPropertySchema(name: 'imagePath', type: IsarType.string),
      IsarPropertySchema(name: 'fallbackColor', type: IsarType.long),
      IsarPropertySchema(name: 'createdAt', type: IsarType.dateTime),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'category',
        properties: ["category"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'status',
        properties: ["status"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'lastWornAt',
        properties: ["lastWornAt"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'inLaundry',
        properties: ["inLaundry"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'createdAt',
        properties: ["createdAt"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, ItemV1>(
    serialize: serializeItemV1,
    deserialize: deserializeItemV1,
    deserializeProperty: deserializeItemV1Prop,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeItemV1(IsarWriter writer, ItemV1 object) {
  IsarCore.writeString(writer, 1, object.name);
  {
    final value = object.brand;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  IsarCore.writeByte(writer, 3, object.category.index);
  IsarCore.writeByte(writer, 4, object.careMethod.index);
  IsarCore.writeByte(writer, 5, object.status.index);
  IsarCore.writeLong(writer, 6, object.washCycle);
  IsarCore.writeLong(writer, 7, object.wearSinceWash);
  IsarCore.writeLong(writer, 8, object.totalWears);
  IsarCore.writeLong(
    writer,
    9,
    object.lastWornAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808,
  );
  IsarCore.writeLong(
    writer,
    10,
    object.lastWashedAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808,
  );
  IsarCore.writeLong(
    writer,
    11,
    object.purchasedAt?.toUtc().microsecondsSinceEpoch ?? -9223372036854775808,
  );
  IsarCore.writeBool(writer, 12, value: object.inLaundry);
  {
    final value = object.imagePath;
    if (value == null) {
      IsarCore.writeNull(writer, 13);
    } else {
      IsarCore.writeString(writer, 13, value);
    }
  }
  IsarCore.writeLong(writer, 14, object.fallbackColor);
  IsarCore.writeLong(
    writer,
    15,
    object.createdAt.toUtc().microsecondsSinceEpoch,
  );
  return object.id;
}

@isarProtected
ItemV1 deserializeItemV1(IsarReader reader) {
  final String _name;
  _name = IsarCore.readString(reader, 1) ?? '';
  final String? _brand;
  _brand = IsarCore.readString(reader, 2);
  final Category _category;
  {
    if (IsarCore.readNull(reader, 3)) {
      _category = Category.outer;
    } else {
      _category = _v1Category[IsarCore.readByte(reader, 3)] ?? Category.outer;
    }
  }
  final CareMethod _careMethod;
  {
    if (IsarCore.readNull(reader, 4)) {
      _careMethod = CareMethod.machine;
    } else {
      _careMethod =
          _v1CareMethod[IsarCore.readByte(reader, 4)] ?? CareMethod.machine;
    }
  }
  final ItemStatus _status;
  {
    if (IsarCore.readNull(reader, 5)) {
      _status = ItemStatus.clean;
    } else {
      _status = _v1Status[IsarCore.readByte(reader, 5)] ?? ItemStatus.clean;
    }
  }
  final int _washCycle;
  _washCycle = IsarCore.readLong(reader, 6);
  final int _wearSinceWash;
  {
    final value = IsarCore.readLong(reader, 7);
    if (value == -9223372036854775808) {
      _wearSinceWash = 0;
    } else {
      _wearSinceWash = value;
    }
  }
  final int _totalWears;
  {
    final value = IsarCore.readLong(reader, 8);
    if (value == -9223372036854775808) {
      _totalWears = 0;
    } else {
      _totalWears = value;
    }
  }
  final DateTime? _lastWornAt;
  {
    final value = IsarCore.readLong(reader, 9);
    if (value == -9223372036854775808) {
      _lastWornAt = null;
    } else {
      _lastWornAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final DateTime? _lastWashedAt;
  {
    final value = IsarCore.readLong(reader, 10);
    if (value == -9223372036854775808) {
      _lastWashedAt = null;
    } else {
      _lastWashedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final DateTime? _purchasedAt;
  {
    final value = IsarCore.readLong(reader, 11);
    if (value == -9223372036854775808) {
      _purchasedAt = null;
    } else {
      _purchasedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final bool _inLaundry;
  _inLaundry = IsarCore.readBool(reader, 12);
  final String? _imagePath;
  _imagePath = IsarCore.readString(reader, 13);
  final int _fallbackColor;
  {
    final value = IsarCore.readLong(reader, 14);
    if (value == -9223372036854775808) {
      _fallbackColor = 0xFFE5E4DC;
    } else {
      _fallbackColor = value;
    }
  }
  final DateTime _createdAt;
  {
    final value = IsarCore.readLong(reader, 15);
    if (value == -9223372036854775808) {
      _createdAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      _createdAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final object = ItemV1(
    name: _name,
    brand: _brand,
    category: _category,
    careMethod: _careMethod,
    status: _status,
    washCycle: _washCycle,
    wearSinceWash: _wearSinceWash,
    totalWears: _totalWears,
    lastWornAt: _lastWornAt,
    lastWashedAt: _lastWashedAt,
    purchasedAt: _purchasedAt,
    inLaundry: _inLaundry,
    imagePath: _imagePath,
    fallbackColor: _fallbackColor,
    createdAt: _createdAt,
  );
  object.id = IsarCore.readId(reader);
  return object;
}

@isarProtected
dynamic deserializeItemV1Prop(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2);
    case 3:
      {
        if (IsarCore.readNull(reader, 3)) {
          return Category.outer;
        } else {
          return _v1Category[IsarCore.readByte(reader, 3)] ?? Category.outer;
        }
      }
    case 4:
      {
        if (IsarCore.readNull(reader, 4)) {
          return CareMethod.machine;
        } else {
          return _v1CareMethod[IsarCore.readByte(reader, 4)] ??
              CareMethod.machine;
        }
      }
    case 5:
      {
        if (IsarCore.readNull(reader, 5)) {
          return ItemStatus.clean;
        } else {
          return _v1Status[IsarCore.readByte(reader, 5)] ?? ItemStatus.clean;
        }
      }
    case 6:
      return IsarCore.readLong(reader, 6);
    case 7:
      {
        final value = IsarCore.readLong(reader, 7);
        if (value == -9223372036854775808) {
          return 0;
        } else {
          return value;
        }
      }
    case 8:
      {
        final value = IsarCore.readLong(reader, 8);
        if (value == -9223372036854775808) {
          return 0;
        } else {
          return value;
        }
      }
    case 9:
      {
        final value = IsarCore.readLong(reader, 9);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 10:
      {
        final value = IsarCore.readLong(reader, 10);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 11:
      {
        final value = IsarCore.readLong(reader, 11);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 12:
      return IsarCore.readBool(reader, 12);
    case 13:
      return IsarCore.readString(reader, 13);
    case 14:
      {
        final value = IsarCore.readLong(reader, 14);
        if (value == -9223372036854775808) {
          return 0xFFE5E4DC;
        } else {
          return value;
        }
      }
    case 15:
      {
        final value = IsarCore.readLong(reader, 15);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

const _v1Category = {
  0: Category.outer,
  1: Category.top,
  2: Category.bottom,
  3: Category.onepiece,
  4: Category.shoes,
  5: Category.bag,
  6: Category.accessory,
  7: Category.activewear,
  8: Category.etc,
};
const _v1CareMethod = {
  0: CareMethod.dryClean,
  1: CareMethod.machine,
  2: CareMethod.handWash,
};
const _v1Status = {0: ItemStatus.clean, 1: ItemStatus.dirty};
