// #40 — 실제 Isar(임시 디렉터리)로 백업 → 빈 DB 복원과 실패 경로의 원자성을 검증한다.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/backup/backup_codec.dart';
import 'package:closetimo/data/backup/backup_format.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_archive_repository.dart';
import 'package:closetimo/data/repositories/isar_backup_repository.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/data/repositories/isar_preferences_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path/path.dart' as p;

import '../support/isar_plus_test_support.dart';

class _FixedClock implements Clock {
  DateTime value = DateTime(2026, 10, 17, 9, 30);
  @override
  DateTime now() => value;
}

/// 지정한 번째 쓰기부터 ENOSPC를 던지는 이미지 저장소(공간 부족 재현).
class _FullDiskImageStore extends ImageStore {
  _FullDiskImageStore({required super.overrideRoot, required this.failFrom});

  final int failFrom;
  int writes = 0;

  @override
  Future<String> writeBytes(String fileName, List<int> bytes) async {
    writes++;
    if (writes >= failFrom) {
      throw const FileSystemException(
        'write',
        'items',
        OSError('No space left on device', 28),
      );
    }
    return super.writeBytes(fileName, bytes);
  }
}

/// 한 기기(Isar + 사진 디렉터리 + repository 묶음).
class _Device {
  _Device(this.root, String name, {ImageStore Function(Directory)? store})
    : clock = _FixedClock() {
    imagesDir = Directory(p.join(root.path, 'images'))..createSync();
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: root.path,
      name: name,
      inspector: false,
    );
    imageStore = store?.call(imagesDir) ?? ImageStore(overrideRoot: imagesDir);
    items = IsarItemRepository(
      isar: isar,
      imageStore: imageStore,
      clock: clock,
    );
    events = IsarEventRepository(isar: isar, clock: clock);
    laundry = IsarLaundryRepository(isar: isar, clock: clock);
    archive = IsarArchiveRepository(isar: isar, clock: clock);
    prefs = IsarPreferencesRepository(isar: isar);
    backup = IsarBackupRepository(
      isar: isar,
      imageStore: imageStore,
      clock: clock,
      random: Random(1),
    );
  }

  final Directory root;
  final _FixedClock clock;
  late final Directory imagesDir;
  late final Isar isar;
  late final ImageStore imageStore;
  late final IsarItemRepository items;
  late final IsarEventRepository events;
  late final IsarLaundryRepository laundry;
  late final IsarArchiveRepository archive;
  late final IsarPreferencesRepository prefs;
  late final IsarBackupRepository backup;

  void close() {
    if (isar.isOpen) isar.close(deleteFromDisk: true);
  }

  /// 사진 경로를 제외한 전체 상태 스냅숏(비교용).
  Map<String, Object?> snapshot() => {
    'items': [
      for (final i in isar.items.where().sortById().findAll())
        BackupCodec.encodeItem(i)..remove('image'),
    ],
    'events': [
      for (final e in isar.wearEvents.where().sortById().findAll())
        BackupCodec.encodeWearEvent(e),
    ],
    'prefs': switch (isar.userPreferences.get(UserPreferences.singletonId)) {
      final p? => BackupCodec.encodePreferences(p),
      null => null,
    },
  };

  /// 옷 id → 사진 바이트.
  Future<Map<int, List<int>>> photoBytes() async => {
    for (final i in isar.items.where().findAll())
      if (i.imagePath != null)
        i.id: await File(
          await imageStore.absolutePath(i.imagePath!),
        ).readAsBytes(),
  };

  Set<String> imageFileNames() => {
    for (final f in imagesDir.listSync()) p.basename(f.path),
  };
}

Uint8List _photo(int seed, [int length = 4096]) {
  final r = Random(seed);
  return Uint8List.fromList(List.generate(length, (_) => r.nextInt(256)));
}

