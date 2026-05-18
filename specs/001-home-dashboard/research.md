# Research: 옷장이모 MVP 기술 결정

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 plan.md의 Technical Context에서 도출된 기술 선택 및 비명시 항목에 대한 결정·근거·대안 비교를 기록한다. 모든 "NEEDS CLARIFICATION"은 본 문서에서 해소되어야 한다.

---

## 1. 상태 관리: Riverpod 채택

- **Decision**: `flutter_riverpod` (StateNotifier 또는 Notifier 기반)을 사용한다.
- **Rationale**:
  - 컴파일 타임 안전성(테스트 시 override 용이)과 비동기 스트림(Isar 쿼리 watch) 통합이 가장 깔끔.
  - 단일 사용자 앱이므로 BLoC의 풍부한 이벤트 모델링까지는 과잉.
  - Riverpod의 `AsyncNotifier`는 Isar의 `IsarCollection.watchLazy()` 스트림과 1:1 매핑이 자연스럽다.
- **Alternatives**:
  - **BLoC**: 강력하지만 보일러플레이트 과다. 단일 사용자·로컬 DB 시나리오에서는 ROI 낮음.
  - **Provider**: Riverpod의 전신. 새 코드는 Riverpod 권장(공식 가이드).
  - **GetX**: 마법 같은 의존성 주입으로 헌법 II(일관성·정직성) 위반 가능. 기각.

## 2. 라우팅: go_router 채택

- **Decision**: `go_router`(공식 Flutter 팀 유지보수)를 단일 진입점 라우터로 사용.
- **Rationale**:
  - 선언적 + URL 기반으로 6 화면 + 상세 + 등록 모달 라우트가 직관적.
  - 딥링크가 v1엔 없지만 후속 spec(공유 옷 링크 등)에서 자연스럽게 확장 가능.
  - `Navigator 2.0` 직접 사용 대비 보일러플레이트 압도적으로 적음.
- **Alternatives**:
  - **AutoRoute**: 코드 생성 기반으로 강력하나 빌드 시간 증가. 6 화면 규모엔 과잉.
  - **Navigator 1.0 (push/pop)**: 가장 단순하지만 탭 전환 + 상세 스택 관리에서 누수 위험.

## 3. 로컬 DB: Isar 4.x 채택 (사용자 지정)

- **Decision**: 사용자가 지정한 `isar` 4.x 라인을 사용한다. (스키마 v1: `Item`, `WearEvent`, `UserPreferences` 컬렉션. `LaundryBasket`은 `Item.inLaundry: bool` 속성으로 표현.)
- **Rationale**:
  - mmap 기반 NoSQL로 수만 건 쿼리에서도 ms 단위 응답 → SC-004(100점 200ms) 무난.
  - `@collection` 데코레이터 + `isar_generator` 빌드로 타입 안전.
  - `watchLazy()` 스트림이 Riverpod와 결합 시 자동 재렌더 워크플로 단순.
  - 헌법 III(로컬 우선)와 부합: 외부 네트워크 호출 없음.
- **Alternatives 비교 (요약)**:
  - **drift (SQLite)**: 관계형 쿼리 강점이나 본 도메인은 옷·이벤트 두 집합 중심으로 NoSQL이 더 직관적.
  - **Hive**: 가볍지만 인덱스·복잡 쿼리 약함. 정렬·필터 다양한 본 spec 요구에 부적합.
  - **ObjectBox**: Isar와 유사하나 라이선스(상업적 사용 시 유료) 부담.
- **버전 주의**: Isar 4.x는 코어가 Rust로 재작성된 라인. iOS·Android 양 플랫폼에서 `isar_flutter_libs` 동적 라이브러리 자동 번들. macOS dev 빌드 시 `isar.dylib` 경로 환경 변수 셋업 필요(quickstart.md 참조).

## 4. 디자인 시스템 → Flutter 매핑

