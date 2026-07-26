// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetItemCollection on Isar {
  IsarCollection<int, Item> get items => this.collection();
}

final ItemSchema = IsarGeneratedSchema(
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
  converter: IsarObjectConverter<int, Item>(
    serialize: serializeItem,
    deserialize: deserializeItem,
    deserializeProperty: deserializeItemProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeItem(IsarWriter writer, Item object) {
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
Item deserializeItem(IsarReader reader) {
  final String _name;
  _name = IsarCore.readString(reader, 1) ?? '';
  final String? _brand;
  _brand = IsarCore.readString(reader, 2);
  final Category _category;
  {
    if (IsarCore.readNull(reader, 3)) {
      _category = Category.outer;
    } else {
      _category = _itemCategory[IsarCore.readByte(reader, 3)] ?? Category.outer;
    }
  }
  final CareMethod _careMethod;
  {
    if (IsarCore.readNull(reader, 4)) {
      _careMethod = CareMethod.machine;
    } else {
      _careMethod =
          _itemCareMethod[IsarCore.readByte(reader, 4)] ?? CareMethod.machine;
    }
  }
  final ItemStatus _status;
  {
    if (IsarCore.readNull(reader, 5)) {
      _status = ItemStatus.clean;
    } else {
      _status = _itemStatus[IsarCore.readByte(reader, 5)] ?? ItemStatus.clean;
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
  final object = Item(
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
dynamic deserializeItemProp(IsarReader reader, int property) {
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
          return _itemCategory[IsarCore.readByte(reader, 3)] ?? Category.outer;
        }
      }
    case 4:
      {
        if (IsarCore.readNull(reader, 4)) {
          return CareMethod.machine;
        } else {
          return _itemCareMethod[IsarCore.readByte(reader, 4)] ??
              CareMethod.machine;
        }
      }
    case 5:
      {
        if (IsarCore.readNull(reader, 5)) {
          return ItemStatus.clean;
        } else {
          return _itemStatus[IsarCore.readByte(reader, 5)] ?? ItemStatus.clean;
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

sealed class _ItemUpdate {
  bool call({
    required int id,
    String? name,
    String? brand,
    Category? category,
    CareMethod? careMethod,
    ItemStatus? status,
    int? washCycle,
    int? wearSinceWash,
    int? totalWears,
    DateTime? lastWornAt,
    DateTime? lastWashedAt,
    DateTime? purchasedAt,
    bool? inLaundry,
    String? imagePath,
    int? fallbackColor,
    DateTime? createdAt,
  });
}

class _ItemUpdateImpl implements _ItemUpdate {
  const _ItemUpdateImpl(this.collection);

  final IsarCollection<int, Item> collection;

  @override
  bool call({
    required int id,
    Object? name = ignore,
    Object? brand = ignore,
    Object? category = ignore,
    Object? careMethod = ignore,
    Object? status = ignore,
    Object? washCycle = ignore,
    Object? wearSinceWash = ignore,
    Object? totalWears = ignore,
    Object? lastWornAt = ignore,
    Object? lastWashedAt = ignore,
    Object? purchasedAt = ignore,
    Object? inLaundry = ignore,
    Object? imagePath = ignore,
    Object? fallbackColor = ignore,
    Object? createdAt = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (name != ignore) 1: name as String?,
            if (brand != ignore) 2: brand as String?,
            if (category != ignore) 3: category as Category?,
            if (careMethod != ignore) 4: careMethod as CareMethod?,
            if (status != ignore) 5: status as ItemStatus?,
            if (washCycle != ignore) 6: washCycle as int?,
            if (wearSinceWash != ignore) 7: wearSinceWash as int?,
            if (totalWears != ignore) 8: totalWears as int?,
            if (lastWornAt != ignore) 9: lastWornAt as DateTime?,
            if (lastWashedAt != ignore) 10: lastWashedAt as DateTime?,
            if (purchasedAt != ignore) 11: purchasedAt as DateTime?,
            if (inLaundry != ignore) 12: inLaundry as bool?,
            if (imagePath != ignore) 13: imagePath as String?,
            if (fallbackColor != ignore) 14: fallbackColor as int?,
            if (createdAt != ignore) 15: createdAt as DateTime?,
          },
        ) >
        0;
  }
}

sealed class _ItemUpdateAll {
  int call({
    required List<int> id,
    String? name,
    String? brand,
    Category? category,
    CareMethod? careMethod,
    ItemStatus? status,
    int? washCycle,
    int? wearSinceWash,
    int? totalWears,
    DateTime? lastWornAt,
    DateTime? lastWashedAt,
    DateTime? purchasedAt,
    bool? inLaundry,
    String? imagePath,
    int? fallbackColor,
    DateTime? createdAt,
  });
}

class _ItemUpdateAllImpl implements _ItemUpdateAll {
  const _ItemUpdateAllImpl(this.collection);

  final IsarCollection<int, Item> collection;

  @override
  int call({
    required List<int> id,
    Object? name = ignore,
    Object? brand = ignore,
    Object? category = ignore,
    Object? careMethod = ignore,
    Object? status = ignore,
    Object? washCycle = ignore,
    Object? wearSinceWash = ignore,
    Object? totalWears = ignore,
    Object? lastWornAt = ignore,
    Object? lastWashedAt = ignore,
    Object? purchasedAt = ignore,
    Object? inLaundry = ignore,
    Object? imagePath = ignore,
    Object? fallbackColor = ignore,
    Object? createdAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (name != ignore) 1: name as String?,
      if (brand != ignore) 2: brand as String?,
      if (category != ignore) 3: category as Category?,
      if (careMethod != ignore) 4: careMethod as CareMethod?,
      if (status != ignore) 5: status as ItemStatus?,
      if (washCycle != ignore) 6: washCycle as int?,
      if (wearSinceWash != ignore) 7: wearSinceWash as int?,
      if (totalWears != ignore) 8: totalWears as int?,
      if (lastWornAt != ignore) 9: lastWornAt as DateTime?,
      if (lastWashedAt != ignore) 10: lastWashedAt as DateTime?,
      if (purchasedAt != ignore) 11: purchasedAt as DateTime?,
      if (inLaundry != ignore) 12: inLaundry as bool?,
      if (imagePath != ignore) 13: imagePath as String?,
      if (fallbackColor != ignore) 14: fallbackColor as int?,
      if (createdAt != ignore) 15: createdAt as DateTime?,
    });
  }
}

extension ItemUpdate on IsarCollection<int, Item> {
  _ItemUpdate get update => _ItemUpdateImpl(this);

  _ItemUpdateAll get updateAll => _ItemUpdateAllImpl(this);
}

sealed class _ItemQueryUpdate {
  int call({
    String? name,
    String? brand,
    Category? category,
    CareMethod? careMethod,
    ItemStatus? status,
    int? washCycle,
    int? wearSinceWash,
    int? totalWears,
    DateTime? lastWornAt,
    DateTime? lastWashedAt,
    DateTime? purchasedAt,
    bool? inLaundry,
    String? imagePath,
    int? fallbackColor,
    DateTime? createdAt,
  });
}

class _ItemQueryUpdateImpl implements _ItemQueryUpdate {
  const _ItemQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Item> query;
  final int? limit;

  @override
  int call({
    Object? name = ignore,
    Object? brand = ignore,
    Object? category = ignore,
    Object? careMethod = ignore,
    Object? status = ignore,
    Object? washCycle = ignore,
    Object? wearSinceWash = ignore,
    Object? totalWears = ignore,
    Object? lastWornAt = ignore,
    Object? lastWashedAt = ignore,
    Object? purchasedAt = ignore,
    Object? inLaundry = ignore,
    Object? imagePath = ignore,
    Object? fallbackColor = ignore,
    Object? createdAt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (name != ignore) 1: name as String?,
      if (brand != ignore) 2: brand as String?,
      if (category != ignore) 3: category as Category?,
      if (careMethod != ignore) 4: careMethod as CareMethod?,
      if (status != ignore) 5: status as ItemStatus?,
      if (washCycle != ignore) 6: washCycle as int?,
      if (wearSinceWash != ignore) 7: wearSinceWash as int?,
      if (totalWears != ignore) 8: totalWears as int?,
      if (lastWornAt != ignore) 9: lastWornAt as DateTime?,
      if (lastWashedAt != ignore) 10: lastWashedAt as DateTime?,
      if (purchasedAt != ignore) 11: purchasedAt as DateTime?,
      if (inLaundry != ignore) 12: inLaundry as bool?,
      if (imagePath != ignore) 13: imagePath as String?,
      if (fallbackColor != ignore) 14: fallbackColor as int?,
      if (createdAt != ignore) 15: createdAt as DateTime?,
    });
  }
}

extension ItemQueryUpdate on IsarQuery<Item> {
  _ItemQueryUpdate get updateFirst => _ItemQueryUpdateImpl(this, limit: 1);

  _ItemQueryUpdate get updateAll => _ItemQueryUpdateImpl(this);
}

class _ItemQueryBuilderUpdateImpl implements _ItemQueryUpdate {
  const _ItemQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Item, Item, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? name = ignore,
    Object? brand = ignore,
    Object? category = ignore,
    Object? careMethod = ignore,
    Object? status = ignore,
    Object? washCycle = ignore,
    Object? wearSinceWash = ignore,
    Object? totalWears = ignore,
    Object? lastWornAt = ignore,
    Object? lastWashedAt = ignore,
    Object? purchasedAt = ignore,
    Object? inLaundry = ignore,
    Object? imagePath = ignore,
    Object? fallbackColor = ignore,
    Object? createdAt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (name != ignore) 1: name as String?,
        if (brand != ignore) 2: brand as String?,
        if (category != ignore) 3: category as Category?,
        if (careMethod != ignore) 4: careMethod as CareMethod?,
        if (status != ignore) 5: status as ItemStatus?,
        if (washCycle != ignore) 6: washCycle as int?,
        if (wearSinceWash != ignore) 7: wearSinceWash as int?,
        if (totalWears != ignore) 8: totalWears as int?,
        if (lastWornAt != ignore) 9: lastWornAt as DateTime?,
        if (lastWashedAt != ignore) 10: lastWashedAt as DateTime?,
        if (purchasedAt != ignore) 11: purchasedAt as DateTime?,
        if (inLaundry != ignore) 12: inLaundry as bool?,
        if (imagePath != ignore) 13: imagePath as String?,
        if (fallbackColor != ignore) 14: fallbackColor as int?,
        if (createdAt != ignore) 15: createdAt as DateTime?,
      });
    } finally {
      q.close();
    }
  }
}

extension ItemQueryBuilderUpdate on QueryBuilder<Item, Item, QOperations> {
  _ItemQueryUpdate get updateFirst =>
      _ItemQueryBuilderUpdateImpl(this, limit: 1);

  _ItemQueryUpdate get updateAll => _ItemQueryBuilderUpdateImpl(this);
}

const _itemCategory = {
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
const _itemCareMethod = {
  0: CareMethod.dryClean,
  1: CareMethod.machine,
  2: CareMethod.handWash,
};
const _itemStatus = {0: ItemStatus.clean, 1: ItemStatus.dirty};

extension ItemQueryFilter on QueryBuilder<Item, Item, QFilterCondition> {
  QueryBuilder<Item, Item, QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 1, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 1, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 2, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryEqualTo(
    Category value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryGreaterThan(
    Category value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryGreaterThanOrEqualTo(
    Category value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryLessThan(
    Category value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 3, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryLessThanOrEqualTo(
    Category value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryBetween(
    Category lower,
    Category upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower.index, upper: upper.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodEqualTo(
    CareMethod value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodGreaterThan(
    CareMethod value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  careMethodGreaterThanOrEqualTo(CareMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodLessThan(
    CareMethod value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodLessThanOrEqualTo(
    CareMethod value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodBetween(
    CareMethod lower,
    CareMethod upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower.index, upper: upper.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusEqualTo(
    ItemStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusGreaterThan(
    ItemStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusGreaterThanOrEqualTo(
    ItemStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusLessThan(
    ItemStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusLessThanOrEqualTo(
    ItemStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusBetween(
    ItemStatus lower,
    ItemStatus upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 5, lower: lower.index, upper: upper.index),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 6, value: value));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 6, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  wearSinceWashGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 7, value: value));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  wearSinceWashLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 7, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 7, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 8, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 8, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  totalWearsGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 8, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 8, value: value));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 8, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 8, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 9));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 9));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  lastWornAtGreaterThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 9, value: value));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 9, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 9, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 10));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 10, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 10, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  lastWashedAtGreaterThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 10, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 10, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 10, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 10, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 11));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 11));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 11, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtGreaterThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 11, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  purchasedAtGreaterThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 11, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtLessThan(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 11, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtLessThanOrEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 11, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtBetween(
    DateTime? lower,
    DateTime? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 11, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> inLaundryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 12, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 13));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 13));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 13, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 13,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 13,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 13, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 13, value: ''),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 14, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 14, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  fallbackColorGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 14, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 14, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition>
  fallbackColorLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 14, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 14, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 15, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 15, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtGreaterThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 15, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 15, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtLessThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 15, value: value),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 15, lower: lower, upper: upper),
      );
    });
  }
}

