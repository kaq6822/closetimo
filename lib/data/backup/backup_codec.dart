// #40 — Isar 모델 ↔ 백업 JSON 명시 매핑. 리플렉션 없이 필드를 하나씩 옮긴다.
//
// 모델에 필드를 추가하면(예: #46 Item 속성) 이 파일 한 곳만 갱신한다:
//   1. *ModelFields에 Isar 속성 이름을 추가한다(가드 테스트가 누락을 잡는다).
//   2. encode/decode에 키를 추가한다.
//   3. BackupFormat.currentVersion을 올리고 이전 버전 decode는 모델 기본값으로 채운다.
//   4. specs/004-backup-restore/data-model.md 표를 갱신한다.

import '../models/item.dart';
import '../models/item_tags.dart';
import '../models/user_preferences.dart';
import '../models/wear_event.dart';
import 'backup_format.dart';

/// `backup.json`에 담기는 내용.
class BackupPayload {
  const BackupPayload({
    required this.createdAt,
    required this.items,
    required this.imageRefs,
    required this.wearEvents,
    required this.preferences,
    this.formatVersion = BackupFormat.currentVersion,
  });

  final int formatVersion;
  final DateTime createdAt;

  /// 옷 레코드. [Item.imagePath]는 기기 경로이므로 직렬화하지 않고 [imageRefs]를 쓴다.
  final List<Item> items;

  /// Item.id → 아카이브 내부 사진 참조(`images/{id}.jpg`). 사진 없는 옷은 키가 없다.
  final Map<int, String> imageRefs;

  final List<WearEvent> wearEvents;

  /// 설정 행이 없었으면 null.
  final UserPreferences? preferences;
}

abstract final class BackupCodec {
  /// codec이 다루는 Item의 Isar 속성(+ id). 가드 테스트가 생성 스키마와 비교한다.
  static const Set<String> itemModelFields = {
    'id',
    'name',
    'brand',
    'category',
    'careMethod',
    'status',
    'washCycle',
    'wearSinceWash',
    'totalWears',
    'lastWornAt',
    'lastWashedAt',
    'purchasedAt',
    'inLaundry',
    'imagePath', // JSON 키 'image'(아카이브 상대 참조)로 옮긴다.
    'fallbackColor',
    'createdAt',
    'careMode',
    'purposes',
    'archivedAt',
    'archiveReason',
    'tags',
  };

  /// codec이 다루는 WearEvent의 Isar 속성(+ id).
  static const Set<String> wearEventModelFields = {
    'id',
    'itemId',
    'kind',
    'occurredAt',
    'note',
  };

  /// codec이 다루는 UserPreferences의 Isar 속성(+ id, id는 singleton이라 직렬화하지 않음).
  static const Set<String> preferencesModelFields = {
    'id',
    'notifWash',
    'notifWeekly',
    'notifUnworn',
    'accent',
    'lastTab',
    'firstLaunchedAt',
  };

  // ── 인코딩 ──

  static Map<String, Object?> encode(BackupPayload payload) => {
    'format': BackupFormat.id,
    'formatVersion': BackupFormat.currentVersion,
    'createdAt': payload.createdAt.toIso8601String(),
    'items': [
      for (final item in payload.items)
        encodeItem(item, imageRef: payload.imageRefs[item.id]),
    ],
    'wearEvents': [for (final e in payload.wearEvents) encodeWearEvent(e)],
    'preferences': payload.preferences == null
        ? null
        : encodePreferences(payload.preferences!),
  };

  static Map<String, Object?> encodeItem(Item item, {String? imageRef}) => {
    'id': item.id,
    'name': item.name,
    'brand': item.brand,
    'category': item.category.name,
    'careMethod': item.careMethod.name,
    'status': item.status.name,
    'washCycle': item.washCycle,
    'wearSinceWash': item.wearSinceWash,
    'totalWears': item.totalWears,
    'lastWornAt': item.lastWornAt?.toIso8601String(),
    'lastWashedAt': item.lastWashedAt?.toIso8601String(),
    'purchasedAt': item.purchasedAt?.toIso8601String(),
    'inLaundry': item.inLaundry,
    'image': imageRef,
    'fallbackColor': item.fallbackColor,
    'createdAt': item.createdAt.toIso8601String(),
    'careMode': item.careMode.name,
    'purposes': [for (final p in item.purposes) p.name],
    'archivedAt': item.archivedAt?.toIso8601String(),
    'archiveReason': item.archiveReason.name,
    'tags': item.tags,
  };

