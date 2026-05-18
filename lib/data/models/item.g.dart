// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetItemCollection on Isar {
  IsarCollection<Item> get items => this.collection();
}

const ItemSchema = CollectionSchema(
  name: r'Item',
  id: 7900997316587104717,
  properties: {
    r'brand': PropertySchema(
      id: 0,
      name: r'brand',
      type: IsarType.string,
    ),
    r'careMethod': PropertySchema(
      id: 1,
      name: r'careMethod',
      type: IsarType.byte,
      enumMap: _ItemcareMethodEnumValueMap,
    ),
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.byte,
      enumMap: _ItemcategoryEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'fallbackColor': PropertySchema(
      id: 4,
      name: r'fallbackColor',
      type: IsarType.long,
    ),
    r'imagePath': PropertySchema(
      id: 5,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'inLaundry': PropertySchema(
      id: 6,
      name: r'inLaundry',
      type: IsarType.bool,
    ),
    r'lastWashedAt': PropertySchema(
      id: 7,
      name: r'lastWashedAt',
      type: IsarType.dateTime,
    ),
    r'lastWornAt': PropertySchema(
      id: 8,
      name: r'lastWornAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'purchasedAt': PropertySchema(
      id: 10,
      name: r'purchasedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 11,
      name: r'status',
      type: IsarType.byte,
      enumMap: _ItemstatusEnumValueMap,
    ),
    r'totalWears': PropertySchema(
      id: 12,
      name: r'totalWears',
      type: IsarType.long,
    ),
    r'washCycle': PropertySchema(
      id: 13,
      name: r'washCycle',
      type: IsarType.long,
    ),
    r'wearSinceWash': PropertySchema(
      id: 14,
      name: r'wearSinceWash',
      type: IsarType.long,
    )
  },
  estimateSize: _itemEstimateSize,
  serialize: _itemSerialize,
  deserialize: _itemDeserialize,
  deserializeProp: _itemDeserializeProp,
  idName: r'id',
  indexes: {
    r'lastWornAt': IndexSchema(
      id: 2553873299518206073,
      name: r'lastWornAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastWornAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _itemGetId,
  getLinks: _itemGetLinks,
  attach: _itemAttach,
  version: '3.1.0+1',
);

int _itemEstimateSize(
  Item object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.brand;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _itemSerialize(
  Item object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.brand);
  writer.writeByte(offsets[1], object.careMethod.index);
  writer.writeByte(offsets[2], object.category.index);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeLong(offsets[4], object.fallbackColor);
  writer.writeString(offsets[5], object.imagePath);
  writer.writeBool(offsets[6], object.inLaundry);
  writer.writeDateTime(offsets[7], object.lastWashedAt);
  writer.writeDateTime(offsets[8], object.lastWornAt);
  writer.writeString(offsets[9], object.name);
  writer.writeDateTime(offsets[10], object.purchasedAt);
  writer.writeByte(offsets[11], object.status.index);
  writer.writeLong(offsets[12], object.totalWears);
  writer.writeLong(offsets[13], object.washCycle);
  writer.writeLong(offsets[14], object.wearSinceWash);
}

Item _itemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Item(
    brand: reader.readStringOrNull(offsets[0]),
    careMethod:
        _ItemcareMethodValueEnumMap[reader.readByteOrNull(offsets[1])] ??
            CareMethod.machine,
    category: _ItemcategoryValueEnumMap[reader.readByteOrNull(offsets[2])] ??
        Category.outer,
    createdAt: reader.readDateTime(offsets[3]),
    fallbackColor: reader.readLongOrNull(offsets[4]) ?? 0xFFE5E4DC,
    imagePath: reader.readStringOrNull(offsets[5]),
    inLaundry: reader.readBoolOrNull(offsets[6]) ?? false,
    lastWashedAt: reader.readDateTimeOrNull(offsets[7]),
    lastWornAt: reader.readDateTimeOrNull(offsets[8]),
    name: reader.readString(offsets[9]),
    purchasedAt: reader.readDateTimeOrNull(offsets[10]),
    status: _ItemstatusValueEnumMap[reader.readByteOrNull(offsets[11])] ??
        ItemStatus.clean,
    totalWears: reader.readLongOrNull(offsets[12]) ?? 0,
    washCycle: reader.readLong(offsets[13]),
    wearSinceWash: reader.readLongOrNull(offsets[14]) ?? 0,
  );
  object.id = id;
  return object;
}

P _itemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (_ItemcareMethodValueEnumMap[reader.readByteOrNull(offset)] ??
          CareMethod.machine) as P;
    case 2:
      return (_ItemcategoryValueEnumMap[reader.readByteOrNull(offset)] ??
          Category.outer) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset) ?? 0xFFE5E4DC) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 11:
      return (_ItemstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          ItemStatus.clean) as P;
    case 12:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ItemcareMethodEnumValueMap = {
  'dryClean': 0,
  'machine': 1,
  'handWash': 2,
};
const _ItemcareMethodValueEnumMap = {
  0: CareMethod.dryClean,
  1: CareMethod.machine,
  2: CareMethod.handWash,
};
const _ItemcategoryEnumValueMap = {
  'outer': 0,
  'top': 1,
  'bottom': 2,
  'onepiece': 3,
  'shoes': 4,
  'bag': 5,
  'accessory': 6,
  'activewear': 7,
  'etc': 8,
};
const _ItemcategoryValueEnumMap = {
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
const _ItemstatusEnumValueMap = {
  'clean': 0,
  'dirty': 1,
};
const _ItemstatusValueEnumMap = {
  0: ItemStatus.clean,
  1: ItemStatus.dirty,
};

Id _itemGetId(Item object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _itemGetLinks(Item object) {
  return [];
}

void _itemAttach(IsarCollection<dynamic> col, Id id, Item object) {
  object.id = id;
}

extension ItemQueryWhereSort on QueryBuilder<Item, Item, QWhere> {
  QueryBuilder<Item, Item, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Item, Item, QAfterWhere> anyLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastWornAt'),
      );
    });
  }
}

