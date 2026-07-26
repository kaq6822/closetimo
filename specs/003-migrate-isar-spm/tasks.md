# Tasks: 로컬 데이터 엔진 장기 호환성

**Input**: Design documents from `/specs/003-migrate-isar-spm/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/storage-migration.md, quickstart.md

**Tests**: FR-012와 프로젝트 테스트 규칙에 따라 실제 native 저장소를 사용하는 이전·repository 회귀 테스트를 포함한다.

**Organization**: 작업은 사용자 스토리별로 묶고, 데이터 보존을 먼저 완성한 뒤 기능 회귀와 플랫폼 빌드를 검증한다.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: SwiftPM 대응 legacy binary와 새 엔진 의존성 기반 준비

- [x] T001 Apache-2.0 원본과 iOS/Android binary를 포함한 local `isar_flutter_libs` 3.1.0+1 fork를 `packages/isar_flutter_libs/`에 가져오고 `packages/isar_flutter_libs/pubspec.yaml`의 SDK 범위를 현재 Dart와 호환되게 정리한다.
- [x] T002 Apple local binary target과 plugin target을 정의하는 `packages/isar_flutter_libs/ios/isar_flutter_libs/Package.swift`, source bridge 및 내부 native 심볼을 격리하는 `packages/isar_flutter_libs/tool/build_darwin_xcframework.sh`를 추가한다.
- [x] T003 Android namespace를 `packages/isar_flutter_libs/android/build.gradle`에 명시하고 루트의 임시 namespace 주입을 `android/build.gradle.kts`에서 제거한다.
- [x] T004 legacy 모델을 격리할 `packages/closetimo_legacy_isar/pubspec.yaml`과 public snapshot API `packages/closetimo_legacy_isar/lib/closetimo_legacy_isar.dart`를 구성한다.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 구형 읽기 모델과 새 저장소 schema를 함께 빌드할 수 있는 기반 완성

**⚠️ CRITICAL**: 이 단계 완료 전에는 이전 로직이나 repository 전환을 시작하지 않는다.

- [x] T005 legacy `Item`, `WearEvent`, `UserPreferences`와 enum을 `packages/closetimo_legacy_isar/lib/src/models/`에 구현하고 검증된 Isar 3 생성 코드를 호환 자산으로 고정한다.
- [x] T006 legacy 파일 탐지·읽기·테스트 fixture 생성을 `packages/closetimo_legacy_isar/lib/src/legacy_store.dart`에 구현한다.
- [x] T007 루트 의존성을 `isar_plus 1.3.7`, `isar_plus_flutter_libs 1.3.7`, local legacy packages로 교체하고 `pubspec.yaml` 및 `pubspec.lock`에서 구형 generator를 제거한다.
- [x] T008 앱 모델 import와 schema를 Isar Plus 형식으로 전환하고 `lib/data/models/item.dart`, `wear_event.dart`, `user_preferences.dart`의 생성 코드를 다시 만든다.
- [x] T009 [P] 이전 완료 표식 모델과 검증 규칙을 `lib/data/models/storage_metadata.dart` 및 생성 코드에 추가한다.

**Checkpoint**: 두 native core와 두 schema 계열이 충돌 없이 컴파일된다.

---

## Phase 3: User Story 1 - 기존 옷장 데이터 보존 (Priority: P1) 🎯 MVP

**Goal**: Isar 3 데이터를 원본 훼손 없이 새 저장소로 한 번만 이전한다.

**Independent Test**: 실제 구형 저장소 파일을 만든 뒤 이전을 두 번 호출하고 의류·이벤트·설정 값과 ID, 관계 및 레코드 수가 동일한지 확인한다.

### Tests for User Story 1

- [x] T010 [US1] 실제 Isar 3 fixture의 전체 필드·enum·nullable 값·관계를 정의하고 실패/재시도 시나리오를 포함한 `test/unit/storage_migrator_test.dart`를 먼저 작성해 실패를 확인한다.

### Implementation for User Story 1

- [x] T011 [US1] `contracts/storage-migration.md` 계약에 맞는 `MigrationResult`와 `StorageMigrator`를 `lib/data/migrations/storage_migrator.dart`에 구현한다.
- [x] T012 [US1] 새 `closetimo_plus` 저장소를 열고 이전 성공 후에만 제공하도록 `lib/data/providers/isar_provider.dart`를 전환하며 영문 진단 로그와 close 처리를 추가하고 기존 `lib/core/persistence/isar_provider.dart`를 제거한다.
- [x] T013 [US1] `test/unit/storage_migrator_test.dart`에서 원자성, 멱등성, ID·설정·이벤트 관계 보존 및 fresh 설치를 모두 통과시킨다.

**Checkpoint**: 이전 로직만 독립 실행해 기존 데이터 100% 보존과 두 번째 호출 no-op을 증명한다.

---

## Phase 4: User Story 2 - 기존 앱 기능의 동일한 동작 (Priority: P2)

**Goal**: 새 저장소에서 모든 repository와 사용자 흐름이 기존 규칙대로 동작한다.

**Independent Test**: 빈 저장소에서 등록·검색·정렬·착용·세탁·수정·삭제와 설정 영속성을 자동화 테스트로 수행한다.

### Tests for User Story 2

- [x] T014 [P] [US2] repository 회귀 테스트의 native 초기화와 transaction 기대값을 Isar Plus에 맞게 `test/feature/isar_item_repository_test.dart`에서 갱신한다.
- [x] T015 [P] [US2] 신규 저장소의 착용·세탁·설정 영속성 회귀를 `test/feature/storage_repository_regression_test.dart`에 추가한다.

### Implementation for User Story 2

- [x] T016 [US2] 동기 transaction과 새 collection API를 사용하도록 `lib/data/repositories/isar_item_repository.dart`를 전환한다.
- [x] T017 [US2] `lib/data/repositories/isar_event_repository.dart`, `isar_laundry_repository.dart`, `isar_preferences_repository.dart`를 새 API로 전환하고 기존 파생 상태 계산을 보존한다.
- [x] T018 [US2] 전체 feature·unit 테스트를 실행해 등록, 필터·정렬, 착용, 세탁, 수정·삭제 및 설정 흐름을 통과시킨다.

**Checkpoint**: User Story 1과 2가 함께 동작하며 UI 계층 변경 없이 전체 테스트가 통과한다.

---

## Phase 5: User Story 3 - 지속 가능한 Apple 플랫폼 빌드 (Priority: P3)

**Goal**: SwiftPM 비활성화 없이 iOS와 Android 빌드가 지원 경로로 성공한다.

**Independent Test**: 깨끗한 의존성 해석 후 iOS·Android debug 빌드를 실행하고 SwiftPM 미지원 경고와 legacy Android namespace 우회가 없음을 확인한다.

### Tests for User Story 3

- [x] T019 [P] [US3] local legacy plugin의 SwiftPM manifest·binary checksum·필수 source 구조를 검사하는 `test/unit/native_plugin_manifest_test.dart`를 추가한다.

### Implementation for User Story 3

- [x] T020 [US3] `flutter build ios --no-codesign --debug`를 실행하고 미지원 SwiftPM 경고 0건과 `Runner.app` 생성을 확인한다.
- [x] T021 [US3] `flutter build apk --debug`를 실행하고 API 24+ debug APK 생성 및 namespace 오류 부재를 확인한다.
- [x] T022 [US3] 실제 iOS Simulator에서 legacy 데이터가 있는 업데이트 설치와 신규 설치의 핵심 흐름을 `specs/003-migrate-isar-spm/quickstart.md`에 따라 검증한다.

**Checkpoint**: 모든 사용자 스토리와 두 모바일 플랫폼 빌드가 독립적으로 검증된다.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 문서·정적 검증·장기 유지 정보 정리

- [x] T023 [P] `specs/001-home-dashboard/research.md`, `quickstart.md`와 루트 `AGENTS.md`의 Isar 버전·명령 설명을 새 저장소 및 legacy 브리지 정책과 맞춘다.
- [x] T024 `dart run tool/check_design_tokens.dart`, `flutter analyze`, `flutter test`를 실행하고 경고·오류·실패가 0건인지 확인한다.
- [x] T025 `specs/003-migrate-isar-spm/tasks.md`의 모든 완료 작업을 `[x]`로 표시하고 quickstart 결과와 남은 legacy 제거 조건을 문서화한다.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 즉시 시작 가능
- **Foundational (Phase 2)**: Setup 완료 후 진행하며 모든 사용자 스토리를 차단
- **US1 (Phase 3)**: Foundational 완료 후 진행
- **US2 (Phase 4)**: 새 저장소가 준비되는 US1 완료 후 진행
- **US3 (Phase 5)**: US1·US2 완료 후 실제 빌드와 업데이트 검증
- **Polish (Phase 6)**: 모든 사용자 스토리 완료 후 진행

### User Story Dependencies

- **US1 (P1)**: Foundational 외 추가 의존성 없음
- **US2 (P2)**: US1이 제공하는 새 저장소와 provider에 의존
- **US3 (P3)**: US1·US2의 최종 dependency graph와 실행 가능한 앱에 의존

### Within Each User Story

- 테스트를 먼저 작성하고 실패를 확인한다.
- 모델과 provider 이후 repository를 전환한다.
- 자동화 테스트 통과 후 플랫폼 빌드와 Simulator 검증을 수행한다.

### Parallel Opportunities

- T009는 legacy 기반 작업 완료 후 다른 새 모델 작업과 병렬 가능하다.
- T014와 T015는 서로 다른 테스트 파일에서 병렬 작성 가능하다.
- T019는 repository 구현과 파일이 겹치지 않아 US2 마무리와 병렬 준비 가능하다.
- T023은 빌드 검증과 파일이 겹치지 않아 병렬 수행 가능하다.

---

## Parallel Example: User Story 2

```text
Task: "test/feature/isar_item_repository_test.dart를 Isar Plus에 맞게 갱신"
Task: "test/feature/storage_repository_regression_test.dart에 착용·세탁·설정 회귀 추가"
```

---

## Implementation Strategy

### MVP First

1. local legacy plugin과 Isar Plus 의존성을 함께 구성한다.
2. 실제 legacy fixture를 읽는 이전 테스트를 작성한다.
3. US1의 원자적 이전과 멱등성을 완성한다.
4. 기존 원본과 새 저장소의 값을 비교해 데이터 보존을 확정한다.

### Incremental Delivery

1. Setup + Foundational → 두 엔진 공존 컴파일
2. US1 → 기존 사용자 데이터 보존
3. US2 → 전체 앱 기능 회귀 통과
4. US3 → SwiftPM 및 Android 정식 빌드 경로 검증
5. Polish → 문서와 장기 legacy 제거 조건 확정

## Notes

- legacy 파일과 binary는 전환 릴리스에서 삭제하지 않는다.
- legacy package는 읽기 전용 production API와 테스트 fixture 생성 API만 노출한다.
- 생성 파일은 원본 모델 수정 후 build_runner로만 갱신한다.
- 기존 dirty worktree의 feature 외 변경은 수정하거나 커밋하지 않는다.