- **Decision**: `design.md` 토큰을 `lib/app/theme/tokens.dart`에 Dart 상수로 미러링하고, `app_theme.dart`에서 Material `ColorScheme.fromSeed` 대신 **명시적** `ColorScheme(...)`을 구성한다. 비-Material 토큰(`surface-container-low`, `surface-container-lowest` 등)은 `ThemeExtension<ClosetimoColors>` 서브클래스로 노출.
- **Rationale**:
  - `ColorScheme.fromSeed`는 Material 3 알고리즘으로 색을 생성 → "The Digital Atelier" 팔레트와 불일치 발생.
  - 토큰 매핑:
    - `primary` #47645e → `colorScheme.primary`
    - `on-primary` #dffef7 → `colorScheme.onPrimary`
    - `background` #fafaf5 → `colorScheme.surface`
    - `surface-container-low` #f3f4ee → ThemeExt
    - `surface-container-lowest` #ffffff → ThemeExt
    - `surface-container` #ecefe7 → ThemeExt
    - `secondary-container` #e3e2e2 → `colorScheme.secondaryContainer`
    - `tertiary` #576342 → `colorScheme.tertiary`
    - `error` #9f403d → `colorScheme.error`
    - `on-background` #2e342d → `colorScheme.onSurface`
  - 디바이더 금지(`No-Line`)는 `ThemeData.dividerTheme = DividerThemeData(color: Colors.transparent)`로 전역 차단 + 린트 규칙으로 `Divider`·`VerticalDivider` 사용 금지 권고.
- **Alternatives**:
  - **Material You(M3) 기본 토큰만 사용**: 디자인 시스템과 토큰 갭 발생 → 헌법 II 위반.

## 5. 타이포그래피 & 한글 폴백

- **Decision**:
  - 라틴 텍스트: **Manrope**(display·headline·body) + **Inter**(label-md, 메타데이터).
  - 한글: **Pretendard**(OFL 라이선스, Manrope/Inter와 X-height·기하학적 정렬이 좋음).
  - `TextTheme`에서 `fontFamilyFallback: ['Pretendard']` 지정.
- **Rationale**:
  - Manrope·Inter는 한글 글리프 부재 → 한국어 1차 UI(헌법 Product Constraint)와 충돌.
  - Pretendard는 디지털 한글 UI의 사실상 표준, 광범위한 무게 지원.
- **Alternatives**:
  - **Noto Sans KR**: 무난하나 Manrope와의 시각적 매칭에서 어색.
  - **Apple SD Gothic Neo / Pretendard Variable**: iOS 시스템 폰트는 라이선스 명확하지만 Android에서 폴백 격차 발생.

## 6. 이미지 입력 및 저장

- **Decision**:
  - **입력**: `image_picker` 패키지 (카메라 + 갤러리).
  - **저장**: 선택된 이미지를 `path_provider`로 얻은 앱 `documents/items/{itemId}.jpg`로 복사. Item 엔티티는 절대 경로 대신 **상대 경로**(`items/{itemId}.jpg`)를 저장(앱 sandbox 마이그레이션 안전).
  - **크기 조정**: 입력 시 긴 변 1600px로 다운스케일(`image_picker`의 `maxWidth`/`maxHeight` 사용).
- **Rationale**:
  - sandbox 내 사본은 사용자가 원본 사진을 갤러리에서 삭제해도 옷장 표시가 깨지지 않음.
  - 1600px 다운스케일로 평균 200-400KB 수준 → 1,000점 저장 시 0.4GB 정도 → 모바일 디바이스에서 수용 가능.
- **Alternatives**:
  - **원본 경로만 참조**: 사용자가 갤러리에서 사진 삭제 시 표시 깨짐.
  - **DB에 BLOB 저장**: Isar DB 파일이 비대해져 백업·동기화 비용 증가.

## 7. 폼 입력 & 검증

