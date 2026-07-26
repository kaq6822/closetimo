# Implementation Plan: 로컬 데이터 엔진 장기 호환성

**Branch**: `003-migrate-isar-spm` | **Date**: 2026-07-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-migrate-isar-spm/spec.md`

## Summary

Swift Package Manager를 정식 지원하는 Isar Plus 안정판으로 주 저장소를 전환한다. Isar 3 데이터 파일은 직접 호환을 가정하지 않고, SwiftPM을 지원하도록 프로젝트에 고정한 읽기 전용 legacy 브리지로 기존 데이터를 연 뒤 별도 이름의 새 데이터베이스에 단일 트랜잭션으로 복사한다. 성공 표식이 기록되기 전에는 새 저장소를 사용하지 않으며 원본 파일은 삭제하지 않는다.

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.6 stable

**Primary Dependencies**: `isar_plus 1.3.7`, `isar_plus_flutter_libs 1.3.7`, Flutter Riverpod 2.6, 프로젝트 내 legacy Isar 3.1 읽기 브리지

**Storage**: Isar 3.1 기존 로컬 파일(`closetimo.isar`, 읽기 전용 보존) → Isar Plus 새 로컬 파일(`closetimo_plus.isar`)

**Testing**: `flutter_test`, 실제 Isar native core를 사용하는 저장소·이전 통합 테스트, iOS Simulator 수동 회귀

**Target Platform**: iOS 13+, Android API 21+, 휴대폰 폼팩터

**Project Type**: Flutter 모바일 앱

**Performance Goals**: 대표 데이터 세트의 첫 이전과 저장소 초기화를 3초 이내 완료하고 이후 실행에는 이전 비용을 발생시키지 않는다.

**Constraints**: 완전 오프라인, 원본 데이터 불변, 서버·외부 분석 도구 금지, 사용자 흐름 및 화면 변경 금지, iOS SwiftPM 미지원 경고 0건

**Scale/Scope**: `Item`, `WearEvent`, `UserPreferences` 3개 기존 collection과 모든 repository 구현, iOS/Android native library 패키징

## Constitution Check

*GATE: Phase 0 조사 전 및 Phase 1 설계 후 재검토 완료.*

| 원칙 | 판정 | 근거 |
|------|------|------|
| I. 큐레이션 우선 사용자 흐름 | PASS | 사용자 입력 단계와 화면을 변경하지 않고 앱 시작 시 내부적으로 이전한다. |
| II. 디자인 시스템 일관성 | PASS | UI 변경이 없다. |
| III. 로컬 우선 데이터 소유권 | PASS | 이전은 디바이스 로컬 파일 사이에서만 수행하며 네트워크·서버를 사용하지 않는다. |
| IV. Spec 주도 변경 관리 | PASS | `spec.md`, `plan.md`, `tasks.md` 및 설계 산출물로 변경을 추적한다. |

설계 후 재검토에서도 네 원칙을 모두 통과한다. 외부 서비스나 추가 사용자 단계가 없고 legacy 원본을 보존하므로 복잡성 예외는 없다.

## Project Structure

### Documentation (this feature)

```text
specs/003-migrate-isar-spm/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── storage-migration.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
└── data/
│   ├── models/
│   │   ├── item.dart
│   │   ├── wear_event.dart
│   │   ├── user_preferences.dart
│   │   └── storage_metadata.dart
│   ├── migrations/
│   │   └── storage_migrator.dart
│   ├── providers/
│   │   └── isar_provider.dart
│   └── repositories/
│       └── isar_*.dart
packages/
├── closetimo_legacy_isar/
│   ├── lib/
│   │   ├── closetimo_legacy_isar.dart
│   │   └── src/models/
│   └── pubspec.yaml
└── isar_flutter_libs/
    ├── android/
    ├── ios/isar_flutter_libs/
    │   ├── Package.swift
    │   ├── Core/
    │   ├── Plugin/
    │   ├── isar.xcframework
    │   └── isar_legacy.xcframework
    ├── lib/
    ├── tool/
    │   └── build_darwin_xcframework.sh
    ├── LICENSE
    └── pubspec.yaml
test/
├── fixtures/
│   └── isar_v3/
├── unit/
│   └── storage_migrator_test.dart
└── feature/
    └── isar_*_repository_test.dart
```

**Structure Decision**: 기존 `features → data → core` 의존 방향을 유지한다. 앱의 새 Isar Plus 모델, migration, provider와 repository는 `lib/data`에 두고, 구형 Isar 타입과 생성 코드는 독립된 로컬 package에 격리한다. 구형 native binary plugin은 Apple SwiftPM manifest와 Android namespace를 포함한 프로젝트 고정 fork로 관리한다. Apple에서는 Isar 3 정적 archive를 공개 `_isar_*` C API만 노출하는 동적 XCFramework로 감싸 Isar Plus의 내부 MDBX/Rust 심볼과 격리한다.

## Complexity Tracking

해당 없음. 이중 엔진은 직접 호환되지 않는 기존 데이터의 무손실 이전을 위해 전환 릴리스에만 필요한 기반이며, 사용자 기능 계층에는 노출되지 않는다.
