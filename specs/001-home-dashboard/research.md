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

## 3. 로컬 DB: Isar 3.x 채택 (안정 라인)

- **Decision**: 안정 라인인 `isar` 3.x(`^3.1.0+1`)를 사용한다. 4.x(Rust core)는 정식 release 전이라 v1에서는 채택하지 않으며, 후속 spec에서 마이그레이션 여부를 검토한다. 스키마 v1: `Item`, `WearEvent`, `UserPreferences` 컬렉션. `LaundryBasket`은 `Item.inLaundry: bool` 속성으로 표현.
- **Rationale**:
  - mmap 기반 NoSQL로 수만 건 쿼리에서도 ms 단위 응답 → SC-004(100점 200ms) 무난.
  - `@collection` 데코레이터 + `isar_generator` 빌드로 타입 안전.
  - `watchLazy()` 스트림이 Riverpod와 결합 시 자동 재렌더 워크플로 단순.
  - 헌법 III(로컬 우선)와 부합: 외부 네트워크 호출 없음.
- **Alternatives 비교 (요약)**:
  - **drift (SQLite)**: 관계형 쿼리 강점이나 본 도메인은 옷·이벤트 두 집합 중심으로 NoSQL이 더 직관적.
  - **Hive**: 가볍지만 인덱스·복잡 쿼리 약함. 정렬·필터 다양한 본 spec 요구에 부적합.
  - **ObjectBox**: Isar와 유사하나 라이선스(상업적 사용 시 유료) 부담.
- **버전 주의**: Isar 3.x는 C++ core 기반 안정 라인. iOS·Android 양 플랫폼에서 `isar_flutter_libs` 동적 라이브러리 자동 번들. macOS dev 빌드 시 `isar.dylib` 경로 환경 변수 셋업 필요(quickstart.md 참조). Android는 AGP 8+ 빌드에서 `isar_flutter_libs` 3.x에 namespace 주입이 필요(commit `b4bbb0b` 참조).

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

## 13. 착용 기록 메모 입력 UX (Clarification 2026-05-23)

- **Decision**:
  - **입력 진입점**: 옷 상세의 "착용 기록하기" 버튼 탭 시 가벼운 바텀시트가 떠 단일행 텍스트필드를 노출한다. 시트의 "기록" 버튼이 `EventRepository.recordWear(itemId, note: ...)`를 호출한다. 입력 없이 "기록"을 누르면 `note=null`로 저장되어 현행 1탭 흐름과 동일하게 동작한다.
  - **적용 범위**: `kind=wear` 이벤트에만 사용자 입력 메모를 받는다. 세탁 완료(`completeWashFor`)는 다중 선택 일괄 흐름을 유지하며 `kind=wash` 이벤트의 `note`는 항상 `null`이다.
  - **제약**: 단일행, 최대 80자, 빈 입력은 `null`로 정규화. UI에서 글자 수 카운터로 한도 강조, Repository에서도 `ArgumentError` 가드.
  - **사후 변경**: 타임라인 wear 항목 long-press → "메모 편집"(`updateEventNote`) 또는 "기록 삭제"(`deleteWearEvent`). 메모 편집은 동일 80자 제약. 삭제는 단일 트랜잭션으로 `wearSinceWash`/`totalWears`/`lastWornAt`/`status`(dirty→clean 자동 복귀) 사이드이펙트를 모두 역적용한다(`inLaundry`는 변경하지 않음).
- **Rationale**:
  - 바텀시트 1단계는 평소 1탭 흐름을 보존하면서 선택적 메모 입력을 가능하게 해 헌법 I(흐름 단순화)에 부합. 인라인 텍스트필드는 상세 화면 정보 밀도를 늘리고, 즉시 기록 후 사후 편집만 두는 방식은 "기록 순간"의 컨텍스트(왜 입었는지)를 놓치게 한다.
  - 80자 단일행은 짧은 코멘트("오피스 미팅, 따뜻함")에 충분하면서 "메모"가 "일기"로 변질되는 것을 방지. 헌법 I과 양립.
  - 삭제 시 사이드이펙트 역적용은 헌법 III(로컬 우선 데이터 소유권)와 부합. "사용자가 잘못 기록한 데이터를 자신의 의도대로 되돌릴 수 있어야 한다"는 원칙. dirty→clean 자동 복귀가 없으면 "삭제했는데 카운터/상태가 어긋난다"는 직관 위반이 발생.
- **Alternatives 비교**:
  - **인라인 메모 텍스트필드(상세 화면 본문)**: 상세 화면이 이미 사진·통계·타임라인으로 정보 밀도가 높아 매번 입력란이 떠 있으면 노이즈. 시각적 위계 약화.
  - **사후 메모 전용(기록 시점은 메모 없음)**: 기록 직후 사용자가 다시 화면으로 진입해야 하므로 흐름 단계가 늘어남.
  - **MVP 제외(스키마 자리만 유지)**: 현행과 동일. 사용자가 명시적으로 "메모 입력 UI가 누락된 것이 의도된 것인가" 질문한 시점에서 갭이 확인됨.
  - **wash 이벤트에도 메모 입력**: 세탁 완료는 다중 선택 일괄 흐름이라 메모-개체 매핑이 부자연스럽고 UX 복잡도가 커진다. 가치 대비 비용 부적합.
  - **삭제 시 이벤트만 제거, Item 카운터/상태는 보존**: 역사 정정용으로는 일관성이 있으나 단일 사용자 로컬 앱에서 "삭제했는데 옷 상태가 안 바뀐다"는 직관 위반이 더 큰 비용.

## 14. v1 후속 spec 후보 (메모 도입 따라 따라온 미해결 항목)

- `kind = wash` 이벤트에 사용자 메모를 받을지 여부 — 현재 결정은 "받지 않음". 사용자 피드백 기반 별도 spec.
- 타임라인 항목의 메모 편집·삭제 UI 트리거 — long-press 표준 + 명시적 액션 아이콘 병행 여부 결정.
- 메모 검색 — 옷장 검색(FR-006, 현재는 이름·브랜드 매칭)을 메모 본문까지 확장할지 여부.

---

**Status**: Clarification 2026-05-23 반영 완료. Phase 1 산출물(contracts/repositories.md, data-model.md)에 적용됨.
