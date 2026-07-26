// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_metadata.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetStorageMetadataCollection on Isar {
  IsarCollection<int, StorageMetadata> get storageMetadatas =>
      this.collection();
}

final StorageMetadataSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'StorageMetadata',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'storageVersion', type: IsarType.long),
      IsarPropertySchema(name: 'migratedAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'legacyItemCount', type: IsarType.long),
      IsarPropertySchema(name: 'legacyEventCount', type: IsarType.long),
      IsarPropertySchema(
        name: 'source',
        type: IsarType.byte,

        enumMap: {"legacyV3": 0, "fresh": 1},
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, StorageMetadata>(
    serialize: serializeStorageMetadata,
    deserialize: deserializeStorageMetadata,
    deserializeProperty: deserializeStorageMetadataProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeStorageMetadata(IsarWriter writer, StorageMetadata object) {
  IsarCore.writeLong(writer, 1, object.storageVersion);
  IsarCore.writeLong(
    writer,
    2,
    object.migratedAt.toUtc().microsecondsSinceEpoch,
  );
  IsarCore.writeLong(writer, 3, object.legacyItemCount);
  IsarCore.writeLong(writer, 4, object.legacyEventCount);
  IsarCore.writeByte(writer, 5, object.source.index);
  return object.id;
}

@isarProtected
StorageMetadata deserializeStorageMetadata(IsarReader reader) {
  final int _storageVersion;
  _storageVersion = IsarCore.readLong(reader, 1);
  final DateTime _migratedAt;
  {
    final value = IsarCore.readLong(reader, 2);
    if (value == -9223372036854775808) {
      _migratedAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      _migratedAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final int _legacyItemCount;
  _legacyItemCount = IsarCore.readLong(reader, 3);
  final int _legacyEventCount;
  _legacyEventCount = IsarCore.readLong(reader, 4);
  final StorageSource _source;
  {
    if (IsarCore.readNull(reader, 5)) {
      _source = StorageSource.legacyV3;
    } else {
      _source =
          _storageMetadataSource[IsarCore.readByte(reader, 5)] ??
          StorageSource.legacyV3;
    }
  }
  final object = StorageMetadata(
    storageVersion: _storageVersion,
    migratedAt: _migratedAt,
    legacyItemCount: _legacyItemCount,
    legacyEventCount: _legacyEventCount,
    source: _source,
  );
  object.id = IsarCore.readId(reader);
  return object;
}

@isarProtected
dynamic deserializeStorageMetadataProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    case 2:
      {
        final value = IsarCore.readLong(reader, 2);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readLong(reader, 4);
    case 5:
      {
        if (IsarCore.readNull(reader, 5)) {
          return StorageSource.legacyV3;
        } else {
          return _storageMetadataSource[IsarCore.readByte(reader, 5)] ??
              StorageSource.legacyV3;
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _StorageMetadataUpdate {
  bool call({
    required int id,
    int? storageVersion,
    DateTime? migratedAt,
    int? legacyItemCount,
    int? legacyEventCount,
    StorageSource? source,
  });
}

class _StorageMetadataUpdateImpl implements _StorageMetadataUpdate {
  const _StorageMetadataUpdateImpl(this.collection);

  final IsarCollection<int, StorageMetadata> collection;

  @override
  bool call({
    required int id,
    Object? storageVersion = ignore,
    Object? migratedAt = ignore,
    Object? legacyItemCount = ignore,
    Object? legacyEventCount = ignore,
    Object? source = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (storageVersion != ignore) 1: storageVersion as int?,
            if (migratedAt != ignore) 2: migratedAt as DateTime?,
            if (legacyItemCount != ignore) 3: legacyItemCount as int?,
            if (legacyEventCount != ignore) 4: legacyEventCount as int?,
            if (source != ignore) 5: source as StorageSource?,
          },
        ) >
        0;
  }
}

sealed class _StorageMetadataUpdateAll {
  int call({
    required List<int> id,
    int? storageVersion,
    DateTime? migratedAt,
    int? legacyItemCount,
    int? legacyEventCount,
    StorageSource? source,
  });
}

class _StorageMetadataUpdateAllImpl implements _StorageMetadataUpdateAll {
  const _StorageMetadataUpdateAllImpl(this.collection);

  final IsarCollection<int, StorageMetadata> collection;

  @override
  int call({
    required List<int> id,
    Object? storageVersion = ignore,
    Object? migratedAt = ignore,
    Object? legacyItemCount = ignore,
    Object? legacyEventCount = ignore,
    Object? source = ignore,
  }) {
    return collection.updateProperties(id, {
      if (storageVersion != ignore) 1: storageVersion as int?,
      if (migratedAt != ignore) 2: migratedAt as DateTime?,
      if (legacyItemCount != ignore) 3: legacyItemCount as int?,
      if (legacyEventCount != ignore) 4: legacyEventCount as int?,
      if (source != ignore) 5: source as StorageSource?,
    });
  }
}

extension StorageMetadataUpdate on IsarCollection<int, StorageMetadata> {
  _StorageMetadataUpdate get update => _StorageMetadataUpdateImpl(this);

  _StorageMetadataUpdateAll get updateAll =>
      _StorageMetadataUpdateAllImpl(this);
}

sealed class _StorageMetadataQueryUpdate {
  int call({
    int? storageVersion,
    DateTime? migratedAt,
    int? legacyItemCount,
    int? legacyEventCount,
    StorageSource? source,
  });
}

class _StorageMetadataQueryUpdateImpl implements _StorageMetadataQueryUpdate {
  const _StorageMetadataQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<StorageMetadata> query;
  final int? limit;

  @override
  int call({
    Object? storageVersion = ignore,
    Object? migratedAt = ignore,
    Object? legacyItemCount = ignore,
    Object? legacyEventCount = ignore,
    Object? source = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (storageVersion != ignore) 1: storageVersion as int?,
      if (migratedAt != ignore) 2: migratedAt as DateTime?,
      if (legacyItemCount != ignore) 3: legacyItemCount as int?,
      if (legacyEventCount != ignore) 4: legacyEventCount as int?,
      if (source != ignore) 5: source as StorageSource?,
    });
  }
}

extension StorageMetadataQueryUpdate on IsarQuery<StorageMetadata> {
  _StorageMetadataQueryUpdate get updateFirst =>
      _StorageMetadataQueryUpdateImpl(this, limit: 1);

  _StorageMetadataQueryUpdate get updateAll =>
      _StorageMetadataQueryUpdateImpl(this);
}

class _StorageMetadataQueryBuilderUpdateImpl
    implements _StorageMetadataQueryUpdate {
  const _StorageMetadataQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<StorageMetadata, StorageMetadata, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? storageVersion = ignore,
    Object? migratedAt = ignore,
    Object? legacyItemCount = ignore,
    Object? legacyEventCount = ignore,
    Object? source = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (storageVersion != ignore) 1: storageVersion as int?,
        if (migratedAt != ignore) 2: migratedAt as DateTime?,
        if (legacyItemCount != ignore) 3: legacyItemCount as int?,
        if (legacyEventCount != ignore) 4: legacyEventCount as int?,
        if (source != ignore) 5: source as StorageSource?,
      });
    } finally {
      q.close();
    }
  }
}

extension StorageMetadataQueryBuilderUpdate
    on QueryBuilder<StorageMetadata, StorageMetadata, QOperations> {
  _StorageMetadataQueryUpdate get updateFirst =>
      _StorageMetadataQueryBuilderUpdateImpl(this, limit: 1);

  _StorageMetadataQueryUpdate get updateAll =>
      _StorageMetadataQueryBuilderUpdateImpl(this);
}

const _storageMetadataSource = {
  0: StorageSource.legacyV3,
  1: StorageSource.fresh,
};

extension StorageMetadataQueryFilter
    on QueryBuilder<StorageMetadata, StorageMetadata, QFilterCondition> {
  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  idGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  idLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  idLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  idBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  storageVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  storageVersionGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  storageVersionGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  storageVersionLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 1, value: value));
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  storageVersionLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  storageVersionBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 1, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  migratedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  migratedAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  migratedAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  migratedAtLessThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 2, value: value));
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  migratedAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  migratedAtBetween(DateTime lower, DateTime upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyItemCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyItemCountGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyItemCountGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyItemCountLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 3, value: value));
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyItemCountLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyItemCountBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyEventCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyEventCountGreaterThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyEventCountGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyEventCountLessThan(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 4, value: value));
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyEventCountLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 4, value: value),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  legacyEventCountBetween(int lower, int upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 4, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  sourceEqualTo(StorageSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  sourceGreaterThan(StorageSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  sourceGreaterThanOrEqualTo(StorageSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  sourceLessThan(StorageSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  sourceLessThanOrEqualTo(StorageSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 5, value: value.index),
      );
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterFilterCondition>
  sourceBetween(StorageSource lower, StorageSource upper) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 5, lower: lower.index, upper: upper.index),
      );
    });
  }
}

