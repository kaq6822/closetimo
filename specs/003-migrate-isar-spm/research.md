# Research: 로컬 데이터 엔진 장기 호환성

## 1. 장기 저장소 계열

**Decision**: 앱의 주 저장소를 `isar_plus`, `isar_plus_flutter_libs` 1.3.7로 전환한다.

**Rationale**:

- 기존 `isar_flutter_libs 3.1.0+1`은 Apple plugin에 podspec만 제공하고 Swift Package Manager manifest가 없다.
- Flutter 3.44부터 SwiftPM이 기본 의존성 관리 방식이며 미지원 plugin은 현재 CocoaPods로 fallback하지만 향후 오류로 전환된다.
- Isar Plus 1.2.7부터 iOS/macOS SwiftPM 지원을 안정 경로로 선언했고, 1.3.5~1.3.7에서 release symbol 보존과 native binary 이름 충돌을 보완했다.
- 1.3.7은 Dart 3.7+ 및 Flutter 3.24+를 요구하므로 현재 Dart 3.12.2 / Flutter 3.44.6 환경과 호환된다.

**Alternatives considered**:

- 프로젝트에서 SwiftPM 비활성화: 즉시 경고는 사라지지만 Flutter가 비활성화 지원 제거를 예고했으므로 장기안이 아니다.
- `isar_community 3.3.2`: 유지보수되는 3.x fork지만 `isar_community_flutter_libs` 배포본에도 `Package.swift`가 없어 현재 경고의 근본 해결이 아니다.
- 기존 Isar plugin만 영구 fork: 데이터 호환성은 가장 높지만 비활성 상태인 3.x Dart/generator 계열 전체의 장기 유지 문제를 남긴다.

**Sources**:

- https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
- https://pub.dev/packages/isar_flutter_libs/versions
- https://pub.dev/packages/isar_plus_flutter_libs/changelog

## 2. 기존 데이터 호환 전략

**Decision**: Isar 3 파일을 직접 새 엔진으로 열지 않고 구형 엔진과 새 엔진을 동시에 포함하는 전환 브리지로 명시적으로 복사한다.

**Rationale**:

- 새 계열은 Isar 4 API와 생성 schema를 기반으로 하며 Isar 3에서 직접 이전하는 공식 기능이 없다.
- Isar Plus 1.3.0부터 native symbol과 binary 이름을 `isar_plus_*`로 분리했으므로 구형 `isar_*` core와 한 앱에 함께 링크할 수 있다.
- 새 데이터베이스 이름을 `closetimo_plus`로 분리하면 구형 `closetimo.isar`를 읽는 동안 파일 충돌이 없다.
- legacy 모델은 별도 local Dart package로 격리하고 검증된 기존 생성 코드를 호환 자산으로 고정하여, 오래된 generator 의존성이 루트의 최신 analyzer/build_runner 해석에 참여하지 않게 한다.

**Alternatives considered**:

- 기존 파일을 새 엔진에서 직접 열기: 공식 호환 보장이 없고 실패 시 사용자 데이터 위험이 있다.
- JSON export를 전제: 기존 배포본이 사전에 export하지 않았으므로 업데이트 한 번으로 처리할 수 없다.
- 중간 릴리스 두 개 운영: 배포 순서를 건너뛰는 사용자에게 안전하지 않다.

**Source**:

- https://github.com/isar/isar/discussions/1456

## 3. 원자성과 재시도

**Decision**: 새 저장소의 모든 레코드와 `StorageMetadata` 완료 표식을 하나의 write transaction에서 기록한다.

**Rationale**:

- transaction 실패 또는 앱 종료 시 완료 표식이 남지 않아 다음 실행에서 안전하게 재시도할 수 있다.
- legacy 원본은 읽기 전용으로 열고 삭제하지 않는다.
- 새 저장소에 완료 표식이 있으면 legacy 엔진을 다시 열지 않아 정상 실행 비용이 증가하지 않는다.
- ID를 그대로 복사하여 `WearEvent.itemId` 관계를 보존한다.

**Alternatives considered**:

- collection별 transaction: 중간 종료 시 부분 데이터와 별도 복구 상태가 필요하다.
- 성공 후 legacy 파일 삭제: 롤백과 현장 진단 가능성을 잃는다.

## 4. legacy native plugin 배포

**Decision**: `isar_flutter_libs 3.1.0+1`의 iOS/Android binary와 Apache-2.0 license를 프로젝트 local package로 고정하고 Apple plugin에 SwiftPM manifest를 추가한다. Apple 원본 정적 archive는 공개 `_isar_*` C API만 export하는 `libisar_legacy.dylib` XCFramework로 변환한다.

**Rationale**:

- 전환 릴리스가 기존 파일을 읽으려면 구형 native core가 필요하다.
- hosted plugin을 그대로 참조하면 미지원 경고가 계속되므로 자체 SwiftPM manifest가 필요하다.
- remote binary URL 대신 검증된 원본 xcframework를 package에 포함하여 오프라인 빌드를 유지한다.
- 구형 정적 archive와 Isar Plus를 직접 함께 링크하면 MDBX/Rust 내부 심볼이 중복되므로, legacy core를 동적 library로 격리하고 export 목록을 제한한다.
- 원본·변환 binary의 SHA-256과 공개 심볼 범위를 자동화 테스트로 고정한다.
- Android plugin에는 명시적 namespace를 추가하여 루트 Gradle의 임시 namespace 주입을 제거한다.

**Alternatives considered**:

- 런타임에 binary 다운로드: 로컬 우선·오프라인 빌드 원칙에 맞지 않는다.
- 비공식 Git fork 직접 참조: 외부 저장소 가용성과 변경에 빌드가 종속된다.

## 5. 검증 전략

**Decision**: 실제 Isar 3 fixture를 생성해 migration 통합 테스트에 사용하고, 기존 repository 테스트와 iOS/Android 빌드 및 iOS Simulator 회귀를 모두 수행한다.

**Rationale**:

- mock 데이터만으로는 native 파일 형식과 binary 동시 로딩을 검증할 수 없다.
- fixture에는 모든 enum, nullable 필드, ID 관계와 설정 값을 포함한다.
- 빌드 로그에서 SwiftPM 미지원 경고가 없는지를 명시적으로 검사한다.

**Alternatives considered**:

- 단위 mock만 사용: 핵심 위험인 실제 구형 파일 읽기를 검증하지 못한다.
- 수동 테스트만 사용: 이후 의존성 업데이트의 회귀를 자동 탐지하지 못한다.