- **Decision**: 표준 `Form` + `TextFormField` 대신, 디자인 시스템에 맞춘 **커스텀 입력 위젯**(`field-input`, `field-label`)을 `core/widgets/`에 정의. 검증은 위젯 내부 `onChanged` 콜백 + Riverpod state.
- **Rationale**:
  - Material `InputDecorator`의 기본 언더라인·라벨 애니메이션이 design.md "No-Line" 규칙과 충돌.
  - 필수 항목(명칭·카테고리)만 검증 — 다른 필드는 빈 값 허용(FR-002, FR-003).

## 8. 토스트 / 비차단 알림

- **Decision**: Material `SnackBar` 직접 사용 대신, `core/widgets/toast.dart`에 `Overlay` 기반 커스텀 토스트를 구현. 2초 후 자동 dismiss, 좌측 체크 아이콘.
- **Rationale**:
  - `SnackBar`는 하단 nav bar(BotNav)와 시각적으로 겹쳐 디자인 의도(우아한 둥근 alert)와 부합하지 않음.
  - 디자인 패키지의 `.toast` 스타일과 1:1 매칭 가능.

## 9. 날짜·로케일 포맷

- **Decision**: `intl` 패키지, 기본 로케일 `ko_KR`. 표시 규칙:
  - "오늘" / "어제" / "N일 전" — 7일 이내
  - "M/d" — 7일 이상 30일 이내
  - "yyyy.MM.dd" — 30일 이상 또는 정확한 날짜가 필요한 곳(구매일, 마지막 세탁일 상세)
- **Rationale**:
  - 디자인 패키지의 시각적 톤(`10/14`, `2022.12.20` 혼용)과 부합.
  - `intl_ko` 데이터로 자동 로컬라이제이션.

## 10. 테스팅 전략

- **Decision**:
  - **단위(Unit)**: Isar `inspectorService` 없이 메모리 인스턴스로 repository 단위 테스트(`Isar.openSync(directory: '...', name: 'test-${random}')`).
  - **위젯(Widget)**: 디자인 시스템 공용 위젯에 골든 테스트(`goldenFileComparator`) 적용 — 헌법 II(디자인 일관성) 회귀 가드.
  - **통합(Integration)**: US1·US3·US4 핵심 흐름 각 1건씩 `integration_test`로 E2E.
- **Rationale**: Spec SC-003(100ms UI 갱신), SC-005(영속화 100%)은 통합 테스트로만 검증 가능. 골든은 디자인 회귀를 PR마다 자동 차단.

## 11. 빌드·코드 생성

- **Decision**:
  - `build.yaml`에서 `isar_generator`(@collection 스키마) + `freezed`(불변 폼 state) + `json_serializable`(`laundry_tips.json` 로드용) 통합.
  - 개발 워크플로: `dart run build_runner watch -d`로 핫 코드 생성 + Flutter hot-reload 병행.

## 12. 의존성 핀(주요)

| 패키지 | 버전 핀 | 비고 |
|---|---|---|
| flutter | 3.35.x (stable) | Dart 3.9.2 포함 (개발 환경 기준; plan.md 작성 시 3.27.x였으나 본 환경은 더 신규 안정 라인) |
| isar | ^3.1.0+1 | 4.x(Rust core)는 정식 release 전이라 안정 라인 3.x를 채택. data-model.md의 `@collection`/`@Index` API 호환. 후속 spec에서 4.x 마이그레이션 |
| isar_flutter_libs | ^3.1.0+1 | isar와 버전 동기화 |
| flutter_riverpod | ^2.6.1 | |
| go_router | ^14.6.2 | |
| image_picker | ^1.1.2 | |
| intl | ^0.20.2 | flutter_localizations(3.35 SDK)가 0.20.2를 핀하므로 0.19→0.20.2로 상향 |
| path_provider | ^2.1.5 | |
| freezed | ^2.5.2 | dev_dep. isar_generator 3.x의 analyzer ^5/6 호환을 위해 2.5.7→2.5.2로 하향 |
| build_runner | ^2.4.13 | dev_dep |

`pubspec.yaml`은 `flutter pub upgrade --major-versions` 시점에 일괄 재검토.

---

**Status**: 모든 Technical Context 항목 해소 완료. Phase 1으로 진행.
