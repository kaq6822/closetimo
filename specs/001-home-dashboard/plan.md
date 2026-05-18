# Implementation Plan: 옷장이모 MVP — 옷장 관리 + 세탁 워크플로

**Branch**: `001-home-dashboard` | **Date**: 2026-05-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-home-dashboard/spec.md`

## Summary

옷장이모 MVP를 Flutter(Dart) 단일 코드베이스로 iOS·Android 양 플랫폼에 구현한다. 디자인 패키지의 React 프로토타입을 시각·인터랙션의 단일 진실 원천(source of truth)으로 사용하되, 모든 UI는 `.specify/memory/design.md`("The Digital Atelier") 토큰으로 정의된 Flutter `ThemeData`와 위젯 시스템을 통해 표현한다. 로컬 데이터는 Isar(NoSQL 임베디드 DB)에 저장하여 헌법 III(로컬 우선 데이터 소유권)와 FR-022/FR-025(앱 재시작 영속화, 오프라인 동작)를 모두 만족시킨다. 상태 관리는 Riverpod, 라우팅은 go_router, 이미지는 image_picker + 앱 sandbox 파일 시스템을 사용한다.

## Technical Context

**Language/Version**: Dart 3.5+ / Flutter 3.27 (stable)

**Primary Dependencies**:
- `flutter` (UI 프레임워크)
- `isar` + `isar_flutter_libs` + `isar_generator` (로컬 NoSQL DB)
- `flutter_riverpod` (상태 관리)
- `go_router` (선언적 라우팅)
- `image_picker` (카메라·앨범 사진 입력)
- `intl` (날짜·숫자 한국어 로케일 포맷)
- `path_provider` (앱 sandbox 디렉터리 접근)
- `freezed` + `freezed_annotation` + `build_runner` (불변 모델 + 코드 생성)

**Storage**: Isar (디바이스 로컬, mmap 기반 NoSQL). `Item`, `WearEvent`, `UserPreferences` 컬렉션 + 이미지 파일은 앱 sandbox `documents/items/` 디렉터리에 사본 저장.

**Testing**: `flutter_test` (unit/widget), `integration_test` (e2e on emulator/simulator). Isar는 in-memory 인스턴스로 격리된 단위 테스트 가능.

**Target Platform**: iOS 13+ (iPhone), Android API 21+ / Android 5.0 Lollipop+ (휴대폰 폼팩터 한정). 태블릿 레이아웃은 v1 범위 밖.

**Project Type**: 모바일 단일 앱 (Flutter cross-platform, 백엔드 없음).

**Performance Goals**:
- 옷장 그리드 100점 렌더링 시작 → 첫 프레임 200ms 이내 (SC-004 매핑)
- 일반 스크롤 60 fps 유지
- 옷 등록·착용 기록 입력 시 100ms 이내 UI 반영 (SC-003 매핑)

**Constraints**:
- 오프라인 우선: 모든 핵심 작업이 네트워크 없이 동작 (FR-025, SC-007)
- 앱 강제 종료 후 100% 상태 복원 (SC-005)
- 디자인 토큰 일관성: 색상·간격·라운딩·타이포는 `design.md` 정의 외 사용 금지 (헌법 II)
- 한국어 1차 UI (`intl_ko`)
- 외부 SDK·분석 도구·서버 동기화 금지 (헌법 III)

**Scale/Scope**:
- 단일 사용자 디바이스 1대
- 의류 50~500점 (일반), 최대 1,000점까지 부드럽게 동작
- 6 화면(홈·옷장·옷 상세·옷 등록·세탁·설정) + 공용 위젯 셋

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 원칙 | 평가 | 비고 |
|---|---|---|
| **I. 큐레이션 우선 사용자 흐름** (NON-NEGOTIABLE) | ✅ Pass | Spec SC-001(등록 4단계 30초), SC-002(탐색 5초)가 흐름 단순성 가드. Flutter는 60 fps 인터랙션 가능. 부가 입력 필드(브랜드·구매일·세탁 방법)는 모두 선택 항목. |
| **II. 디자인 시스템 일관성** | ✅ Pass | `design.md` 토큰을 Flutter `ColorScheme` + `TextTheme` + 커스텀 `ThemeExtension`으로 1:1 매핑한다. 1px 디바이더 금지·토널 레이어링·Sage primary는 위젯 라이브러리에서 강제. (research.md 참조) |
| **III. 로컬 우선 데이터 소유권** | ✅ Pass | Isar는 디바이스 로컬 mmap DB. 외부 분석 SDK·서버 동기화 없음. 백업(iCloud/Drive)은 v1 범위 밖(spec Assumption). |
| **IV. Spec 주도 변경 관리** | ✅ Pass | 본 plan과 후속 tasks/code는 spec.md FR/SC에 1:1로 묶인다. PR은 본 plan을 참조한다. |

**Result**: 4/4 통과. `Complexity Tracking` 정당화 사유 없음.

## Project Structure

### Documentation (this feature)

```text
specs/001-home-dashboard/
├── plan.md              # 이 파일
├── research.md          # Phase 0 산출물 (기술 결정)
├── data-model.md        # Phase 1 산출물 (Isar 스키마)
├── quickstart.md        # Phase 1 산출물 (개발자 부트스트랩)
├── contracts/           # Phase 1 산출물
│   ├── routes.md        # 네비게이션 라우트 명세
│   └── repositories.md  # Repository 인터페이스(추상화 계층)
├── checklists/
│   └── requirements.md  # spec 품질 체크리스트
└── tasks.md             # /speckit-tasks 산출물 (이 명령에서 생성하지 않음)
```

### Source Code (repository root)

```text
lib/
├── main.dart                       # 앱 엔트리: Isar 초기화 + ProviderScope + MaterialApp.router
├── app/
│   ├── router.dart                 # go_router 정의 (홈·옷장·상세·등록·세탁·설정)
│   └── theme/
│       ├── tokens.dart             # design.md → Dart 상수 (색상·간격·라운딩)
│       ├── app_theme.dart          # ThemeData + ColorScheme + TextTheme
│       └── typography.dart         # Manrope / Inter / Pretendard 폰트 패밀리
├── core/
│   ├── persistence/
│   │   ├── isar_provider.dart      # Isar 단일 인스턴스 Riverpod provider
│   │   └── image_store.dart        # 이미지 파일을 sandbox로 복사·조회
│   ├── utils/
│   │   ├── date_formatter.dart     # "오늘" / "어제" / "M/d" 포맷
│   │   └── result.dart             # 성공/실패 타입(필요 시)
│   └── widgets/                    # 디자인 시스템 공통 위젯
│       ├── primary_button.dart     # 알약 모양 Sage primary
│       ├── soft_button.dart        # 보조 액션 (surface-container-highest 배경)
│       ├── chip_filter.dart        # 카테고리 칩
│       ├── status_label.dart       # "깨끗함" / "세탁 필요" 라벨
│       ├── progress_bar.dart       # 세탁 진행률
│       ├── toast.dart              # 2초 비차단 토스트
│       └── top_bar.dart            # 공용 상단바
├── features/
│   ├── home/
│   │   ├── home_screen.dart        # US5
│   │   └── widgets/
│   │       ├── stats_row.dart
│   │       ├── category_bento.dart
│   │       ├── recently_worn_list.dart
│   │       └── laundry_preview.dart
│   ├── wardrobe/
│   │   ├── wardrobe_screen.dart    # US2
│   │   ├── wardrobe_filter.dart
│   │   ├── garment_grid.dart
│   │   └── garment_tile.dart
│   ├── item_detail/
│   │   ├── item_detail_screen.dart # US3
│   │   ├── stats_grid.dart
│   │   └── history_timeline.dart
│   ├── add_item/
│   │   ├── add_item_screen.dart    # US1
│   │   ├── photo_picker_card.dart
│   │   ├── wash_cycle_stepper.dart
│   │   └── care_method_picker.dart
│   ├── laundry/
│   │   ├── laundry_screen.dart     # US4
│   │   └── laundry_tile.dart
│   └── settings/
│       ├── settings_screen.dart    # US5 환경 설정
│       └── profile_card.dart
└── data/
    ├── models/
    │   ├── item.dart               # @collection Isar Item
    │   ├── wear_event.dart         # @collection Isar WearEvent
    │   └── user_preferences.dart   # @collection Isar UserPreferences (single)
    ├── repositories/
    │   ├── item_repository.dart    # CRUD + 통계 쿼리
    │   ├── laundry_repository.dart # 바구니 토글·일괄 세탁 완료
    │   ├── event_repository.dart   # 착용·세탁 이벤트 기록
    │   └── preferences_repository.dart
    └── providers/
        └── app_providers.dart      # Riverpod providers (repositories·streams)

