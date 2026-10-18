// #40 — BackupRepository의 Isar 구현.
// 형식: specs/004-backup-restore/data-model.md / 원자성: spec.md FR-007

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path/path.dart' as p;

import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../backup/backup_codec.dart';
import '../backup/backup_format.dart';
import '../models/item.dart';
import '../models/user_preferences.dart';
import '../models/wear_event.dart';
import 'backup_repository.dart';

class IsarBackupRepository implements BackupRepository {
  IsarBackupRepository({
    required Isar isar,
    required ImageStore imageStore,
    required Clock clock,
    Random? random,
  }) : _isar = isar,
       _imageStore = imageStore,
       _clock = clock,
       _random = random ?? Random.secure();

  final Isar _isar;
  final ImageStore _imageStore;
  final Clock _clock;
  final Random _random;

  @override
  Future<BackupCounts> currentCounts() async => _isar.read(
    (isar) => BackupCounts(
      items: isar.items.count(),
      wearEvents: isar.wearEvents.count(),
      images: isar.items.where().imagePathIsNotNull().count(),
    ),
  );

  // ── 백업 ──

  @override
  Future<BackupExport> createBackup(Directory outputDir) async {
    final createdAt = _clock.now();
    // 한 읽기 트랜잭션에서 스냅숏을 떠 옷·기록 사이의 일관성을 보장한다.
    final (items, events, prefs) = _isar.read(
      (isar) => (
        isar.items.where().findAll(),
        isar.wearEvents.where().findAll(),
        isar.userPreferences.get(UserPreferences.singletonId),
      ),
    );

    final imageFiles = <int, File>{};
    var missing = 0;
    for (final item in items) {
      final path = item.imagePath;
      if (path == null) continue;
      final file = File(await _imageStore.absolutePath(path));
      if (file.existsSync()) {
        imageFiles[item.id] = file;
      } else {
        missing++;
        debugPrint('Backup: image file missing for item ${item.id}');
      }
    }

    final payload = BackupPayload(
      createdAt: createdAt,
      items: items,
      imageRefs: {
        for (final id in imageFiles.keys) id: BackupFormat.imageRef(id),
      },
      wearEvents: events,
      preferences: prefs,
    );
    final manifest = utf8.encode(jsonEncode(BackupCodec.encode(payload)));

    final name =
        'closetimo-backup-${DateFormat('yyyyMMdd-HHmmss').format(createdAt)}.zip';
    final target = File(p.join(outputDir.path, name));
    final partial = File('${target.path}.part');
    try {
      outputDir.createSync(recursive: true);
      final encoder = ZipFileEncoder()..create(partial.path);
      try {
        encoder.addArchiveFile(
          ArchiveFile.bytes(BackupFormat.manifestEntry, manifest),
        );
        for (final MapEntry(key: id, value: file) in imageFiles.entries) {
          await encoder.addFile(file, BackupFormat.imageRef(id));
        }
      } finally {
        await encoder.close();
      }
      await partial.rename(target.path);
    } on FileSystemException catch (e) {
      _deleteQuietly(partial);
      debugPrint('Backup failed: $e');
      throw classifyFileSystemError(e);
    } catch (e) {
      _deleteQuietly(partial);
      debugPrint('Backup failed: $e');
      throw BackupIoException('$e');
    }

    return BackupExport(
      file: target,
      createdAt: createdAt,
      counts: BackupCounts(
        items: items.length,
        wearEvents: events.length,
        images: imageFiles.length,
      ),
      missingImageCount: missing,
    );
  }

  // ── 검증 ──

  @override
  Future<ValidatedBackup> inspect(File archive) async {
    return _withArchive(archive, (zip, payload) {
      // 사진 엔트리 존재·CRC까지 확인해야 확인 안내 뒤 적용 단계에서
      // 손상이 드러나지 않는다.
      for (final ref in payload.imageRefs.values) {
        _readVerified(zip, ref);
      }
      return ValidatedBackup(
        file: archive,
        formatVersion: payload.formatVersion,
        createdAt: payload.createdAt,
        counts: _countsOf(payload),
      );
    });
  }

  // ── 복원 ──

