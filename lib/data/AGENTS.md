# AGENTS.md — lib/data (데이터 레이어)

Isar 모델, repository 추상화·구현, Riverpod provider 배선을 담당하는 데이터 레이어다.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
data/
├── backup/            # 사용자 실행형 백업 형식·codec(#40, specs/004-backup-restore)
├── migrations/        # Isar 3 → Isar Plus 이전 + 저장소 버전 업그레이드(StorageMetadata.storageVersion)
├── models/            # Isar Plus @collection 모델 + *.g.dart
├── repositories/      # 추상 인터페이스(item_repository.dart) + Isar 구현(isar_item_repository.dart)
└── providers/         # Isar 인스턴스와 repository Riverpod 배선
```

## 이 레이어의 규칙

- **스키마의 단일 진실 원천은 [data-model.md](../../specs/001-home-dashboard/data-model.md)다.**
  모델 필드·인덱스 변경은 spec 문서 갱신과 함께 진행한다.
- **repository 인터페이스는 [contracts/repositories.md](../../specs/001-home-dashboard/contracts/repositories.md) 계약을 따른다.**
  인터페이스(`*_repository.dart`)와 Isar 구현(`isar_*_repository.dart`)을 항상 분리 유지한다.
  상위 레이어(features)는 인터페이스에만 의존한다.
- 모델 수정 후에는 반드시 코드 생성을 실행한다:
  `dart run build_runner build`
  `*.g.dart`는 생성 파일이므로 직접 수정 금지.
- 앱 모델과 repository는 Isar Plus 1.3.x API를 사용한다. 구형 Isar 3 타입은
  `packages/closetimo_legacy_isar` 밖으로 노출하지 않는다.
- 새 저장소 이름은 `closetimo_plus`로 고정하고, 이전 원본 `closetimo` 저장소는 삭제하거나
  직접 열어 쓰지 않는다. 이전 정책은 `specs/003-migrate-isar-spm/`을 따른다.
- repository 로직 변경 시 in-memory Isar 인스턴스를 사용한 테스트로 검증한다.
- enum은 ordinal로 저장되므로 값은 **끝에만 추가**하고, 새 필드는 클래스 **끝에** 선언한다.
  의미가 바뀌는 변경은 `StorageMetadata.currentStorageVersion`을 올리고 `storage_migrator.dart`에
  업그레이드 단계와 구 스키마 고정본 기반 테스트를 추가한다.
- 모델(`Item`·`WearEvent`·`UserPreferences`)에 필드를 추가하면 `backup/backup_codec.dart`의 명시 매핑과
  `BackupFormat.currentVersion`도 함께 갱신한다(가드 테스트 `test/unit/backup_codec_test.dart`).
- **watch 쿼리에 인덱스 조건(`where().xxxEqualTo/IsNotNull`)을 쓰지 않는다.** Isar Plus는 옷이 조건 밖으로
  나가는 수정(세탁 완료·보관·복원)을 방출하지 않아 목록이 낡는다(#48 실기기 회귀). 전체를 구독하고
  Dart에서 거른다. 전체 구독은 `SharedItemsWatcher`(공유 구독 1개)를 통해서만 한다(#53).
  새 watch 쿼리는 "조건 밖으로 나가는" 변경 테스트를 함께 둔다
  (`test/feature/laundry_basket_sync_test.dart`).
- 이 레이어는 UI(위젯, BuildContext)를 알지 못한다. Flutter widget import 금지 (`providers/` 제외).
