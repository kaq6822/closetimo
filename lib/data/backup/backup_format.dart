// #40 — 백업 파일 형식 상수·결과 타입·예외.
// 형식 정의: specs/004-backup-restore/data-model.md

import 'dart:io';

/// 백업 아카이브 형식 상수.
abstract final class BackupFormat {
  /// `backup.json`의 `format` 값. 다르면 옷장이모 백업이 아니다.
  static const String id = 'closetimo-backup';

  /// 앱이 쓰고 읽을 수 있는 최대 형식 버전(data-model.md §4).
  static const int currentVersion = 1;

  /// 메타·레코드를 담은 JSON 엔트리 이름.
  static const String manifestEntry = 'backup.json';

  /// 사진 엔트리 디렉터리(아카이브 내부 상대 참조 접두).
  static const String imageDir = 'images/';

  /// 옷 [itemId]의 아카이브 내부 사진 참조.
  static String imageRef(int itemId) => '$imageDir$itemId.jpg';
}

/// 레코드 개수 요약.
class BackupCounts {
  const BackupCounts({
    required this.items,
    required this.wearEvents,
    required this.images,
  });

  final int items;
  final int wearEvents;
  final int images;
}

/// 백업 생성 결과.
class BackupExport {
  const BackupExport({
    required this.file,
    required this.createdAt,
    required this.counts,
    required this.missingImageCount,
  });

  final File file;
  final DateTime createdAt;
  final BackupCounts counts;

  /// 사진 경로는 있으나 파일이 없어 사진 없이 포함한 옷 수.
  final int missingImageCount;
}

/// 검증을 통과한 백업. 복원 확인 안내와 적용에 쓴다.
class ValidatedBackup {
  const ValidatedBackup({
    required this.file,
    required this.formatVersion,
    required this.createdAt,
    required this.counts,
  });

  final File file;
  final int formatVersion;
  final DateTime createdAt;
  final BackupCounts counts;
}

/// 복원 결과.
class RestoreResult {
  const RestoreResult({required this.counts});

  final BackupCounts counts;
}

/// 백업·복원 실패. 모든 하위 예외는 기존 데이터를 바꾸지 않은 상태에서 던진다.
sealed class BackupException implements Exception {
  const BackupException();
}

/// 아카이브 구조·JSON·필드·참조·이미지 무결성 오류.
class BackupFormatException extends BackupException {
  const BackupFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'BackupFormatException: $reason';
}

/// 지원하지 않는 형식 버전(앱보다 새로운 백업 등).
class BackupVersionException extends BackupException {
  const BackupVersionException({required this.found, required this.supported});

  final int found;
  final int supported;

  bool get isNewer => found > supported;

  @override
  String toString() =>
      'BackupVersionException: found $found, supported up to $supported';
}

/// 기기 저장 공간 부족(ENOSPC).
class BackupStorageFullException extends BackupException {
  const BackupStorageFullException();

  @override
  String toString() => 'BackupStorageFullException: no space left on device';
}

/// 그 밖의 파일·저장소 오류.
class BackupIoException extends BackupException {
  const BackupIoException(this.message);

  final String message;

  @override
  String toString() => 'BackupIoException: $message';
}

/// iOS·Android(POSIX) 공통 ENOSPC errno.
const int _enospc = 28;

/// 파일 시스템 오류를 백업 예외로 분류한다.
BackupException classifyFileSystemError(FileSystemException error) {
  if (error.osError?.errorCode == _enospc) {
    return const BackupStorageFullException();
  }
  return BackupIoException(error.toString());
}