void main() {
  setUpAll(initializeIsarPlusForTests);

  late Directory tmp;
  late _Device source;
  final extra = <_Device>[];

  _Device device(String name, {ImageStore Function(Directory)? store}) {
    final d = _Device(
      Directory(p.join(tmp.path, name))..createSync(),
      name,
      store: store,
    );
    extra.add(d);
    return d;
  }

  /// 원본 기기에 옷·사진·기록·보관·설정을 만든다.
  Future<void> seed(_Device d) async {
    final photoA = File(p.join(tmp.path, 'a.jpg'))..writeAsBytesSync(_photo(1));
    final photoB = File(p.join(tmp.path, 'b.jpg'))..writeAsBytesSync(_photo(2));
    final coat = await d.items.create(
      NewItemDraft(
        name: '울 코트',
        brand: 'ZARA',
        category: Category.outer,
        careMethod: CareMethod.dryClean,
        washCycle: 2,
        purchasedAt: DateTime(2025, 11, 3),
        tempPhoto: photoA,
      ),
    );
    final shirt = await d.items.create(
      NewItemDraft(
        name: '린넨 셔츠',
        category: Category.top,
        purposes: const [ItemPurpose.sport],
        tags: const ['검정', '여름'],
        careMode: CareMode.manual,
        tempPhoto: photoB,
      ),
    );
    final bag = await d.items.create(const NewItemDraft(name: '토트백'));
    await d.events.recordWear(coat, note: '출근');
    d.clock.value = d.clock.value.add(const Duration(hours: 1));
    await d.events.recordWear(coat);
    await d.laundry.toggle(shirt); // 바구니에 담긴 채로 백업된다.
    await d.laundry.toggle(coat);
    await d.laundry.completeWashFor([coat]);
    await d.events.recordWear(shirt);
    await d.archive.archive(bag, reason: ArchiveReason.seasonal);
    await d.prefs.setNotifWash(false);
    await d.prefs.setNotifUnworn(true);
    await d.prefs.setAccent('ink');
    await d.prefs.setLastTab('/wardrobe');
  }

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('closetimo_backup');
    source = device('source');
    await seed(source);
  });

  tearDown(() {
    for (final d in extra) {
      d.close();
    }
    extra.clear();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<File> makeBackup() async => (await source.backup.createBackup(
    Directory(p.join(tmp.path, 'out')),
  )).file;

  test('백업 → 빈 DB 복원 시 옷·사진·기록·보관·설정·참조가 동일하다', () async {
    final export = await source.backup.createBackup(
      Directory(p.join(tmp.path, 'out')),
    );
    expect(
      p.basename(export.file.path),
      'closetimo-backup-20261017-103000.zip',
    );
    expect(export.counts.items, 3);
    expect(export.counts.images, 2);
    expect(export.counts.wearEvents, source.isar.wearEvents.count());
    expect(export.missingImageCount, 0);

    final target = device('target');
    final preview = await target.backup.inspect(export.file);
    expect(preview.formatVersion, BackupFormat.currentVersion);
    expect(preview.createdAt, source.clock.value);
    expect(preview.counts.items, 3);

    final result = await target.backup.restore(preview);
    expect(result.counts.items, 3);

    expect(target.snapshot(), source.snapshot());
    expect(await target.photoBytes(), await source.photoBytes());
    // 기록 → 옷 참조가 그대로 이어진다.
    final coat = target.isar.items.where().nameEqualTo('울 코트').findFirst()!;
    final coatEvents = target.isar.wearEvents
        .where()
        .itemIdEqualTo(coat.id)
        .findAll();
    expect(coatEvents.map((e) => e.kind), contains(EventKind.wash));
    expect(coatEvents.any((e) => e.note == '출근'), isTrue);
    // 태그(#46)·보관 상태와 설정.
    final shirtBack = target.isar.items
        .where()
        .nameEqualTo('린넨 셔츠')
        .findFirst()!;
    expect(shirtBack.tags, ['검정', '여름']);
    final bag = target.isar.items.where().nameEqualTo('토트백').findFirst()!;
    expect(bag.archiveReason, ArchiveReason.seasonal);
    expect(bag.isArchived, isTrue);
    final prefs = target.isar.userPreferences.get(0)!;
    expect(prefs.notifWash, isFalse);
    expect(prefs.lastTab, '/wardrobe');

    // 복원 후 새로 등록한 옷의 id가 복원된 id와 충돌하지 않는다.
    final restoredIds = target.isar.items.where().idProperty().findAll();
    final newId = await target.items.create(const NewItemDraft(name: '새 옷'));
    expect(restoredIds, isNot(contains(newId)));
    expect(target.isar.items.count(), 4);
  });

  test('같은 백업을 두 번 복원해도 중복 없이 같은 상태이고 고아 사진이 남지 않는다', () async {
    final file = await makeBackup();
    final target = device('target');
    // 기존 데이터가 있는 기기(사진 1장 포함).
    await target.items.create(
      NewItemDraft(name: '기존 옷', tempPhoto: File(p.join(tmp.path, 'a.jpg'))),
    );
    expect(target.imageFileNames(), hasLength(1));

    await target.backup.restore(await target.backup.inspect(file));
    final first = target.snapshot();
    await target.backup.restore(await target.backup.inspect(file));

    expect(target.snapshot(), first);
    expect(target.snapshot(), source.snapshot());
    expect(target.isar.items.count(), 3);
    // 사진 파일은 현재 옷이 참조하는 2장뿐이다(기존·1차 복원 사진 정리).
    expect(target.imageFileNames(), hasLength(2));
    expect(await target.photoBytes(), await source.photoBytes());
  });

  test('복원 사진을 교체하면 이전 복원 파일이 지워진다(고아 방지)', () async {
    final target = device('target');
    await target.backup.restore(
      await target.backup.inspect(await makeBackup()),
    );
    final coat = target.isar.items.where().nameEqualTo('울 코트').findFirst()!;
    final restoredPath = coat.imagePath!;
    expect(restoredPath, contains('_r'));

    await target.items.update(
      coat.id,
      ItemPatch(
        name: coat.name,
        category: coat.category,
        careMethod: coat.careMethod,
        washCycle: coat.washCycle,
        careMode: coat.careMode,
        purposes: coat.purposes,
        newPhoto: File(p.join(tmp.path, 'b.jpg')),
      ),
    );
    expect(target.isar.items.get(coat.id)!.imagePath, 'items/${coat.id}.jpg');
    expect(
      File(await target.imageStore.absolutePath(restoredPath)).existsSync(),
      isFalse,
    );
  });

  test('사진 파일이 사라진 옷은 사진 없이 백업하고 누락 수를 알린다', () async {
    final coat = source.isar.items.where().nameEqualTo('울 코트').findFirst()!;
    File(await source.imageStore.absolutePath(coat.imagePath!)).deleteSync();

    final export = await source.backup.createBackup(
      Directory(p.join(tmp.path, 'out')),
    );
    expect(export.missingImageCount, 1);
    expect(export.counts.images, 1);

    final target = device('target');
    await target.backup.restore(await target.backup.inspect(export.file));
    expect(
      target.isar.items.where().nameEqualTo('울 코트').findFirst()!.imagePath,
      isNull,
    );
    expect(target.isar.items.count(), 3);
  });

  group('실패 경로는 기존 데이터를 바꾸지 않는다', () {
    late _Device target;
    late Map<String, Object?> before;
    late Map<int, List<int>> beforePhotos;
    late Set<String> beforeFiles;

    Future<void> prepareTarget({ImageStore Function(Directory)? store}) async {
      target = device('target', store: store);
      await target.items.create(
        NewItemDraft(
          name: '지켜야 할 옷',
          tempPhoto: File(p.join(tmp.path, 'b.jpg')),
        ),
      );
      await target.prefs.setAccent('sage');
      before = target.snapshot();
      beforePhotos = await target.photoBytes();
      beforeFiles = target.imageFileNames();
    }

    Future<void> expectUnchanged() async {
      expect(target.snapshot(), before);
      expect(await target.photoBytes(), beforePhotos);
      expect(target.imageFileNames(), beforeFiles);
    }

    File writeFile(String name, List<int> bytes) =>
        File(p.join(tmp.path, name))..writeAsBytesSync(bytes);

    List<int> zip(Map<String, List<int>> entries) {
      final archive = Archive();
      for (final MapEntry(:key, :value) in entries.entries) {
        archive.addFile(ArchiveFile.bytes(key, value));
      }
      return ZipEncoder().encode(archive);
    }

    List<int> manifestOf(Map<String, Object?> json) =>
        utf8.encode(jsonEncode(json));

    Future<Map<String, Object?>> sourceManifest() async {
      final file = await makeBackup();
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
      return jsonDecode(
            utf8.decode(archive.find(BackupFormat.manifestEntry)!.content),
          )
          as Map<String, Object?>;
    }

    test('zip이 아닌 파일', () async {
      await prepareTarget();
      final file = writeFile('junk.zip', utf8.encode('hello, not a zip'));
      await expectLater(
        target.backup.inspect(file),
        throwsA(isA<BackupFormatException>()),
      );
      await expectUnchanged();
    });

    test('잘린 백업 파일', () async {
      await prepareTarget();
      final bytes = (await makeBackup()).readAsBytesSync();
      final file = writeFile('cut.zip', bytes.sublist(0, bytes.length ~/ 2));
      await expectLater(
        target.backup.inspect(file),
        throwsA(isA<BackupFormatException>()),
      );
      await expectUnchanged();
    });

    test('backup.json이 없는 zip', () async {
      await prepareTarget();
      final file = writeFile(
        'other.zip',
        zip({'readme.txt': utf8.encode('x')}),
      );
      await expectLater(
        target.backup.inspect(file),
        throwsA(isA<BackupFormatException>()),
      );
      await expectUnchanged();
    });

    test('사진 엔트리 누락', () async {
      await prepareTarget();
      final manifest = await sourceManifest();
      final file = writeFile(
        'noimg.zip',
        zip({BackupFormat.manifestEntry: manifestOf(manifest)}),
      );
      await expectLater(
        target.backup.inspect(file),
        throwsA(isA<BackupFormatException>()),
      );
      await expectUnchanged();
    });

    test('사진 데이터 손상(CRC 불일치)', () async {
      await prepareTarget();
      final bytes = (await makeBackup()).readAsBytesSync();
      // 난수 사진은 압축되지 않으므로 원본 바이트 구간을 찾아 1바이트를 바꾼다.
      final marker = _photo(1).sublist(2000, 2032);
      final at = _indexOf(bytes, marker);
      expect(at, greaterThan(0));
      bytes[at + 10] ^= 0xFF;
      final file = writeFile('crc.zip', bytes);
      await expectLater(
        target.backup.inspect(file),
        throwsA(isA<BackupFormatException>()),
      );
      await expectUnchanged();
    });

    test('더 새로운 형식 버전은 거부', () async {
      await prepareTarget();
      final manifest = await sourceManifest()
        ..['formatVersion'] = BackupFormat.currentVersion + 1;
      final file = writeFile(
        'newer.zip',
        zip({BackupFormat.manifestEntry: manifestOf(manifest)}),
      );
      await expectLater(
        target.backup.inspect(file),
        throwsA(
          isA<BackupVersionException>().having((e) => e.isNewer, 'newer', true),
        ),
      );
      await expectUnchanged();
    });

    test('검증 후 파일이 손상되면 적용 단계에서 다시 거부한다', () async {
      await prepareTarget();
      final file = await makeBackup();
      final preview = await target.backup.inspect(file);
      file.writeAsBytesSync(utf8.encode('corrupted later'));
      await expectLater(
        target.backup.restore(preview),
        throwsA(isA<BackupFormatException>()),
      );
      await expectUnchanged();
    });

    test('공간 부족 시 staging 사진을 지우고 기존 데이터를 유지한다', () async {
      await prepareTarget(
        store: (dir) => _FullDiskImageStore(overrideRoot: dir, failFrom: 2),
      );
      final preview = await target.backup.inspect(await makeBackup());
      // 복원 첫 사진은 성공, 두 번째 사진에서 ENOSPC(등록 때의 copyTo는
      // writeBytes를 쓰지 않는다).
      await expectLater(
        target.backup.restore(preview),
        throwsA(isA<BackupStorageFullException>()),
      );
      await expectUnchanged();
    });
  });
}

int _indexOf(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