extension ItemQueryObject on QueryBuilder<Item, Item, QFilterCondition> {}

extension ItemQuerySortBy on QueryBuilder<Item, Item, QSortBy> {
  QueryBuilder<Item, Item, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByNameDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByBrand({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByBrandDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCareMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCareMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWashCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWashCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWearSinceWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWearSinceWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByTotalWears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByTotalWearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWornAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByPurchasedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByPurchasedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByInLaundry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByInLaundryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByImagePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByImagePathDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByFallbackColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByFallbackColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, sort: Sort.desc);
    });
  }
}

extension ItemQuerySortThenBy on QueryBuilder<Item, Item, QSortThenBy> {
  QueryBuilder<Item, Item, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByNameDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByBrand({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByBrandDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCareMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCareMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWashCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWashCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWearSinceWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWearSinceWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByTotalWears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByTotalWearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWornAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(9, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByPurchasedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByPurchasedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByInLaundry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByInLaundryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByImagePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByImagePathDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByFallbackColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByFallbackColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, sort: Sort.desc);
    });
  }
}

extension ItemQueryWhereDistinct on QueryBuilder<Item, Item, QDistinct> {
  QueryBuilder<Item, Item, QAfterDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByBrand({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByCareMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByWashCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByWearSinceWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByTotalWears() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByLastWashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByPurchasedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(11);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByInLaundry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(12);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByImagePath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(13, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByFallbackColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(14);
    });
  }

