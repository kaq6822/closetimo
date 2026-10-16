// #40 — 백업 codec: 필드 목록 가드, 왕복, 손상·버전 케이스.

import 'dart:convert';
import 'dart:io';

import 'package:closetimo/data/backup/backup_codec.dart';
import 'package:closetimo/data/backup/backup_format.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

/// Isar 생성 스키마의 속성 이름(+ id). 생성 스키마가 유일한 진실 원천이므로
/// protected 멤버지만 가드 목적으로 읽는다.
Set<String> _schemaFields(IsarGeneratedSchema generated) {
  // ignore: invalid_use_of_protected_member
  final schema = generated.schema;
  return {schema.idName!, for (final p in schema.properties) p.name};
}

Item _fullItem() => Item(
  name: '울 코트',
  brand: 'ZARA',
  category: Category.outer,
  careMethod: CareMethod.dryClean,
  careMode: CareMode.manual,
  purposes: const [ItemPurpose.sport],
  status: ItemStatus.dirty,
  washCycle: 3,
  wearSinceWash: 4,
  totalWears: 9,
  lastWornAt: DateTime(2026, 10, 10, 8, 30),
  lastWashedAt: DateTime(2026, 9, 1),
  purchasedAt: DateTime(2025, 12, 24),
  inLaundry: true,
  imagePath: 'items/7.jpg',
  fallbackColor: 0xFF123456,
  createdAt: DateTime(2025, 12, 25, 10),
  archivedAt: DateTime(2026, 10, 12),
  archiveReason: ArchiveReason.seasonal,
  tags: const ['검정', '여름'],
)..id = 7;

BackupPayload _payload() => BackupPayload(
  createdAt: DateTime(2026, 10, 17, 9, 30),
  items: [_fullItem()],
  imageRefs: {7: BackupFormat.imageRef(7)},
  wearEvents: [
    WearEvent(
      itemId: 7,
      kind: EventKind.wear,
      occurredAt: DateTime(2026, 10, 10, 8, 30),
      note: '출근',
    )..id = 3,
    WearEvent(itemId: 7, kind: EventKind.wash, occurredAt: DateTime(2026, 9, 1))
      ..id = 4,
  ],
  preferences: UserPreferences(
    notifWash: false,
    notifWeekly: true,
    notifUnworn: true,
    accent: 'ink',
    lastTab: '/wardrobe',
    firstLaunchedAt: DateTime(2025, 4, 1),
  ),
);

/// JSON 문자열을 한 번 거쳐 실제 파일과 같은 형태로 만든다.
Map<String, Object?> _json(BackupPayload p) =>
    jsonDecode(jsonEncode(BackupCodec.encode(p))) as Map<String, Object?>;