test/
├── unit/
│   ├── repositories/               # in-memory Isar로 repo 단위 테스트
│   └── theme/
├── widget/
│   ├── widgets/                    # 공용 위젯 골든 테스트
│   └── features/                   # 화면 단위 위젯 테스트
└── helpers/
    └── isar_test_helper.dart

integration_test/
├── add_item_flow_test.dart         # US1 E2E
├── wear_record_flow_test.dart      # US3 E2E
└── laundry_flow_test.dart          # US4 E2E

assets/
├── fonts/
│   ├── Manrope/                    # OFL
│   ├── Inter/                      # OFL
│   └── Pretendard/                 # OFL (한글 폴백)
├── images/
│   └── upload-placeholder.png
└── tips/laundry_tips.json          # 홈 세탁 팁 풀 (FR-021)

android/
ios/
pubspec.yaml
analysis_options.yaml
build.yaml                           # build_runner 설정 (isar_generator, freezed)
```

**Structure Decision**: Flutter 표준 단일 프로젝트 레이아웃을 채택한다. `lib/` 아래를 `app/`(부트·테마·라우팅) · `core/`(유틸·DI·공용 위젯) · `features/`(화면 단위 모듈) · `data/`(모델·리포지토리·프로바이더)로 분리한 feature-first 구조다. 백엔드가 없어 mobile + API 분리 옵션은 채택하지 않았다. `core/widgets/`에 디자인 시스템 위젯을 모아 헌법 II(디자인 일관성)를 코드 레벨에서 강제한다.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

해당 없음 — 4개 헌법 원칙 모두 위반 없이 통과.