  static Map<String, Object?> encodeWearEvent(WearEvent e) => {
    'id': e.id,
    'itemId': e.itemId,
    'kind': e.kind.name,
    'occurredAt': e.occurredAt.toIso8601String(),
    'note': e.note,
  };

  static Map<String, Object?> encodePreferences(UserPreferences p) => {
    'notifWash': p.notifWash,
    'notifWeekly': p.notifWeekly,
    'notifUnworn': p.notifUnworn,
    'accent': p.accent,
    'lastTab': p.lastTab,
    'firstLaunchedAt': p.firstLaunchedAt?.toIso8601String(),
  };

  // ── 디코딩 ──

  /// `backup.json`을 해석하고 참조 무결성까지 검증한다.
  /// 형식·필드 오류는 [BackupFormatException], 버전 오류는 [BackupVersionException].
  static BackupPayload decode(Object? json) {
    final root = _Obj.from(json, 'backup.json');
    if (root.string('format') != BackupFormat.id) {
      throw const BackupFormatException('not a closetimo backup');
    }
    final version = root.integer('formatVersion');
    if (version < 1 || version > BackupFormat.currentVersion) {
      throw BackupVersionException(
        found: version,
        supported: BackupFormat.currentVersion,
      );
    }
    // 버전별 디코더. 새 버전을 추가하면 `switch (version)`으로 분기하고 이전
    // 버전 분기는 없는 필드를 모델 기본값으로 채운다.
    final payload = _decodeV1(root, version);
    _validateReferences(payload);
    return payload;
  }

  static BackupPayload _decodeV1(_Obj root, int version) {
    final items = <Item>[];
    final imageRefs = <int, String>{};
    for (final (i, raw) in root.list('items').indexed) {
      final o = _Obj.from(raw, 'items[$i]');
      final item = _decodeItem(o);
      items.add(item);
      final ref = o.nullableString('image');
      if (ref != null) imageRefs[item.id] = ref;
    }
    final events = [
      for (final (i, raw) in root.list('wearEvents').indexed)
        _decodeWearEvent(_Obj.from(raw, 'wearEvents[$i]')),
    ];
    final prefsRaw = root.raw('preferences');
    return BackupPayload(
      formatVersion: version,
      createdAt: root.dateTime('createdAt'),
      items: items,
      imageRefs: imageRefs,
      wearEvents: events,
      preferences: prefsRaw == null
          ? null
          : _decodePreferences(_Obj.from(prefsRaw, 'preferences')),
    );
  }

  static Item _decodeItem(_Obj o) {
    final name = o.string('name');
    if (name.trim().isEmpty) o.fail('name', 'must be non-empty');
    final washCycle = o.integer('washCycle');
    if (washCycle < 1) o.fail('washCycle', 'must be >= 1');
    final wearSinceWash = o.integer('wearSinceWash');
    final totalWears = o.integer('totalWears');
    if (wearSinceWash < 0 || totalWears < 0) {
      o.fail('wearSinceWash/totalWears', 'must be >= 0');
    }
    final fallbackColor = o.integer('fallbackColor');
    if (fallbackColor < 0 || fallbackColor > 0xFFFFFFFF) {
      o.fail('fallbackColor', 'must be a 32-bit ARGB value');
    }
    final archivedAt = o.nullableDateTime('archivedAt');
    final inLaundry = o.boolean('inLaundry');
    return Item(
      name: name,
      brand: o.nullableString('brand'),
      category: o.enumValue('category', Category.values),
      careMethod: o.enumValue('careMethod', CareMethod.values),
      status: o.enumValue('status', ItemStatus.values),
      washCycle: washCycle,
      wearSinceWash: wearSinceWash,
      totalWears: totalWears,
      lastWornAt: o.nullableDateTime('lastWornAt'),
      lastWashedAt: o.nullableDateTime('lastWashedAt'),
      purchasedAt: o.nullableDateTime('purchasedAt'),
      // 보관한 옷은 바구니에 담을 수 없다(#44). 손으로 편집한 백업을 방어한다.
      inLaundry: inLaundry && archivedAt == null,
      fallbackColor: fallbackColor,
      createdAt: o.dateTime('createdAt'),
      careMode: o.enumValue('careMode', CareMode.values),
      purposes: o.enumList('purposes', ItemPurpose.values),
      archivedAt: archivedAt,
      archiveReason: o.enumValue('archiveReason', ArchiveReason.values),
      // 앱 입력 규칙(공백 정리·20자·대소문자 중복)을 복원 값에도 적용한다.
      tags: normalizeTags(o.stringList('tags')),
    )..id = o.integer('id');
  }

