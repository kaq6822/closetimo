# Implementation Plan: 사용자 실행형 백업·복원

**Branch**: `feat/issues-batch-20261016` (#40) | **Date**: 2026-10-17 | **Spec**: [spec.md](./spec.md)

## Summary

설정 화면의 '데이터 백업'(준비 중) 행을 실제 동작으로 바꾸고 '백업에서 복원' 행을 추가한다. 데이터 레이어에
`BackupRepository`를 두어 Isar 전체(옷·기록·설정)와 sandbox 사진을 zip 하나로 내보내고, 검증 후 단일 트랜잭션으로
전체 교체 복원한다. 파일 저장·선택은 OS 공유 시트·문서 선택기에 맡긴다.

## Technical Context

**신규 의존성** (모두 순수 로컬, 네트워크 호출 없음 — 헌법 III 준수):

| 패키지 | 용도 | 근거 |
|---|---|---|
| `archive` ^4.5.2 | zip 생성·해제 | 순수 Dart. 네이티브 코드·권한 없음. 파일 스트림으로 써서 사진이 많아도 메모리에 전체 적재하지 않는다 |
| `share_plus` ^13.3.1 | OS 공유 시트(iOS `UIActivityViewController`, Android `ACTION_SEND`) | 사용자가 저장 위치(파일 앱·iCloud Drive·Google Drive)를 직접 고른다. SwiftPM 지원(`ios/share_plus/Package.swift`) |
| `file_selector` ^1.1.0 | OS 문서 선택기(iOS `UIDocumentPickerViewController`, Android SAF `ACTION_OPEN_DOCUMENT`) | Flutter 팀 1st-party. 권한 없이 사용자 선택 파일만 읽는다. iOS 13 최소 버전·SwiftPM 지원. (`file_picker` 13은 iOS 14 이상을 요구해 iOS 13+ 지원 범위와 맞지 않아 제외) |

`url_launcher`는 백업·복원에서 쓰지 않는다. 설정의 개인정보처리방침 링크(#56)를 위해 직접 의존성으로 추가했으며 근거는 [001 research.md](../001-home-dashboard/research.md)의 의존성 표를 따른다.

**플랫폼 설정**:

- iOS: 추가 Info.plist 키 없음. 문서 선택기·공유 시트는 권한 프롬프트가 없다. (사진 보관함 접근은 기존
  image_picker 설정을 그대로 쓴다.)
- Android: 추가 권한 없음. `share_plus`는 자체 `FileProvider`를 manifest merge로 등록하고, `file_selector_android`는
  권한을 선언하지 않는다. `READ/WRITE_EXTERNAL_STORAGE`를 요청하지 않는다.

## 구조

```text
lib/data/backup/backup_format.dart        # 상수·결과 타입·예외
lib/data/backup/backup_codec.dart         # Item/WearEvent/UserPreferences ↔ JSON 명시 매핑(단일 위치)
lib/data/repositories/backup_repository.dart
lib/data/repositories/isar_backup_repository.dart
lib/core/persistence/image_store.dart     # writeBytes 추가
lib/features/settings/backup/backup_file_gateway.dart
lib/features/settings/backup/backup_flow.dart   # 진행 표시·확인 안내·결과 토스트
```

## 테스트

- `test/unit/backup_codec_test.dart`: 왕복, 필드 목록 가드, 손상 JSON·enum·버전 케이스.
- `test/feature/backup_restore_repository_test.dart`: 실제 Isar(임시 디렉터리)로 백업 → 빈 DB 복원, 손상·버전·
  공간 부족·중복 복원·롤백.
- `test/feature/settings_backup_flow_test.dart`: 설정 행 chevron, 취소·확인·오류 안내.
- `integration_test/backup_restore_test.dart`: 실기기에서 백업 → 데이터 변경 → 복원 검증(lead가 실행).
