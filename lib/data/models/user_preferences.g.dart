// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserPreferencesCollection on Isar {
  IsarCollection<UserPreferences> get userPreferences => this.collection();
}

const UserPreferencesSchema = CollectionSchema(
  name: r'UserPreferences',
  id: -7545901164102504045,
  properties: {
    r'accent': PropertySchema(
      id: 0,
      name: r'accent',
      type: IsarType.string,
    ),
    r'firstLaunchedAt': PropertySchema(
      id: 1,
      name: r'firstLaunchedAt',
      type: IsarType.dateTime,
    ),
    r'lastTab': PropertySchema(
      id: 2,
      name: r'lastTab',
      type: IsarType.string,
    ),
    r'notifUnworn': PropertySchema(
      id: 3,
      name: r'notifUnworn',
      type: IsarType.bool,
    ),
    r'notifWash': PropertySchema(
      id: 4,
      name: r'notifWash',
      type: IsarType.bool,
    ),
    r'notifWeekly': PropertySchema(
      id: 5,
      name: r'notifWeekly',
      type: IsarType.bool,
    )
  },
  estimateSize: _userPreferencesEstimateSize,
  serialize: _userPreferencesSerialize,
  deserialize: _userPreferencesDeserialize,
  deserializeProp: _userPreferencesDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userPreferencesGetId,
  getLinks: _userPreferencesGetLinks,
  attach: _userPreferencesAttach,
  version: '3.1.0+1',
);

int _userPreferencesEstimateSize(
  UserPreferences object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accent.length * 3;
  {
    final value = object.lastTab;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _userPreferencesSerialize(
  UserPreferences object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accent);
  writer.writeDateTime(offsets[1], object.firstLaunchedAt);
  writer.writeString(offsets[2], object.lastTab);
  writer.writeBool(offsets[3], object.notifUnworn);
  writer.writeBool(offsets[4], object.notifWash);
  writer.writeBool(offsets[5], object.notifWeekly);
}

UserPreferences _userPreferencesDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserPreferences(
    accent: reader.readStringOrNull(offsets[0]) ?? 'sage',
    firstLaunchedAt: reader.readDateTimeOrNull(offsets[1]),
    lastTab: reader.readStringOrNull(offsets[2]),
    notifUnworn: reader.readBoolOrNull(offsets[3]) ?? false,
    notifWash: reader.readBoolOrNull(offsets[4]) ?? true,
    notifWeekly: reader.readBoolOrNull(offsets[5]) ?? true,
  );
  object.id = id;
  return object;
}

P _userPreferencesDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? 'sage') as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userPreferencesGetId(UserPreferences object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userPreferencesGetLinks(UserPreferences object) {
  return [];
}

void _userPreferencesAttach(
    IsarCollection<dynamic> col, Id id, UserPreferences object) {
  object.id = id;
}

extension UserPreferencesQueryWhereSort
    on QueryBuilder<UserPreferences, UserPreferences, QWhere> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserPreferencesQueryWhere
    on QueryBuilder<UserPreferences, UserPreferences, QWhereClause> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<UserPreferences, UserPreferences, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterWhereClause> idBetween(
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
}

extension UserPreferencesQueryFilter
    on QueryBuilder<UserPreferences, UserPreferences, QFilterCondition> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accent',
        value: '',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      accentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accent',
        value: '',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      firstLaunchedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firstLaunchedAt',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      firstLaunchedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firstLaunchedAt',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      firstLaunchedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstLaunchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      firstLaunchedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstLaunchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      firstLaunchedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstLaunchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      firstLaunchedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstLaunchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastTab',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastTab',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTab',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastTab',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastTab',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTab',
        value: '',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      lastTabIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastTab',
        value: '',
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      notifUnwornEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notifUnworn',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      notifWashEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notifWash',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
      notifWeeklyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notifWeekly',
        value: value,
      ));
    });
  }
}

extension UserPreferencesQueryObject
    on QueryBuilder<UserPreferences, UserPreferences, QFilterCondition> {}

extension UserPreferencesQueryLinks
    on QueryBuilder<UserPreferences, UserPreferences, QFilterCondition> {}

extension UserPreferencesQuerySortBy
    on QueryBuilder<UserPreferences, UserPreferences, QSortBy> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> sortByAccent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accent', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByAccentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accent', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByFirstLaunchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLaunchedAt', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByFirstLaunchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLaunchedAt', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> sortByLastTab() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTab', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByLastTabDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTab', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByNotifUnworn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifUnworn', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByNotifUnwornDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifUnworn', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByNotifWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWash', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByNotifWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWash', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByNotifWeekly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWeekly', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      sortByNotifWeeklyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWeekly', Sort.desc);
    });
  }
}

extension UserPreferencesQuerySortThenBy
    on QueryBuilder<UserPreferences, UserPreferences, QSortThenBy> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenByAccent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accent', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByAccentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accent', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByFirstLaunchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLaunchedAt', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByFirstLaunchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstLaunchedAt', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenByLastTab() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTab', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByLastTabDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTab', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByNotifUnworn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifUnworn', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByNotifUnwornDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifUnworn', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByNotifWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWash', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByNotifWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWash', Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByNotifWeekly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWeekly', Sort.asc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
      thenByNotifWeeklyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notifWeekly', Sort.desc);
    });
  }
}

extension UserPreferencesQueryWhereDistinct
    on QueryBuilder<UserPreferences, UserPreferences, QDistinct> {
  QueryBuilder<UserPreferences, UserPreferences, QDistinct> distinctByAccent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accent', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QDistinct>
      distinctByFirstLaunchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstLaunchedAt');
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QDistinct> distinctByLastTab(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTab', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QDistinct>
      distinctByNotifUnworn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifUnworn');
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QDistinct>
      distinctByNotifWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifWash');
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QDistinct>
      distinctByNotifWeekly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notifWeekly');
    });
  }
}

extension UserPreferencesQueryProperty
    on QueryBuilder<UserPreferences, UserPreferences, QQueryProperty> {
  QueryBuilder<UserPreferences, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserPreferences, String, QQueryOperations> accentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accent');
    });
  }

  QueryBuilder<UserPreferences, DateTime?, QQueryOperations>
      firstLaunchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstLaunchedAt');
    });
  }

  QueryBuilder<UserPreferences, String?, QQueryOperations> lastTabProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTab');
    });
  }

  QueryBuilder<UserPreferences, bool, QQueryOperations> notifUnwornProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifUnworn');
    });
  }

  QueryBuilder<UserPreferences, bool, QQueryOperations> notifWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifWash');
    });
  }

  QueryBuilder<UserPreferences, bool, QQueryOperations> notifWeeklyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notifWeekly');
    });
  }
}
