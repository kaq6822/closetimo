// #40 — 사용자 실행형 백업·복원 계약.
// specs/004-backup-restore/contracts/backup-service.md

import 'dart:io';

import '../backup/backup_format.dart';

abstract interface class BackupRepository {
  /// 현재 옷장 규모(복원 확인 안내용).
  Future<BackupCounts> currentCounts();

  /// [outputDir]에 백업 zip을 만든다. 실패하면 만들던 파일을 지우고
  /// [BackupException]을 던진다. 앱 데이터는 바꾸지 않는다.
  Future<BackupExport> createBackup(Directory outputDir);

  /// 아카이브 전체를 검증하고 미리보기를 돌려준다. DB·파일을 바꾸지 않는다.
  Future<ValidatedBackup> inspect(File archive);

  /// 현재 옷장을 백업 내용으로 전체 교체한다(FR-005·FR-007). 실패하면 기존
  /// 데이터를 그대로 둔 채 [BackupException]을 던진다.
  Future<RestoreResult> restore(ValidatedBackup backup);
}