extension StorageMetadataQueryObject
    on QueryBuilder<StorageMetadata, StorageMetadata, QFilterCondition> {}

extension StorageMetadataQuerySortBy
    on QueryBuilder<StorageMetadata, StorageMetadata, QSortBy> {
  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByStorageVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByStorageVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByMigratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByMigratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByLegacyItemCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByLegacyItemCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByLegacyEventCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortByLegacyEventCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }
}

extension StorageMetadataQuerySortThenBy
    on QueryBuilder<StorageMetadata, StorageMetadata, QSortThenBy> {
  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByStorageVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByStorageVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByMigratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByMigratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByLegacyItemCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByLegacyItemCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByLegacyEventCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenByLegacyEventCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc);
    });
  }
}

extension StorageMetadataQueryWhereDistinct
    on QueryBuilder<StorageMetadata, StorageMetadata, QDistinct> {
  QueryBuilder<StorageMetadata, StorageMetadata, QAfterDistinct>
  distinctByStorageVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterDistinct>
  distinctByMigratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterDistinct>
  distinctByLegacyItemCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterDistinct>
  distinctByLegacyEventCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<StorageMetadata, StorageMetadata, QAfterDistinct>
  distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5);
    });
  }
}