  @override
  Future<RestoreResult> restore(ValidatedBackup backup) async {
    // 1) 검증 + 2) 사진 staging. 파일이 확인 이후 바뀌었을 수 있으므로 다시 검증한다.
    final written = <String>[];
    final (payload, newPaths) = await _withArchiveAsync(backup.file, (
      zip,
      payload,
    ) async {
      final token = await _uniqueToken(payload.imageRefs.keys);
      final paths = <int, String>{};
      try {
        for (final MapEntry(key: id, value: ref) in payload.imageRefs.entries) {
          final bytes = _readVerified(zip, ref);
          final rel = await _imageStore.writeBytes(
            _restoredName(id, token),
            bytes,
          );
          written.add(rel);
          paths[id] = rel;
        }
      } on FileSystemException catch (e) {
        await _deleteAll(written);
        debugPrint('Restore staging failed: $e');
        throw classifyFileSystemError(e);
      } catch (_) {
        await _deleteAll(written);
        rethrow;
      }
      return (payload, paths);
    });

    // 3) 커밋: 단일 쓰기 트랜잭션으로 전체 교체. 실패하면 Isar가 롤백한다.
    final List<String> oldPaths;
    try {
      oldPaths = _isar.write((isar) {
        final previous = isar.items
            .where()
            .imagePathIsNotNull()
            .imagePathProperty()
            .findAll()
            .whereType<String>()
            .toList();
        isar.items.clear();
        isar.wearEvents.clear();
        isar.userPreferences.clear();
        for (final item in payload.items) {
          item.imagePath = newPaths[item.id];
        }
        isar.items.putAll(payload.items);
        isar.wearEvents.putAll(payload.wearEvents);
        final prefs = payload.preferences;
        if (prefs != null) {
          isar.userPreferences.put(prefs..id = UserPreferences.singletonId);
        }
        return previous;
      });
    } catch (e) {
      await _deleteAll(written);
      debugPrint('Restore commit failed: $e');
      throw BackupIoException('$e');
    }

    // 4) 정리: 이전 옷들의 사진을 best-effort로 지운다.
    final kept = written.toSet();
    for (final old in oldPaths) {
      if (!kept.contains(old)) await _imageStore.delete(old);
    }
    return RestoreResult(counts: _countsOf(payload));
  }

  // ── 내부 ──

  static BackupCounts _countsOf(BackupPayload payload) => BackupCounts(
    items: payload.items.length,
    wearEvents: payload.wearEvents.length,
    images: payload.imageRefs.length,
  );

  /// 아카이브를 열어 `backup.json`을 해석한 뒤 [body]를 실행하고 파일을 닫는다.
  T _withArchive<T>(File file, T Function(Archive, BackupPayload) body) {
    final input = _openInput(file);
    try {
      final zip = _decodeZip(input);
      return body(zip, _decodeManifest(zip));
    } finally {
      input.closeSync();
    }
  }

  Future<T> _withArchiveAsync<T>(
    File file,
    Future<T> Function(Archive, BackupPayload) body,
  ) async {
    final input = _openInput(file);
    try {
      final zip = _decodeZip(input);
      return await body(zip, _decodeManifest(zip));
    } finally {
      input.closeSync();
    }
  }

  static InputFileStream _openInput(File file) {
    try {
      return InputFileStream(file.path);
    } on FileSystemException catch (e) {
      throw classifyFileSystemError(e);
    }
  }

  static Archive _decodeZip(InputFileStream input) {
    try {
      return ZipDecoder().decodeStream(input);
    } catch (e) {
      debugPrint('Backup archive unreadable: $e');
      throw const BackupFormatException('not a valid zip archive');
    }
  }

  static BackupPayload _decodeManifest(Archive zip) {
    final bytes = _readVerified(zip, BackupFormat.manifestEntry);
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupFormatException('backup.json is not valid JSON');
    }
    return BackupCodec.decode(json);
  }

  /// 엔트리를 읽고 CRC32를 다시 계산해 손상을 감지한다.
  static List<int> _readVerified(Archive zip, String name) {
    final entry = zip.find(name);
    if (entry == null || !entry.isFile) {
      throw BackupFormatException('missing entry $name');
    }
    final Uint8List? bytes;
    try {
      bytes = entry.readBytes();
    } catch (_) {
      throw BackupFormatException('unreadable entry $name');
    }
    if (bytes == null || getCrc32(bytes) != entry.crc32) {
      throw BackupFormatException('corrupted entry $name');
    }
    return bytes;
  }

  static String _restoredName(int itemId, String token) =>
      '${itemId}_r$token.jpg';

  /// 기존 파일과 겹치지 않는 복원 토큰을 만든다(커밋 전 기존 사진 보호).
  Future<String> _uniqueToken(Iterable<int> itemIds) async {
    while (true) {
      final token = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
      var clash = false;
      for (final id in itemIds) {
        final abs = await _imageStore.absolutePath(
          p.join('items', _restoredName(id, token)),
        );
        if (File(abs).existsSync()) {
          clash = true;
          break;
        }
      }
      if (!clash) return token;
    }
  }

  Future<void> _deleteAll(List<String> relativePaths) async {
    for (final rel in relativePaths) {
      await _imageStore.delete(rel);
    }
  }

  static void _deleteQuietly(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // best-effort
    }
  }
}
