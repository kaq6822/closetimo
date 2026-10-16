// #40 — 백업 파일의 OS 경계(공유 시트·문서 선택기).
// 앱은 클라우드 API를 직접 호출하지 않는다. iCloud Drive·Google Drive 저장/선택은
// 사용자가 OS UI에서 고른다(헌법 III, specs/004-backup-restore/spec.md FR-009).

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class BackupFileGateway {
  /// 백업 작업용 앱 임시 디렉터리(iOS NSTemporaryDirectory, Android cacheDir).
  Future<Directory> workDirectory();

  /// OS 공유 시트로 [file]을 내보낸다. 사용자가 시트를 닫으면 false.
  Future<bool> share(File file);

  /// OS 문서 선택기로 파일 하나를 고르고 [workDirectory] 안 사본을 돌려준다.
  /// 취소하면 null.
  Future<File?> pickBackupFile();
}

class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  @override
  Future<Directory> workDirectory() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, 'backup'));
    // 이전 작업의 남은 파일(공유를 마친 백업, 복원용 사본)을 정리한다.
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<bool> share(File file) async {
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: '옷장이모 백업'),
    );
    // Android 일부 런처는 결과를 알려주지 않는다(unavailable) — 내보냄으로 본다.
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Future<File?> pickBackupFile() async {
    // 형식 필터 없이(iOS public.data, Android */*) 모든 파일을 보이고 내용
    // 검증으로 걸러낸다. Drive·메일 앱이 zip MIME/UTI를 제각각 붙이기 때문이다.
    final picked = await openFile();
    if (picked == null) return null;
    // 선택기가 준 파일은 임시 사본이거나 content URI일 수 있으므로 항상 앱
    // 임시 영역으로 복사해 읽는다.
    final dir = await workDirectory();
    final copy = File(p.join(dir.path, 'restore-source.zip'));
    final sink = copy.openWrite();
    try {
      await sink.addStream(picked.openRead());
    } finally {
      await sink.close();
    }
    return copy;
  }
}

final backupFileGatewayProvider = Provider<BackupFileGateway>(
  (ref) => const PlatformBackupFileGateway(),
);
