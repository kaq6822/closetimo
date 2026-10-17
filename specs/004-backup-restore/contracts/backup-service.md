# Contract: BackupRepository · BackupFileGateway (#40)

## 1. `BackupRepository` (데이터 레이어)

`lib/data/repositories/backup_repository.dart`(인터페이스) / `isar_backup_repository.dart`(Isar 구현).
UI는 인터페이스에만 의존한다. 형식은 [data-model.md](../data-model.md).

```dart
abstract interface class BackupRepository {
  /// 현재 옷장 규모(복원 확인 안내용).
  Future<BackupCounts> currentCounts();

  /// [outputDir]에 백업 zip을 만든다. 같은 이름이 있으면 덮어쓴다.
  /// 사진 파일이 없는 옷은 사진 없이 포함하고 missingImageCount에 센다.
  Future<BackupExport> createBackup(Directory outputDir);

  /// 아카이브 전체(JSON·참조·이미지 CRC)를 검증하고 미리보기를 돌려준다. DB·파일 무변경.
  Future<ValidatedBackup> inspect(File archive);

  /// FR-007 순서(검증 → 이미지 staging → 단일 트랜잭션 교체 → 이전 사진 정리)로 전체 교체한다.
  Future<RestoreResult> restore(ValidatedBackup backup);
}
```

### 결과 타입

| 타입 | 필드 |
|---|---|
| `BackupCounts` | `items`, `wearEvents`, `images` |
| `BackupExport` | `file`, `counts`, `missingImageCount`, `createdAt` |
| `ValidatedBackup` | `file`, `formatVersion`, `createdAt`, `counts` |
| `RestoreResult` | `counts` |

### 예외 (`sealed class BackupException implements Exception`)

| 예외 | 발생 | 기존 데이터 |
|---|---|---|
| `BackupFormatException(reason)` | zip 아님·잘림·`backup.json` 누락·JSON/필드/enum 오류·id 중복·참조 위반·이미지 누락/CRC 불일치·format 식별자 불일치 | 무변경 |
| `BackupVersionException(found, supported)` | `formatVersion > currentFormatVersion` 또는 1 미만 | 무변경 |
| `BackupStorageFullException` | 파일 쓰기 중 ENOSPC(errno 28, Android/iOS 공통) | 무변경(쓴 파일 정리) |
| `BackupIoException(message)` | 그 밖의 파일 시스템 오류 | 무변경(쓴 파일 정리) |

`createBackup` 실패 시에는 만들던 zip을 지운다. 쓰기 트랜잭션 실패는 Isar가 롤백하며 staging 사진을 지운 뒤
`BackupIoException`으로 감싸 던진다.

## 2. `BackupFileGateway` (features/settings — 플랫폼 경계)

`lib/features/settings/backup/backup_file_gateway.dart`. 위젯 테스트는 provider override로 가짜 구현을 쓴다.

```dart
abstract interface class BackupFileGateway {
  /// 백업 작업용 앱 임시 디렉터리(iOS NSTemporaryDirectory, Android cacheDir).
  Future<Directory> workDirectory();

  /// OS 공유 시트로 [file]을 내보낸다. 사용자가 닫으면 false.
  Future<bool> share(File file);

  /// OS 문서 선택기로 파일 하나를 고르고 [workDirectory] 안 사본을 돌려준다. 취소하면 null.
  Future<File?> pickBackupFile();
}
```

구현(`PlatformBackupFileGateway`): 공유는 `share_plus`, 선택은 `file_selector`의 `openFile()`(형식 필터 없음 — iOS `public.data`,
Android `*/*`. Drive·메일 앱이 zip에 붙이는 MIME/UTI가 제각각이라 내용 검증으로 거른다). 두 패키지 모두 네트워크 호출이 없고 OS UI만 띄운다(헌법 III).
