// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetUserPreferencesCollection on Isar {
  IsarCollection<int, UserPreferences> get userPreferences => this.collection();
}

final UserPreferencesSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'UserPreferences',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'notifWash', type: IsarType.bool),
      IsarPropertySchema(name: 'notifWeekly', type: IsarType.bool),
      IsarPropertySchema(name: 'notifUnworn', type: IsarType.bool),
      IsarPropertySchema(name: 'accent', type: IsarType.string),
      IsarPropertySchema(name: 'lastTab', type: IsarType.string),
      IsarPropertySchema(name: 'firstLaunchedAt', type: IsarType.dateTime),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, UserPreferences>(
    serialize: serializeUserPreferences,
    deserialize: deserializeUserPreferences,
    deserializeProperty: deserializeUserPreferencesProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeUserPreferences(IsarWriter writer, UserPreferences object) {
  IsarCore.writeBool(writer, 1, value: object.notifWash);
  IsarCore.writeBool(writer, 2, value: object.notifWeekly);
  IsarCore.writeBool(writer, 3, value: object.notifUnworn);
  IsarCore.writeString(writer, 4, object.accent);
  {
    final value = object.lastTab;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  IsarCore.writeLong(
    writer,
    6,
    object.firstLaunchedAt?.toUtc().microsecondsSinceEpoch ??
        -9223372036854775808,
  );
  return object.id;
}

@isarProtected
UserPreferences deserializeUserPreferences(IsarReader reader) {
  final bool _notifWash;
  {
    if (IsarCore.readNull(reader, 1)) {
      _notifWash = true;
    } else {
      _notifWash = IsarCore.readBool(reader, 1);
    }
  }
  final bool _notifWeekly;
  {
    if (IsarCore.readNull(reader, 2)) {
      _notifWeekly = true;
    } else {
      _notifWeekly = IsarCore.readBool(reader, 2);
    }
  }
  final bool _notifUnworn;
  _notifUnworn = IsarCore.readBool(reader, 3);
  final String _accent;
  _accent = IsarCore.readString(reader, 4) ?? 'sage';
  final String? _lastTab;
  _lastTab = IsarCore.readString(reader, 5);
  final DateTime? _firstLaunchedAt;
  {
    final value = IsarCore.readLong(reader, 6);
    if (value == -9223372036854775808) {
      _firstLaunchedAt = null;
    } else {
      _firstLaunchedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final object = UserPreferences(
    notifWash: _notifWash,
    notifWeekly: _notifWeekly,
    notifUnworn: _notifUnworn,
    accent: _accent,
    lastTab: _lastTab,
    firstLaunchedAt: _firstLaunchedAt,
  );
  object.id = IsarCore.readId(reader);
  return object;
}

@isarProtected
dynamic deserializeUserPreferencesProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      {
        if (IsarCore.readNull(reader, 1)) {
          return true;
        } else {
          return IsarCore.readBool(reader, 1);
        }
      }
    case 2:
      {
        if (IsarCore.readNull(reader, 2)) {
          return true;
        } else {
          return IsarCore.readBool(reader, 2);
        }
      }
    case 3:
      return IsarCore.readBool(reader, 3);
    case 4:
      return IsarCore.readString(reader, 4) ?? 'sage';
    case 5:
      return IsarCore.readString(reader, 5);
    case 6:
      {
        final value = IsarCore.readLong(reader, 6);
        if (value == -9223372036854775808) {
          return null;
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

sealed class _UserPreferencesUpdate {
  bool call({
    required int id,
    bool? notifWash,
    bool? notifWeekly,
    bool? notifUnworn,
    String? accent,
    String? lastTab,
    DateTime? firstLaunchedAt,
  });
}

class _UserPreferencesUpdateImpl implements _UserPreferencesUpdate {
  const _UserPreferencesUpdateImpl(this.collection);

  final IsarCollection<int, UserPreferences> collection;

  @override
  bool call({
    required int id,
    Object? notifWash = ignore,
    Object? notifWeekly = ignore,
    Object? notifUnworn = ignore,
    Object? accent = ignore,
    Object? lastTab = ignore,
    Object? firstLaunchedAt = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (notifWash != ignore) 1: notifWash as bool?,
            if (notifWeekly != ignore) 2: notifWeekly as bool?,
            if (notifUnworn != ignore) 3: notifUnworn as bool?,
            if (accent != ignore) 4: accent as String?,
            if (lastTab != ignore) 5: lastTab as String?,
            if (firstLaunchedAt != ignore) 6: firstLaunchedAt as DateTime?,
          },
        ) >
        0;
  }
}

sealed class _UserPreferencesUpdateAll {
  int call({
    required List<int> id,
    bool? notifWash,
    bool? notifWeekly,
    bool? notifUnworn,
    String? accent,
    String? lastTab,
    DateTime? firstLaunchedAt,
  });
}

class _UserPreferencesUpdateAllImpl implements _UserPreferencesUpdateAll {
  const _UserPreferencesUpdateAllImpl(this.collection);

  final IsarCollection<int, UserPreferences> collection;

  @override
  int call({
    required List<int> id,
    Object? notifWash = ignore,
    Object? notifWeekly = ignore,
    Object? notifUnworn = ignore,
    Object? accent = ignore,
    Object? lastTab = ignore,
    Object? firstLaunchedAt = ignore,
  }) {
    return collection.updateProperties(id, {
      if (notifWash != ignore) 1: notifWash as bool?,
      if (notifWeekly != ignore) 2: notifWeekly as bool?,
      if (notifUnworn != ignore) 3: notifUnworn as bool?,
      if (accent != ignore) 4: accent as String?,
      if (lastTab != ignore) 5: lastTab as String?,
      if (firstLaunchedAt != ignore) 6: firstLaunchedAt as DateTime?,
    });
  }
}

extension UserPreferencesUpdate on IsarCollection<int, UserPreferences> {
  _UserPreferencesUpdate get update => _UserPreferencesUpdateImpl(this);

  _UserPreferencesUpdateAll get updateAll =>
      _UserPreferencesUpdateAllImpl(this);
}

sealed class _UserPreferencesQueryUpdate {
  int call({
    bool? notifWash,
    bool? notifWeekly,
    bool? notifUnworn,
    String? accent,
    String? lastTab,
    DateTime? firstLaunchedAt,
  });
}

class _UserPreferencesQueryUpdateImpl implements _UserPreferencesQueryUpdate {
  const _UserPreferencesQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<UserPreferences> query;
  final int? limit;

  @override
  int call({
    Object? notifWash = ignore,
    Object? notifWeekly = ignore,
    Object? notifUnworn = ignore,
    Object? accent = ignore,
    Object? lastTab = ignore,
    Object? firstLaunchedAt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (notifWash != ignore) 1: notifWash as bool?,
      if (notifWeekly != ignore) 2: notifWeekly as bool?,
      if (notifUnworn != ignore) 3: notifUnworn as bool?,
      if (accent != ignore) 4: accent as String?,
      if (lastTab != ignore) 5: lastTab as String?,
      if (firstLaunchedAt != ignore) 6: firstLaunchedAt as DateTime?,
    });
  }
}

extension UserPreferencesQueryUpdate on IsarQuery<UserPreferences> {
  _UserPreferencesQueryUpdate get updateFirst =>
      _UserPreferencesQueryUpdateImpl(this, limit: 1);

  _UserPreferencesQueryUpdate get updateAll =>
      _UserPreferencesQueryUpdateImpl(this);
}

class _UserPreferencesQueryBuilderUpdateImpl
    implements _UserPreferencesQueryUpdate {
  const _UserPreferencesQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<UserPreferences, UserPreferences, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? notifWash = ignore,
    Object? notifWeekly = ignore,
    Object? notifUnworn = ignore,
    Object? accent = ignore,
    Object? lastTab = ignore,
    Object? firstLaunchedAt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (notifWash != ignore) 1: notifWash as bool?,
        if (notifWeekly != ignore) 2: notifWeekly as bool?,
        if (notifUnworn != ignore) 3: notifUnworn as bool?,
        if (accent != ignore) 4: accent as String?,
        if (lastTab != ignore) 5: lastTab as String?,
        if (firstLaunchedAt != ignore) 6: firstLaunchedAt as DateTime?,
      });
    } finally {
      q.close();
    }
  }
}

