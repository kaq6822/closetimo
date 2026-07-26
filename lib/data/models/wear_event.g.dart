// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wear_event.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetWearEventCollection on Isar {
  IsarCollection<int, WearEvent> get wearEvents => this.collection();
}

final WearEventSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'WearEvent',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(name: 'itemId', type: IsarType.long),
      IsarPropertySchema(
        name: 'kind',
        type: IsarType.byte,

        enumMap: {"wear": 0, "wash": 1},
      ),
      IsarPropertySchema(name: 'occurredAt', type: IsarType.dateTime),
      IsarPropertySchema(name: 'note', type: IsarType.string),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'itemId',
        properties: ["itemId"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'kind',
        properties: ["kind"],
        unique: false,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'occurredAt',
        properties: ["occurredAt"],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, WearEvent>(
    serialize: serializeWearEvent,
    deserialize: deserializeWearEvent,
    deserializeProperty: deserializeWearEventProp,
  ),
  getEmbeddedSchemas: () => [],
);

@isarProtected
int serializeWearEvent(IsarWriter writer, WearEvent object) {
  IsarCore.writeLong(writer, 1, object.itemId);
  IsarCore.writeByte(writer, 2, object.kind.index);
  IsarCore.writeLong(
    writer,
    3,
    object.occurredAt.toUtc().microsecondsSinceEpoch,
  );
  {
    final value = object.note;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  return object.id;
}

@isarProtected
WearEvent deserializeWearEvent(IsarReader reader) {
  final int _itemId;
  _itemId = IsarCore.readLong(reader, 1);
  final EventKind _kind;
  {
    if (IsarCore.readNull(reader, 2)) {
      _kind = EventKind.wear;
    } else {
      _kind = _wearEventKind[IsarCore.readByte(reader, 2)] ?? EventKind.wear;
    }
  }
  final DateTime _occurredAt;
  {
    final value = IsarCore.readLong(reader, 3);
    if (value == -9223372036854775808) {
      _occurredAt = DateTime.fromMillisecondsSinceEpoch(
        0,
        isUtc: true,
      ).toLocal();
    } else {
      _occurredAt = DateTime.fromMicrosecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
    }
  }
  final String? _note;
  _note = IsarCore.readString(reader, 4);
  final object = WearEvent(
    itemId: _itemId,
    kind: _kind,
    occurredAt: _occurredAt,
    note: _note,
  );
  object.id = IsarCore.readId(reader);
  return object;
}

@isarProtected
dynamic deserializeWearEventProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    case 2:
      {
        if (IsarCore.readNull(reader, 2)) {
          return EventKind.wear;
        } else {
          return _wearEventKind[IsarCore.readByte(reader, 2)] ?? EventKind.wear;
        }
      }
    case 3:
      {
        final value = IsarCore.readLong(reader, 3);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(
            value,
            isUtc: true,
          ).toLocal();
        }
      }
    case 4:
      return IsarCore.readString(reader, 4);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _WearEventUpdate {
  bool call({
    required int id,
    int? itemId,
    EventKind? kind,
    DateTime? occurredAt,
    String? note,
  });
}

class _WearEventUpdateImpl implements _WearEventUpdate {
  const _WearEventUpdateImpl(this.collection);

  final IsarCollection<int, WearEvent> collection;

  @override
  bool call({
    required int id,
    Object? itemId = ignore,
    Object? kind = ignore,
    Object? occurredAt = ignore,
    Object? note = ignore,
  }) {
    return collection.updateProperties(
          [id],
          {
            if (itemId != ignore) 1: itemId as int?,
            if (kind != ignore) 2: kind as EventKind?,
            if (occurredAt != ignore) 3: occurredAt as DateTime?,
            if (note != ignore) 4: note as String?,
          },
        ) >
        0;
  }
}

sealed class _WearEventUpdateAll {
  int call({
    required List<int> id,
    int? itemId,
    EventKind? kind,
    DateTime? occurredAt,
    String? note,
  });
}

class _WearEventUpdateAllImpl implements _WearEventUpdateAll {
  const _WearEventUpdateAllImpl(this.collection);

  final IsarCollection<int, WearEvent> collection;

  @override
  int call({
    required List<int> id,
    Object? itemId = ignore,
    Object? kind = ignore,
    Object? occurredAt = ignore,
    Object? note = ignore,
  }) {
    return collection.updateProperties(id, {
      if (itemId != ignore) 1: itemId as int?,
      if (kind != ignore) 2: kind as EventKind?,
      if (occurredAt != ignore) 3: occurredAt as DateTime?,
      if (note != ignore) 4: note as String?,
    });
  }
}

extension WearEventUpdate on IsarCollection<int, WearEvent> {
  _WearEventUpdate get update => _WearEventUpdateImpl(this);

  _WearEventUpdateAll get updateAll => _WearEventUpdateAllImpl(this);
}

sealed class _WearEventQueryUpdate {
  int call({int? itemId, EventKind? kind, DateTime? occurredAt, String? note});
}