void main() {
  group('필드 목록 가드 — 모델에 필드가 추가되면 실패해 codec 갱신을 강제한다', () {
    test('Item', () {
      expect(BackupCodec.itemModelFields, _schemaFields(ItemSchema));
      final keys = BackupCodec.encodeItem(_fullItem()).keys.toSet();
      expect(keys, {
        ...BackupCodec.itemModelFields.difference({'imagePath'}),
        'image',
      });
    });

    test('WearEvent', () {
      expect(BackupCodec.wearEventModelFields, _schemaFields(WearEventSchema));
      final e = WearEvent(
        itemId: 1,
        kind: EventKind.wear,
        occurredAt: DateTime(2026),
      );
      expect(
        BackupCodec.encodeWearEvent(e).keys.toSet(),
        BackupCodec.wearEventModelFields,
      );
    });

    test('UserPreferences', () {
      expect(
        BackupCodec.preferencesModelFields,
        _schemaFields(UserPreferencesSchema),
      );
      expect(
        BackupCodec.encodePreferences(UserPreferences()).keys.toSet(),
        BackupCodec.preferencesModelFields.difference({'id'}),
      );
    });
  });

  test('왕복 시 모든 필드와 참조가 보존되고 사진은 아카이브 상대 참조로만 기록된다', () {
    final json = _json(_payload());
    final itemJson = (json['items']! as List).single as Map<String, Object?>;
    expect(itemJson['image'], 'images/7.jpg');
    expect(itemJson.containsKey('imagePath'), isFalse);
    expect(itemJson['category'], 'outer', reason: 'enum은 이름으로 저장');

    final decoded = BackupCodec.decode(json);
    expect(decoded.formatVersion, BackupFormat.currentVersion);
    expect(decoded.createdAt, DateTime(2026, 10, 17, 9, 30));
    expect(decoded.imageRefs, {7: 'images/7.jpg'});

    final a = _fullItem();
    final b = decoded.items.single;
    expect(b.imagePath, isNull, reason: '기기 경로는 복원 시 새로 정한다');
    expect(
      BackupCodec.encodeItem(b, imageRef: 'images/7.jpg'),
      BackupCodec.encodeItem(a, imageRef: 'images/7.jpg'),
    );

    expect(decoded.wearEvents.map(BackupCodec.encodeWearEvent).toList(), [
      for (final e in _payload().wearEvents) BackupCodec.encodeWearEvent(e),
    ]);
    expect(
      BackupCodec.encodePreferences(decoded.preferences!),
      BackupCodec.encodePreferences(_payload().preferences!),
    );
  });

  test('설정 행이 없던 백업은 preferences null로 왕복한다', () {
    final p = BackupPayload(
      createdAt: DateTime(2026),
      items: const [],
      imageRefs: const {},
      wearEvents: const [],
      preferences: null,
    );
    expect(BackupCodec.decode(_json(p)).preferences, isNull);
  });

  group('손상 케이스는 BackupFormatException', () {
    void expectFormatError(void Function(Map<String, Object?> json) mutate) {
      final json = _json(_payload());
      mutate(json);
      expect(
        () => BackupCodec.decode(json),
        throwsA(isA<BackupFormatException>()),
      );
    }

    Map<String, Object?> item(Map<String, Object?> j) =>
        (j['items']! as List).first as Map<String, Object?>;
    Map<String, Object?> event(Map<String, Object?> j) =>
        (j['wearEvents']! as List).first as Map<String, Object?>;

    test('루트가 객체가 아님', () {
      expect(
        () => BackupCodec.decode([1, 2]),
        throwsA(isA<BackupFormatException>()),
      );
    });
    test('format 식별자 불일치', () => expectFormatError((j) => j['format'] = 'x'));
    test('필수 키 누락', () => expectFormatError((j) => item(j).remove('name')));
    test('타입 불일치', () => expectFormatError((j) => item(j)['washCycle'] = '3'));
    test('알 수 없는 enum 이름', () {
      expectFormatError((j) => item(j)['category'] = 'spaceSuit');
    });
    test('잘못된 날짜', () => expectFormatError((j) => item(j)['createdAt'] = 'x'));
    test('빈 이름', () => expectFormatError((j) => item(j)['name'] = '  '));
    test('세탁 주기 0', () => expectFormatError((j) => item(j)['washCycle'] = 0));
    test('옷 id 중복', () {
      expectFormatError((j) => (j['items']! as List).add(item(j)));
    });
    test('기록 id 중복', () {
      expectFormatError((j) => (j['wearEvents']! as List).add(event(j)));
    });
    test('없는 옷을 가리키는 기록(참조 무결성)', () {
      expectFormatError((j) => event(j)['itemId'] = 999);
    });
    test('사진 참조가 아카이브 상대 경로 규칙과 다름', () {
      expectFormatError((j) => item(j)['image'] = '/var/mobile/7.jpg');
    });
  });

  group('버전', () {
    test('앱보다 새로운 formatVersion은 거부', () {
      final json = _json(_payload())
        ..['formatVersion'] = BackupFormat.currentVersion + 1;
      expect(
        () => BackupCodec.decode(json),
        throwsA(
          isA<BackupVersionException>().having(
            (e) => e.isNewer,
            'isNewer',
            true,
          ),
        ),
      );
    });
    test('1 미만 formatVersion은 거부', () {
      final json = _json(_payload())..['formatVersion'] = 0;
      expect(
        () => BackupCodec.decode(json),
        throwsA(isA<BackupVersionException>()),
      );
    });
  });

  test('ENOSPC 파일 오류는 저장 공간 부족으로 분류한다', () {
    expect(
      classifyFileSystemError(
        const FileSystemException('write', '/x', OSError('No space', 28)),
      ),
      isA<BackupStorageFullException>(),
    );
    expect(
      classifyFileSystemError(
        const FileSystemException('write', '/x', OSError('Denied', 13)),
      ),
      isA<BackupIoException>(),
    );
  });
}