extension UserPreferencesQueryBuilderUpdate
    on QueryBuilder<UserPreferences, UserPreferences, QOperations> {
  _UserPreferencesQueryUpdate get updateFirst =>
      _UserPreferencesQueryBuilderUpdateImpl(this, limit: 1);

  _UserPreferencesQueryUpdate get updateAll =>
      _UserPreferencesQueryBuilderUpdateImpl(this);
}

extension UserPreferencesQueryFilter
    on QueryBuilder<UserPreferences, UserPreferences, QFilterCondition> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  idBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  notifWashEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  notifWeeklyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  notifUnwornEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentGreaterThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentGreaterThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentLessThan(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentLessThanOrEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentBetween(String lower, String upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  accentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabGreaterThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabLessThan(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabBetween(String? lower, String? upper, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  lastTabIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 5, value: ''),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 6));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtGreaterThan(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtGreaterThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtLessThan(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 6, value: value));
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtLessThanOrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 6, value: value),
      );
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterFilterCondition>
  firstLaunchedAtBetween(DateTime? lower, DateTime? upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 6, lower: lower, upper: upper),
      );
    });
  }
}

extension UserPreferencesQueryObject
    on QueryBuilder<UserPreferences, UserPreferences, QFilterCondition> {}

extension UserPreferencesQuerySortBy
    on QueryBuilder<UserPreferences, UserPreferences, QSortBy> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByNotifWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByNotifWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByNotifWeekly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByNotifWeeklyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByNotifUnworn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByNotifUnwornDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> sortByAccent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByAccentDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> sortByLastTab({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByLastTabDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByFirstLaunchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  sortByFirstLaunchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }
}

