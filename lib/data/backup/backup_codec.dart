// #40 — Isar 모델 ↔ 백업 JSON 명시 매핑. 리플렉션 없이 필드를 하나씩 옮긴다.
//
// 모델에 필드를 추가하면(예: #46 Item 속성) 이 파일 한 곳만 갱신한다:
//   1. *ModelFields에 Isar 속성 이름을 추가한다(가드 테스트가 누락을 잡는다).
//   2. encode/decode에 키를 추가한다.
//   3. BackupFormat.currentVersion을 올리고 이전 버전 decode는 모델 기본값으로 채운다.
//   4. specs/004-backup-restore/data-model.md 표를 갱신한다.

import '../models/item.dart';
import '../models/item_attributes.dart';
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
    this.cutoutRefs = const {},
    this.formatVersion = BackupFormat.currentVersion,
  });

  final int formatVersion;
  final DateTime createdAt;

  /// 옷 레코드. [Item.imagePath]는 기기 경로이므로 직렬화하지 않고 [imageRefs]를 쓴다.
  final List<Item> items;

  /// Item.id → 아카이브 내부 사진 참조(`images/{id}.jpg`). 사진 없는 옷은 키가 없다.
  final Map<int, String> imageRefs;

  /// Item.id → 아카이브 내부 배경 제거본 참조(`images/{id}_cutout.png`, v2). 원본 사진이
  /// 있는 옷만 키를 가진다.
  final Map<int, String> cutoutRefs;

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
    'subType',
    'colors',
    'seasons',
    'material',
    'pattern',
    'cutoutPath', // JSON 키 'cutoutImage'(아카이브 상대 참조)로 옮긴다.
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
    'removeBackground',
    'onDeviceAi',
  };

  // ── 인코딩 ──

  /// 시각은 UTC 순간(`Z`)으로 기록한다. 로컬 시각 문자열은 다른 시간대 기기에서
  /// 복원하면 모든 날짜가 어긋난다(착용·세탁 순서 판정에도 영향).
  static String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

  static Map<String, Object?> encode(BackupPayload payload) => {
    'format': BackupFormat.id,
    'formatVersion': BackupFormat.currentVersion,
    'createdAt': _iso(payload.createdAt),
    'items': [
      for (final item in payload.items)
        encodeItem(
          item,
          imageRef: payload.imageRefs[item.id],
          cutoutRef: payload.cutoutRefs[item.id],
        ),
    ],
    'wearEvents': [for (final e in payload.wearEvents) encodeWearEvent(e)],
    'preferences': payload.preferences == null
        ? null
        : encodePreferences(payload.preferences!),
  };

  static Map<String, Object?> encodeItem(
    Item item, {
    String? imageRef,
    String? cutoutRef,
  }) => {
    'id': item.id,
    'name': item.name,
    'brand': item.brand,
    'category': item.category.name,
    'careMethod': item.careMethod.name,
    'status': item.status.name,
    'washCycle': item.washCycle,
    'wearSinceWash': item.wearSinceWash,
    'totalWears': item.totalWears,
    'lastWornAt': _iso(item.lastWornAt),
    'lastWashedAt': _iso(item.lastWashedAt),
    'purchasedAt': _iso(item.purchasedAt),
    'inLaundry': item.inLaundry,
    'image': imageRef,
    'fallbackColor': item.fallbackColor,
    'createdAt': _iso(item.createdAt),
    'careMode': item.careMode.name,
    'purposes': [for (final p in item.purposes) p.name],
    'archivedAt': _iso(item.archivedAt),
    'archiveReason': item.archiveReason.name,
    'tags': item.tags,
    'subType': item.subType,
    'colors': item.colors,
    'seasons': [for (final s in item.seasons) s.name],
    'material': item.material,
    'pattern': item.pattern,
    'cutoutImage': cutoutRef,
  };

  static Map<String, Object?> encodeWearEvent(WearEvent e) => {
    'id': e.id,
    'itemId': e.itemId,
    'kind': e.kind.name,
    'occurredAt': _iso(e.occurredAt),
    'note': e.note,
  };

  static Map<String, Object?> encodePreferences(UserPreferences p) => {
    'notifWash': p.notifWash,
    'notifWeekly': p.notifWeekly,
    'notifUnworn': p.notifUnworn,
    'accent': p.accent,
    'lastTab': p.lastTab,
    'firstLaunchedAt': _iso(p.firstLaunchedAt),
    'removeBackground': p.removeBackground,
    'onDeviceAi': p.onDeviceAi,
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
    // 버전별 디코더. v2(005)는 v1에 키를 더한 형식이라 같은 디코더에서 버전으로
    // 분기하고, v1은 새 필드를 모델 기본값으로 채운다.
    final payload = _decode(root, version);
    _validateReferences(payload);
    return payload;
  }

  static BackupPayload _decode(_Obj root, int version) {
    final v2 = version >= 2;
    final items = <Item>[];
    final imageRefs = <int, String>{};
    final cutoutRefs = <int, String>{};
    for (final (i, raw) in root.list('items').indexed) {
      final o = _Obj.from(raw, 'items[$i]');
      final item = _decodeItem(o, v2: v2);
      items.add(item);
      final ref = o.nullableString('image');
      if (ref != null) imageRefs[item.id] = ref;
      // 원본 사진 없는 배경 제거본은 앱 규칙(data-model §1)에 맞지 않아 버린다.
      final cutout = v2 ? o.nullableString('cutoutImage') : null;
      if (cutout != null && ref != null) cutoutRefs[item.id] = cutout;
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
      cutoutRefs: cutoutRefs,
      wearEvents: events,
      preferences: prefsRaw == null
          ? null
          : _decodePreferences(_Obj.from(prefsRaw, 'preferences'), v2: v2),
    );
  }

  static Item _decodeItem(_Obj o, {required bool v2}) {
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
    final item = Item(
      name: name,
      brand: o.nullableString('brand'),
      category: o.enumValue('category', Category.values),
      careMethod: o.enumValue('careMethod', CareMethod.values),
      // 임시 값. 아래에서 카운터·관리 방식으로 다시 계산한다.
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
      // 손으로 편집한 백업의 중복 용도를 정리한다(순서 유지).
      purposes: o.enumList('purposes', ItemPurpose.values).toSet().toList(),
      archivedAt: archivedAt,
      archiveReason: o.enumValue('archiveReason', ArchiveReason.values),
      // 앱 입력 규칙(공백 정리·20자·대소문자 중복)을 복원 값에도 적용한다.
      tags: normalizeTags(o.stringList('tags')),
    )..id = o.integer('id');
    if (v2) {
      // 손으로 편집한 백업 방어: 알 수 없는 코드·종류와 맞지 않는 세부 종류를 정리한다.
      ItemAttributeValues(
        subType: o.nullableString('subType'),
        colors: o.stringList('colors'),
        seasons: o.enumList('seasons', Season.values),
        material: o.nullableString('material'),
        pattern: o.nullableString('pattern'),
      ).applyTo(item);
    }
    // 파생값(status)은 저장된 값을 믿지 않고 앱 규칙(FR-011)으로 다시 계산한다.
    item.status = item.derivedStatus;
    return item;
  }

  static WearEvent _decodeWearEvent(_Obj o) => WearEvent(
    itemId: o.integer('itemId'),
    kind: o.enumValue('kind', EventKind.values),
    occurredAt: o.dateTime('occurredAt'),
    note: o.nullableString('note'),
  )..id = o.integer('id');

  static UserPreferences _decodePreferences(_Obj o, {required bool v2}) =>
      UserPreferences(
        notifWash: o.boolean('notifWash'),
        notifWeekly: o.boolean('notifWeekly'),
        notifUnworn: o.boolean('notifUnworn'),
        accent: o.string('accent'),
        lastTab: o.nullableString('lastTab'),
        firstLaunchedAt: o.nullableDateTime('firstLaunchedAt'),
        removeBackground: v2 ? o.boolean('removeBackground') : true,
        onDeviceAi: v2 ? o.boolean('onDeviceAi') : false,
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
    for (final MapEntry(key: id, value: ref) in p.cutoutRefs.entries) {
      if (ref != BackupFormat.cutoutRef(id)) {
        throw BackupFormatException('item $id has invalid cutout ref "$ref"');
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

  // 오프셋이 없는 문자열은 로컬로 읽히고, `Z`는 UTC 순간이므로 로컬로 바꿔 돌려준다.
  DateTime? _parseDate(String key, String s) => DateTime.tryParse(s)?.toLocal();

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