  static WearEvent _decodeWearEvent(_Obj o) => WearEvent(
    itemId: o.integer('itemId'),
    kind: o.enumValue('kind', EventKind.values),
    occurredAt: o.dateTime('occurredAt'),
    note: o.nullableString('note'),
  )..id = o.integer('id');

  static UserPreferences _decodePreferences(_Obj o) => UserPreferences(
    notifWash: o.boolean('notifWash'),
    notifWeekly: o.boolean('notifWeekly'),
    notifUnworn: o.boolean('notifUnworn'),
    accent: o.string('accent'),
    lastTab: o.nullableString('lastTab'),
    firstLaunchedAt: o.nullableDateTime('firstLaunchedAt'),
  );

  static void _validateReferences(BackupPayload p) {
    final itemIds = <int>{};
    for (final item in p.items) {
      if (!itemIds.add(item.id)) {
        throw BackupFormatException('duplicate item id ${item.id}');
      }
    }
    final eventIds = <int>{};
    for (final e in p.wearEvents) {
      if (!eventIds.add(e.id)) {
        throw BackupFormatException('duplicate wear event id ${e.id}');
      }
      if (!itemIds.contains(e.itemId)) {
        throw BackupFormatException(
          'wear event ${e.id} references missing item ${e.itemId}',
        );
      }
    }
    for (final MapEntry(key: id, value: ref) in p.imageRefs.entries) {
      if (ref != BackupFormat.imageRef(id)) {
        throw BackupFormatException('item $id has invalid image ref "$ref"');
      }
    }
  }
}

/// 엄격한 JSON 객체 리더. 키 누락·타입 불일치는 위치와 함께 [BackupFormatException].
class _Obj {
  _Obj._(this._map, this._path);

  factory _Obj.from(Object? raw, String path) {
    if (raw is! Map<String, Object?>) {
      throw BackupFormatException('$path must be an object');
    }
    return _Obj._(raw, path);
  }

  final Map<String, Object?> _map;
  final String _path;

  Never fail(String key, String message) =>
      throw BackupFormatException('$_path.$key $message');

  Object? raw(String key) {
    if (!_map.containsKey(key)) fail(key, 'is missing');
    return _map[key];
  }

  T _typed<T>(String key, String typeName) {
    final v = raw(key);
    if (v is! T) fail(key, 'must be $typeName');
    return v;
  }

  String string(String key) => _typed<String>(key, 'a string');
  String? nullableString(String key) =>
      _typed<String?>(key, 'a string or null');
  int integer(String key) => _typed<int>(key, 'an integer');
  bool boolean(String key) => _typed<bool>(key, 'a boolean');
  List<Object?> list(String key) => _typed<List<Object?>>(key, 'an array');

  DateTime dateTime(String key) =>
      _parseDate(key, string(key)) ?? fail(key, 'is not a datetime');

  DateTime? nullableDateTime(String key) {
    final s = nullableString(key);
    if (s == null) return null;
    return _parseDate(key, s) ?? fail(key, 'is not a datetime');
  }

  DateTime? _parseDate(String key, String s) => DateTime.tryParse(s);

  T enumValue<T extends Enum>(String key, List<T> values) =>
      _byName(key, string(key), values);

  List<T> enumList<T extends Enum>(String key, List<T> values) => [
    for (final v in list(key))
      if (v is String) _byName(key, v, values) else fail(key, 'must be names'),
  ];

  List<String> stringList(String key) => [
    for (final v in list(key))
      if (v is String) v else fail(key, 'must be strings'),
  ];

  T _byName<T extends Enum>(String key, String name, List<T> values) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    fail(key, 'has unknown value "$name"');
  }
}