extension ItemQueryWhere on QueryBuilder<Item, Item, QWhereClause> {
  QueryBuilder<Item, Item, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastWornAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastWornAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtEqualTo(
      DateTime? lastWornAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastWornAt',
        value: [lastWornAt],
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtNotEqualTo(
      DateTime? lastWornAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastWornAt',
              lower: [],
              upper: [lastWornAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastWornAt',
              lower: [lastWornAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastWornAt',
              lower: [lastWornAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastWornAt',
              lower: [],
              upper: [lastWornAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtGreaterThan(
    DateTime? lastWornAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastWornAt',
        lower: [lastWornAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtLessThan(
    DateTime? lastWornAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastWornAt',
        lower: [],
        upper: [lastWornAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterWhereClause> lastWornAtBetween(
    DateTime? lowerLastWornAt,
    DateTime? upperLastWornAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastWornAt',
        lower: [lowerLastWornAt],
        includeLower: includeLower,
        upper: [upperLastWornAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ItemQueryFilter on QueryBuilder<Item, Item, QFilterCondition> {
  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'brand',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'brand',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brand',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brand',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> brandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodEqualTo(
      CareMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'careMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodGreaterThan(
    CareMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'careMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodLessThan(
    CareMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'careMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> careMethodBetween(
    CareMethod lower,
    CareMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'careMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryEqualTo(
      Category value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryGreaterThan(
    Category value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryLessThan(
    Category value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> categoryBetween(
    Category lower,
    Category upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fallbackColor',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fallbackColor',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fallbackColor',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> fallbackColorBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fallbackColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> inLaundryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inLaundry',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastWashedAt',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastWashedAt',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastWashedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastWashedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastWashedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWashedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastWashedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastWornAt',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastWornAt',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastWornAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastWornAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastWornAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> lastWornAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastWornAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'purchasedAt',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'purchasedAt',
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchasedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchasedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchasedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> purchasedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchasedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusEqualTo(
      ItemStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusGreaterThan(
    ItemStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusLessThan(
    ItemStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> statusBetween(
    ItemStatus lower,
    ItemStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalWears',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalWears',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalWears',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> totalWearsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalWears',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'washCycle',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'washCycle',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'washCycle',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> washCycleBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'washCycle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wearSinceWash',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wearSinceWash',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wearSinceWash',
        value: value,
      ));
    });
  }

  QueryBuilder<Item, Item, QAfterFilterCondition> wearSinceWashBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wearSinceWash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ItemQueryObject on QueryBuilder<Item, Item, QFilterCondition> {}

extension ItemQueryLinks on QueryBuilder<Item, Item, QFilterCondition> {}

extension ItemQuerySortBy on QueryBuilder<Item, Item, QSortBy> {
  QueryBuilder<Item, Item, QAfterSortBy> sortByBrand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByBrandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCareMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'careMethod', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCareMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'careMethod', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByFallbackColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fallbackColor', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByFallbackColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fallbackColor', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByInLaundry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLaundry', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByInLaundryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLaundry', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWashedAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWashedAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWornAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByLastWornAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWornAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByPurchasedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasedAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByPurchasedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasedAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByTotalWears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWears', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByTotalWearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWears', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWashCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'washCycle', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWashCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'washCycle', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWearSinceWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wearSinceWash', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> sortByWearSinceWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wearSinceWash', Sort.desc);
    });
  }
}

extension ItemQuerySortThenBy on QueryBuilder<Item, Item, QSortThenBy> {
  QueryBuilder<Item, Item, QAfterSortBy> thenByBrand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByBrandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCareMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'careMethod', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCareMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'careMethod', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByFallbackColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fallbackColor', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByFallbackColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fallbackColor', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByInLaundry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLaundry', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByInLaundryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inLaundry', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWashedAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWashedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWashedAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWornAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByLastWornAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWornAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByPurchasedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasedAt', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByPurchasedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasedAt', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByTotalWears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWears', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByTotalWearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalWears', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWashCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'washCycle', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWashCycleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'washCycle', Sort.desc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWearSinceWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wearSinceWash', Sort.asc);
    });
  }

  QueryBuilder<Item, Item, QAfterSortBy> thenByWearSinceWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wearSinceWash', Sort.desc);
    });
  }
}

extension ItemQueryWhereDistinct on QueryBuilder<Item, Item, QDistinct> {
  QueryBuilder<Item, Item, QDistinct> distinctByBrand(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brand', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByCareMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'careMethod');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByFallbackColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fallbackColor');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByInLaundry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inLaundry');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByLastWashedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastWashedAt');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByLastWornAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastWornAt');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByPurchasedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchasedAt');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByTotalWears() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalWears');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByWashCycle() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'washCycle');
    });
  }

  QueryBuilder<Item, Item, QDistinct> distinctByWearSinceWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wearSinceWash');
    });
  }
}

extension ItemQueryProperty on QueryBuilder<Item, Item, QQueryProperty> {
  QueryBuilder<Item, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Item, String?, QQueryOperations> brandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brand');
    });
  }

  QueryBuilder<Item, CareMethod, QQueryOperations> careMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'careMethod');
    });
  }

  QueryBuilder<Item, Category, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<Item, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Item, int, QQueryOperations> fallbackColorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fallbackColor');
    });
  }

  QueryBuilder<Item, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<Item, bool, QQueryOperations> inLaundryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inLaundry');
    });
  }

  QueryBuilder<Item, DateTime?, QQueryOperations> lastWashedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastWashedAt');
    });
  }

  QueryBuilder<Item, DateTime?, QQueryOperations> lastWornAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastWornAt');
    });
  }

  QueryBuilder<Item, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Item, DateTime?, QQueryOperations> purchasedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchasedAt');
    });
  }

  QueryBuilder<Item, ItemStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Item, int, QQueryOperations> totalWearsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalWears');
    });
  }

  QueryBuilder<Item, int, QQueryOperations> washCycleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'washCycle');
    });
  }

  QueryBuilder<Item, int, QQueryOperations> wearSinceWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wearSinceWash');
    });
  }
}