extension StorageMetadataQueryProperty1
    on QueryBuilder<StorageMetadata, StorageMetadata, QProperty> {
  QueryBuilder<StorageMetadata, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<StorageMetadata, int, QAfterProperty> storageVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StorageMetadata, DateTime, QAfterProperty> migratedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StorageMetadata, int, QAfterProperty> legacyItemCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StorageMetadata, int, QAfterProperty>
  legacyEventCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<StorageMetadata, StorageSource, QAfterProperty>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension StorageMetadataQueryProperty2<R>
    on QueryBuilder<StorageMetadata, R, QAfterProperty> {
  QueryBuilder<StorageMetadata, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<StorageMetadata, (R, int), QAfterProperty>
  storageVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StorageMetadata, (R, DateTime), QAfterProperty>
  migratedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StorageMetadata, (R, int), QAfterProperty>
  legacyItemCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StorageMetadata, (R, int), QAfterProperty>
  legacyEventCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<StorageMetadata, (R, StorageSource), QAfterProperty>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension StorageMetadataQueryProperty3<R1, R2>
    on QueryBuilder<StorageMetadata, (R1, R2), QAfterProperty> {
  QueryBuilder<StorageMetadata, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<StorageMetadata, (R1, R2, int), QOperations>
  storageVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StorageMetadata, (R1, R2, DateTime), QOperations>
  migratedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StorageMetadata, (R1, R2, int), QOperations>
  legacyItemCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StorageMetadata, (R1, R2, int), QOperations>
  legacyEventCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<StorageMetadata, (R1, R2, StorageSource), QOperations>
  sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}