  QueryBuilder<Item, Item, QAfterDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(15);
    });
  }
}

extension ItemQueryProperty1 on QueryBuilder<Item, Item, QProperty> {
  QueryBuilder<Item, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Item, String, QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Item, String?, QAfterProperty> brandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Item, Category, QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Item, CareMethod, QAfterProperty> careMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Item, ItemStatus, QAfterProperty> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Item, int, QAfterProperty> washCycleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Item, int, QAfterProperty> wearSinceWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<Item, int, QAfterProperty> totalWearsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<Item, DateTime?, QAfterProperty> lastWornAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<Item, DateTime?, QAfterProperty> lastWashedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<Item, DateTime?, QAfterProperty> purchasedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<Item, bool, QAfterProperty> inLaundryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<Item, String?, QAfterProperty> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<Item, int, QAfterProperty> fallbackColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<Item, DateTime, QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }
}

extension ItemQueryProperty2<R> on QueryBuilder<Item, R, QAfterProperty> {
  QueryBuilder<Item, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Item, (R, String), QAfterProperty> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Item, (R, String?), QAfterProperty> brandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Item, (R, Category), QAfterProperty> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Item, (R, CareMethod), QAfterProperty> careMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Item, (R, ItemStatus), QAfterProperty> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Item, (R, int), QAfterProperty> washCycleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Item, (R, int), QAfterProperty> wearSinceWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<Item, (R, int), QAfterProperty> totalWearsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<Item, (R, DateTime?), QAfterProperty> lastWornAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<Item, (R, DateTime?), QAfterProperty> lastWashedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<Item, (R, DateTime?), QAfterProperty> purchasedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<Item, (R, bool), QAfterProperty> inLaundryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<Item, (R, String?), QAfterProperty> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<Item, (R, int), QAfterProperty> fallbackColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<Item, (R, DateTime), QAfterProperty> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }
}

extension ItemQueryProperty3<R1, R2>
    on QueryBuilder<Item, (R1, R2), QAfterProperty> {
  QueryBuilder<Item, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Item, (R1, R2, String), QOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Item, (R1, R2, String?), QOperations> brandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Item, (R1, R2, Category), QOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Item, (R1, R2, CareMethod), QOperations> careMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Item, (R1, R2, ItemStatus), QOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<Item, (R1, R2, int), QOperations> washCycleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<Item, (R1, R2, int), QOperations> wearSinceWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<Item, (R1, R2, int), QOperations> totalWearsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<Item, (R1, R2, DateTime?), QOperations> lastWornAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<Item, (R1, R2, DateTime?), QOperations> lastWashedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<Item, (R1, R2, DateTime?), QOperations> purchasedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<Item, (R1, R2, bool), QOperations> inLaundryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<Item, (R1, R2, String?), QOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<Item, (R1, R2, int), QOperations> fallbackColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<Item, (R1, R2, DateTime), QOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }
}