extension UserPreferencesQuerySortThenBy
    on QueryBuilder<UserPreferences, UserPreferences, QSortThenBy> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByNotifWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByNotifWashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByNotifWeekly() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByNotifWeeklyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByNotifUnworn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByNotifUnwornDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenByAccent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByAccentDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy> thenByLastTab({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByLastTabDesc({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByFirstLaunchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterSortBy>
  thenByFirstLaunchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }
}

extension UserPreferencesQueryWhereDistinct
    on QueryBuilder<UserPreferences, UserPreferences, QDistinct> {
  QueryBuilder<UserPreferences, UserPreferences, QAfterDistinct>
  distinctByNotifWash() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterDistinct>
  distinctByNotifWeekly() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterDistinct>
  distinctByNotifUnworn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterDistinct>
  distinctByAccent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterDistinct>
  distinctByLastTab({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserPreferences, UserPreferences, QAfterDistinct>
  distinctByFirstLaunchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }
}

extension UserPreferencesQueryProperty1
    on QueryBuilder<UserPreferences, UserPreferences, QProperty> {
  QueryBuilder<UserPreferences, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<UserPreferences, bool, QAfterProperty> notifWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserPreferences, bool, QAfterProperty> notifWeeklyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserPreferences, bool, QAfterProperty> notifUnwornProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserPreferences, String, QAfterProperty> accentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<UserPreferences, String?, QAfterProperty> lastTabProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<UserPreferences, DateTime?, QAfterProperty>
  firstLaunchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}

extension UserPreferencesQueryProperty2<R>
    on QueryBuilder<UserPreferences, R, QAfterProperty> {
  QueryBuilder<UserPreferences, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<UserPreferences, (R, bool), QAfterProperty> notifWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserPreferences, (R, bool), QAfterProperty>
  notifWeeklyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserPreferences, (R, bool), QAfterProperty>
  notifUnwornProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserPreferences, (R, String), QAfterProperty> accentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<UserPreferences, (R, String?), QAfterProperty>
  lastTabProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<UserPreferences, (R, DateTime?), QAfterProperty>
  firstLaunchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}

extension UserPreferencesQueryProperty3<R1, R2>
    on QueryBuilder<UserPreferences, (R1, R2), QAfterProperty> {
  QueryBuilder<UserPreferences, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<UserPreferences, (R1, R2, bool), QOperations>
  notifWashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserPreferences, (R1, R2, bool), QOperations>
  notifWeeklyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserPreferences, (R1, R2, bool), QOperations>
  notifUnwornProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserPreferences, (R1, R2, String), QOperations>
  accentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<UserPreferences, (R1, R2, String?), QOperations>
  lastTabProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<UserPreferences, (R1, R2, DateTime?), QOperations>
  firstLaunchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }
}