class _WearEventQueryUpdateImpl implements _WearEventQueryUpdate {
  const _WearEventQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<WearEvent> query;
  final int? limit;

  @override
  int call({
    Object? itemId = ignore,
    Object? kind = ignore,
    Object? occurredAt = ignore,
    Object? note = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (itemId != ignore) 1: itemId as int?,
      if (kind != ignore) 2: kind as EventKind?,
      if (occurredAt != ignore) 3: occurredAt as DateTime?,
      if (note != ignore) 4: note as String?,
    });
  }
}

extension WearEventQueryUpdate on IsarQuery<WearEvent> {
  _WearEventQueryUpdate get updateFirst =>
      _WearEventQueryUpdateImpl(this, limit: 1);

  _WearEventQueryUpdate get updateAll => _WearEventQueryUpdateImpl(this);
}

class _WearEventQueryBuilderUpdateImpl implements _WearEventQueryUpdate {
  const _WearEventQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<WearEvent, WearEvent, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? itemId = ignore,
    Object? kind = ignore,
    Object? occurredAt = ignore,
    Object? note = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (itemId != ignore) 1: itemId as int?,
        if (kind != ignore) 2: kind as EventKind?,
        if (occurredAt != ignore) 3: occurredAt as DateTime?,
        if (note != ignore) 4: note as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension WearEventQueryBuilderUpdate
    on QueryBuilder<WearEvent, WearEvent, QOperations> {
  _WearEventQueryUpdate get updateFirst =>
      _WearEventQueryBuilderUpdateImpl(this, limit: 1);

  _WearEventQueryUpdate get updateAll => _WearEventQueryBuilderUpdateImpl(this);
}

const _wearEventKind = {0: EventKind.wear, 1: EventKind.wash};

extension WearEventQueryFilter
    on QueryBuilder<WearEvent, WearEvent, QFilterCondition> {
  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  idGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 0, value: value));
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 0, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 0, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> itemIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> itemIdGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  itemIdGreaterThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> itemIdLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 1, value: value));
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  itemIdLessThanOrEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 1, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> itemIdBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 1, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> kindEqualTo(
    EventKind value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 2, value: value.index),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> kindGreaterThan(
    EventKind value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 2, value: value.index),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  kindGreaterThanOrEqualTo(EventKind value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 2, value: value.index),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> kindLessThan(
    EventKind value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 2, value: value.index),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  kindLessThanOrEqualTo(EventKind value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 2, value: value.index),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> kindBetween(
    EventKind lower,
    EventKind upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 2, lower: lower.index, upper: upper.index),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> occurredAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  occurredAtGreaterThan(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  occurredAtGreaterThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> occurredAtLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(LessCondition(property: 3, value: value));
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  occurredAtLessThanOrEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(property: 3, value: value),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> occurredAtBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(property: 3, lower: lower, upper: upper),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  noteGreaterThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(property: 4, value: value, caseSensitive: caseSensitive),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition>
  noteLessThanOrEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(property: 4, value: ''),
      );
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(property: 4, value: ''),
      );
    });
  }
}

extension WearEventQueryObject
    on QueryBuilder<WearEvent, WearEvent, QFilterCondition> {}

extension WearEventQuerySortBy on QueryBuilder<WearEvent, WearEvent, QSortBy> {
  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> sortByNoteDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension WearEventQuerySortThenBy
    on QueryBuilder<WearEvent, WearEvent, QSortThenBy> {
  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByItemIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterSortBy> thenByNoteDesc({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension WearEventQueryWhereDistinct
    on QueryBuilder<WearEvent, WearEvent, QDistinct> {
  QueryBuilder<WearEvent, WearEvent, QAfterDistinct> distinctByItemId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterDistinct> distinctByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterDistinct> distinctByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<WearEvent, WearEvent, QAfterDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }
}

extension WearEventQueryProperty1
    on QueryBuilder<WearEvent, WearEvent, QProperty> {
  QueryBuilder<WearEvent, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<WearEvent, int, QAfterProperty> itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<WearEvent, EventKind, QAfterProperty> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<WearEvent, DateTime, QAfterProperty> occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<WearEvent, String?, QAfterProperty> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension WearEventQueryProperty2<R>
    on QueryBuilder<WearEvent, R, QAfterProperty> {
  QueryBuilder<WearEvent, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<WearEvent, (R, int), QAfterProperty> itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<WearEvent, (R, EventKind), QAfterProperty> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<WearEvent, (R, DateTime), QAfterProperty> occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<WearEvent, (R, String?), QAfterProperty> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension WearEventQueryProperty3<R1, R2>
    on QueryBuilder<WearEvent, (R1, R2), QAfterProperty> {
  QueryBuilder<WearEvent, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<WearEvent, (R1, R2, int), QOperations> itemIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<WearEvent, (R1, R2, EventKind), QOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<WearEvent, (R1, R2, DateTime), QOperations>
  occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<WearEvent, (R1, R2, String?), QOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}
