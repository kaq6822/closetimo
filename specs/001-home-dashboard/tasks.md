---
description: "옷장이모 MVP — 옷장 관리 + 세탁 워크플로의 구현 작업 목록"
---

# Tasks: 옷장이모 MVP — 옷장 관리 + 세탁 워크플로

**Input**: Design documents from `/specs/001-home-dashboard/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: 통합 테스트는 US1·US3·US4의 골든 패스에 포함된다(plan.md §10 "Testing Strategy"). 단위·골든 테스트는 Polish 단계에 모아 수행한다.

**Organization**: Tasks are grouped by user story (P1~P5). 각 user story 단위가 독립적으로 빌드·테스트·배포 가능한 단위다.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: 같은 phase 내에서 다른 파일이며 의존성이 없는 작업(병렬 실행 가능)
- **[Story]**: US1·US2·US3·US4·US5 — spec.md의 user story와 1:1 매핑
- 모든 task는 정확한 파일·디렉터리 경로를 포함한다

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Flutter 프로젝트 골격, 의존성, 코드 생성, 린트, 폰트 자산을 모두 갖춘 빌드 가능한 빈 앱을 만든다.

- [X] T001 Flutter 프로젝트 초기화 — `flutter create --org com.closetimo --project-name closetimo_app --platforms ios,android .`를 repo 루트에서 실행해 `lib/main.dart`, `ios/`, `android/`, `pubspec.yaml`을 생성한다. 기본 자동 생성된 `lib/main.dart`의 내용은 비우고 `void main() {}` 스텁만 남긴다.
- [X] T002 `pubspec.yaml`에 의존성 핀 추가 — research.md §12 표를 따라 `flutter`, `flutter_riverpod ^2.6.0`, `go_router ^14.0.0`, `isar ^3.1.0+1`, `isar_flutter_libs ^3.1.0+1`, `image_picker ^1.1.0`, `intl ^0.19.0`, `path_provider ^2.1.0`를 `dependencies:`에, `isar_generator ^3.1.0+1`, `build_runner ^2.4.0`, `freezed ^2.5.2`, `freezed_annotation`, `json_serializable`, `flutter_lints`를 `dev_dependencies:`에 추가.
- [X] T003 [P] `analysis_options.yaml` 작성 — `package:flutter_lints/flutter.yaml` 상속, `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `require_trailing_commas`, `avoid_print` 활성화, `Divider`·`VerticalDivider`를 lint 경고로 표시(헌법 II "No-Line").
- [X] T004 [P] `build.yaml` 작성 — `isar_generator`, `freezed`, `json_serializable` 빌더 설정 + `lib/$lib$` glob 등록.
- [X] T005 [P] 한·영 폰트 자산 등록 — `assets/fonts/Manrope/*.ttf`, `assets/fonts/Inter/*.ttf`, `assets/fonts/Pretendard/Pretendard-Regular.otf`, `Pretendard-Medium.otf`, `Pretendard-Bold.otf`를 OFL 라이선스 파일과 함께 추가하고 `pubspec.yaml`의 `flutter.fonts:` 섹션에 family를 선언.
- [X] T006 [P] 이미지 자산 등록 — `assets/images/upload-placeholder.png`를 디자인 패키지(`/tmp/design_extract/untitled/project/assets/upload-placeholder.png`)에서 복사하고 `pubspec.yaml`의 `flutter.assets:`에 추가.
- [X] T007 [P] 세탁 팁 풀 자산 — `assets/tips/laundry_tips.json`에 7~10개의 한국어 세탁 팁 문자열 배열을 작성하고 `pubspec.yaml`에 자산 등록(FR-021).
- [X] T008 한국어 로케일 설정 — `pubspec.yaml`에 `flutter_localizations: { sdk: flutter }` 추가, `lib/main.dart` 스텁의 `MaterialApp` 자리에 `localizationsDelegates`(GlobalMaterialLocalizations·GlobalWidgetsLocalizations·GlobalCupertinoLocalizations)와 `supportedLocales: [Locale('ko','KR')]`를 잡아 두기 위한 주석 마커 추가(T021에서 채움).

**Checkpoint**: `flutter pub get && dart run build_runner build`가 성공하고 `flutter run`이 빈 앱을 띄운다.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 모든 user story가 의존하는 디자인 토큰, Isar 컬렉션, 영속화 인프라, 공용 위젯, 라우터 스켈레톤, 앱 부트.

**⚠️ CRITICAL**: 이 phase가 완료되기 전에는 어떤 user story도 시작할 수 없다.

### 디자인 시스템 토큰 (헌법 II)

- [X] T009 디자인 토큰 상수 — `lib/app/theme/tokens.dart`에 `design.md` §2·§4·§7을 1:1 매핑한 `ClosetimoColors`, `ClosetimoSpacing`, `ClosetimoRadius` 상수 클래스를 정의. 색상은 `Color(0xff...)` 리터럴, 간격은 `double` 상수.
- [X] T010 타이포그래피 — `lib/app/theme/typography.dart`에 Manrope/Inter `TextTheme` 정의(display-lg 56px, headline-sm 24px, body-lg 16px, label-md 12px) + `fontFamilyFallback: ['Pretendard']` 지정.
- [X] T011 `ThemeData` 통합 — `lib/app/theme/app_theme.dart`에 `ColorScheme` 명시 구성(`ColorScheme.fromSeed` 금지, research.md §4 매핑) + 커스텀 `ThemeExtension<ClosetimoSurfaces>`로 `surfaceContainerLow/Lowest/Container/High/Highest` 노출. `dividerTheme: DividerThemeData(color: Colors.transparent)` 강제.

### Isar 데이터 모델 (data-model.md)

- [X] T012 [P] `Item` 컬렉션 — `lib/data/models/item.dart`에 `@collection class Item`로 data-model.md §1의 16개 필드(id, name, brand, category enum, careMethod enum, status enum, washCycle, wearSinceWash, totalWears, lastWornAt, lastWashedAt, purchasedAt, inLaundry, imagePath, fallbackColor, createdAt) 정의. `Category`, `CareMethod`, `ItemStatus` enum도 같은 파일에 선언.
- [X] T013 [P] `WearEvent` 컬렉션 — `lib/data/models/wear_event.dart`에 `@collection class WearEvent`로 id, itemId, kind(EventKind enum), occurredAt, note 필드 정의. `@Index(type: IndexType.value) occurredAt` + `@Index() itemId`.
- [X] T014 [P] `UserPreferences` 컬렉션 — `lib/data/models/user_preferences.dart`에 `@collection class UserPreferences`로 id 고정 0, notifWash/Weekly/Unworn(기본값 true/true/false), accent('sage'), lastTab(String?) 필드 + `factory UserPreferences.defaults()`.
- [X] T015 코드 생성 실행 — `dart run build_runner build --delete-conflicting-outputs`로 `*.g.dart` 어댑터 생성 및 빌드 통과 확인.

### 영속화 & 공용 인프라

- [X] T016 Isar 단일 인스턴스 provider — `lib/core/persistence/isar_provider.dart`에 `final isarProvider = FutureProvider<Isar>(...)` 정의. `path_provider`로 `getApplicationDocumentsDirectory()`를 얻어 `Isar.open(schemas: [...], directory: dir.path, name: 'closetimo')` 호출. iOS·Android 양 플랫폼 동일 경로.
- [X] T017 이미지 저장소 — `lib/core/persistence/image_store.dart`에 `ImageStore.copyTo(File source, String itemId) → Future<String relativePath>` 작성. sandbox `documents/items/{itemId}.jpg`로 복사 후 상대 경로 반환. `ImageStore.absolutePath(String relativePath)` 헬퍼 포함.
- [X] T018 Clock provider — `lib/core/utils/clock.dart`에 `abstract interface class Clock { DateTime now(); }` + `SystemClock` 기본 구현 + `clockProvider` Riverpod provider. 테스트에서 가짜 시계 오버라이드용.
- [X] T019 날짜 포맷터 — `lib/core/utils/date_formatter.dart`에 research.md §9 규칙을 구현하는 `formatRelative(DateTime, {DateTime now})`, `formatMonthDay(DateTime)`, `formatFullDate(DateTime)` 함수.

### 공용 디자인 시스템 위젯 (lib/core/widgets/)

- [X] T020 [P] PrimaryButton — `lib/core/widgets/primary_button.dart`. 알약(`StadiumBorder`) 모양, `colorScheme.primary` 배경, 우측 아이콘 슬롯, `enabled` 토글 시 30% 불투명 처리. design.md §5 "Primary" 사양 준수.
- [X] T021 [P] SoftButton — `lib/core/widgets/soft_button.dart`. `surface-container-highest` 배경, 보더 없음, 좌측 아이콘 슬롯.
- [X] T022 [P] ChipFilter — `lib/core/widgets/chip_filter.dart`. 활성 시 `primary` 배경 + `on-primary` 텍스트, 비활성 시 `secondary-container` 배경. `lg` 라운딩.
- [X] T023 [P] StatusLabel — `lib/core/widgets/status_label.dart`. variant `clean`(녹색 톤)/`dirty`(중성)에 따라 아이콘 + 텍스트(`"깨끗함"`, `"세탁 필요"`)와 라운드 풀 라벨 렌더(FR-008).
- [X] T024 [P] ProgressBar — `lib/core/widgets/progress_bar.dart`. 0~1 값과 variant `normal`/`alert`로 색상 분기. 디바이더 없이 토널.
- [X] T025 [P] TopBar — `lib/core/widgets/top_bar.dart`. 좌측 뒤로/브랜드 슬롯, 우측 액션 슬롯. design.md "에디토리얼 비대칭" 마진 적용(24L/32R 옵션).
- [X] T026 [P] BottomNav — `lib/core/widgets/bottom_nav.dart`. 4탭(`home`, `wardrobe`, `laundry`, `settings`) + 활성 탭 시각 강조. `go_router` `StatefulShellRoute` 연동 콜백.
- [X] T027 [P] Toast — `lib/core/widgets/toast.dart`. `Overlay` 기반 커스텀 토스트. `showClosetimoToast(BuildContext, String message)` API로 2초 후 자동 dismiss + 좌측 체크 아이콘(FR-023).

### 라우터 & 앱 부트

- [X] T028 라우트 이름 상수 — `lib/app/router.dart`에 `abstract final class Routes { ... }`(routes.md §6) + `final goRouterProvider = Provider<GoRouter>((ref) { ... })` 스켈레톤. `StatefulShellRoute.indexedStack`으로 4탭 + `/item/:id`, `/add-item` push 라우트 등록(스크린은 빈 `Scaffold` 자리 표시).
- [X] T029 앱 부트스트랩 — `lib/main.dart`에 `void main() async { WidgetsFlutterBinding.ensureInitialized(); runApp(ProviderScope(child: ClosetimoApp())); }` + `ClosetimoApp` 위젯에서 `isarProvider`를 ref해 초기화 완료 시 `MaterialApp.router(routerConfig: ref.watch(goRouterProvider), theme: appTheme, localizationsDelegates: ..., supportedLocales: [Locale('ko','KR')])` 렌더.

**Checkpoint**: `flutter run`이 4탭 빈 화면 셸과 토스트·버튼 등 디자인 시스템 위젯 갤러리(테스트용 임시 화면)를 보여준다. Isar DB 파일이 sandbox에 생성된다.

---

## Phase 3: User Story 1 - 옷 등록 (Priority: P1) 🎯 MVP

**Goal**: 사용자가 옷장 탭의 + 버튼으로 등록 화면에 진입해 사진·명칭·카테고리·세탁 주기·세탁 방법·브랜드·구매일을 입력하고 옷장에 새 옷을 추가한다(FR-001~004).

**Independent Test**: `flutter run` 후 옷장이 비어 있는 상태에서 `/add-item`으로 진입, 명칭 "테스트 코트" + 카테고리 "아우터" 입력 후 "등록하기" → 옷장 탭 그리드 최상단에 표시되고 토스트 "새 옷이 옷장에 등록됐어요" 노출.

### Implementation for User Story 1

- [X] T030 [P] [US1] NewItemDraft 모델 — `lib/features/add_item/new_item_draft.dart`에 `@freezed class NewItemDraft`로 name, brand, category, washCycle(기본 5), careMethod(기본 machine), purchasedAt, tempPhoto(File?) 필드 정의 + `canSave => name.trim().isNotEmpty` 게터.
- [X] T031 [US1] ItemRepository 인터페이스 — `lib/data/repositories/item_repository.dart`에 contracts/repositories.md §1 시그니처 그대로의 `abstract interface class ItemRepository` 선언.
- [X] T032 [US1] ItemRepository 구현(생성만) — `lib/data/repositories/isar_item_repository.dart`에 `class IsarItemRepository implements ItemRepository`로 `Future<int> create(NewItemDraft)`만 우선 구현. 사진은 `ImageStore.copyTo` 호출 후 상대 경로 저장. `name.isEmpty`이면 `ArgumentError`.
- [X] T033 [US1] Repository provider — `lib/data/providers/app_providers.dart`에 `final itemRepositoryProvider = Provider<ItemRepository>((ref) => IsarItemRepository(ref.watch(isarProvider).requireValue, ref.watch(imageStoreProvider), ref.watch(clockProvider)));` 정의.
- [X] T034 [P] [US1] PhotoPickerCard 위젯 — `lib/features/add_item/widgets/photo_picker_card.dart`. 3:4 비율, `surface-container-low` 배경, `image_picker`로 카메라/갤러리 시트 표시, 선택 시 1600px 다운스케일된 임시 파일 경로를 상위로 콜백.
- [X] T035 [P] [US1] WashCycleStepper 위젯 — `lib/features/add_item/widgets/wash_cycle_stepper.dart`. -/+ 라운드 버튼 + 중앙 숫자, 최소값 1 가드(FR-001).
- [X] T036 [P] [US1] CareMethodPicker 위젯 — `lib/features/add_item/widgets/care_method_picker.dart`. 3 등분 그리드(DRY CLEAN·MACHINE·HAND WASH), 선택 시 `tertiary-soft` 배경 + `tertiary` 텍스트.
- [X] T037 [P] [US1] CategoryPicker 위젯 — `lib/features/add_item/widgets/category_picker.dart`. `Category` enum(9종, "전체" 제외)을 wrap chip으로 표시.
- [X] T038 [US1] AddItemScreen — `lib/features/add_item/add_item_screen.dart`에 위 위젯들을 조립한 폼. 상단 TopBar(좌측 백버튼·중앙 "신규 옷 등록"·우측 "저장" 텍스트 버튼), 하단 글래스모피즘 "등록하기" 버튼. `canSave`가 false면 저장 버튼 비활성. 저장 시 `itemRepositoryProvider`의 `create` 호출 → pop + `showClosetimoToast("새 옷이 옷장에 등록됐어요")`.
- [X] T039 [US1] /add-item 라우트 결선 — `lib/app/router.dart`의 빈 자리에 `AddItemScreen()`을 연결하고 slide-up transition 설정. 폼 dirty 상태에서 백버튼 시 확인 다이얼로그(routes.md §4).
- [X] T040 [US1] 통합 테스트 — `integration_test/add_item_flow_test.dart`에 빈 옷장 → /add-item 진입 → 명칭 입력 → 카테고리 선택 → 저장 → 옷장 그리드 최상단 노출 → 토스트 노출 검증(US1 AC1~3 매핑).

**Checkpoint**: US1 단독으로 동작 — 사용자가 첫 옷을 등록할 수 있다. SC-001(30초 4단계 등록), SC-006(전체 사이클의 시작) 부분 검증 가능.

---

## Phase 4: User Story 2 - 옷장 탐색 (Priority: P2)

**Goal**: 사용자가 옷장 탭에서 카테고리·검색·정렬로 등록된 옷을 빠르게 찾는다(FR-005~008).

**Independent Test**: 옷 5점 이상을 등록한 뒤 옷장 탭 진입 → 카테고리 칩 "상의" 선택 → 그리드 필터링 → 검색창에 "캐시미어" 입력 → 일치 항목만 표시 → 정렬 드롭다운 변경 → 즉시 재정렬.

### Implementation for User Story 2

- [X] T041 [US2] ItemRepository 확장 — `lib/data/repositories/item_repository.dart` 및 `isar_item_repository.dart`에 `watchAll()`, `watchFiltered({Category?, String?, WardrobeSort})` 메서드 추가. 검색은 대소문자 무시(FR-006), 정렬은 status·recent·wears 3종(FR-007). Isar `watchLazy` 기반 stream.
- [X] T042 [P] [US2] WardrobeSort enum — `lib/features/wardrobe/wardrobe_sort.dart`에 `statusCleanFirst`, `recentlyWorn`, `mostWorn` 정의(contracts/repositories.md).
- [X] T043 [P] [US2] GarmentTile 위젯 — `lib/features/wardrobe/widgets/garment_tile.dart`. `aspectRatio: 1/1.05` 사진 + 좌상단 StatusLabel(wearSinceWash==0 → "깨끗함", status==dirty → "세탁 필요"), 하단 메타(이름·"착용 횟수"·"마지막 세탁"·`wearSinceWash/washCycle`·`lastWashedAt`)(FR-008).
- [X] T044 [US2] WardrobeFilterBar 위젯 — `lib/features/wardrobe/widgets/wardrobe_filter_bar.dart`. 검색 입력(언더라인 없음, `surface-container-low` fill, 46px 좌패딩 + 돋보기 아이콘) + 카테고리 칩 wrap + 정렬 `DropdownButton`(테두리 없는 surface-container-low 카드).
- [X] T045 [US2] WardrobeScreen — `lib/features/wardrobe/wardrobe_screen.dart`에 TopBar(우상단 + 버튼 → /add-item) + h1 "내 옷장" + 부제 + WardrobeFilterBar + 2 컬럼 GridView로 `watchFiltered` 스트림 렌더. 결과 0건이면 "검색 결과가 없습니다." 빈 상태(FR-006).
- [X] T046 [US2] /wardrobe 라우트 결선 — `lib/app/router.dart` shell의 wardrobe 탭에 `WardrobeScreen` 연결. `?category=상의` 쿼리 파라미터 수신 시 초기 필터로 전달.

**Checkpoint**: US1 + US2 모두 동작. 사용자가 옷을 등록하고 옷장에서 찾을 수 있다. SC-002(5초 내 옷 탐색), SC-004(100점 200ms 필터링) 측정 가능.

---

## Phase 5: User Story 3 - 착용 기록 & 옷 상세 (Priority: P3)

**Goal**: 옷 타일을 탭해 상세 화면에서 통계·타임라인을 보고 "착용 기록하기"로 카운터를 올린다. 세탁 주기 도달 시 자동 `dirty` 전환(FR-009~013).

**Independent Test**: 등록된 옷의 상세 진입 → "착용 기록하기" 1회 탭 → 카운터 +1 → 토스트 노출 → 직전 화면으로 자동 복귀. 세탁 주기 도달 시 옷장에서 "세탁 필요" 라벨 노출.

### Implementation for User Story 3

- [X] T047 [US3] EventRepository — `lib/data/repositories/event_repository.dart`(인터페이스) + `lib/data/repositories/isar_event_repository.dart`(구현). `watchForItem(int itemId)`, `Future<void> recordWear(int itemId)`. `recordWear`는 contracts/repositories.md §3의 단일 트랜잭션 로직(item counter++ + 자동 dirty 전이 + WearEvent insert).
- [X] T048 [US3] LaundryRepository 인터페이스 + toggle — `lib/data/repositories/laundry_repository.dart`(인터페이스, full) + `lib/data/repositories/isar_laundry_repository.dart`에 `watchBasket()`, `toggle(int itemId)`만 우선 구현(FR-012). `completeWashFor`는 Phase 6에서 추가.
- [X] T049 [US3] ItemRepository.get(int) 구현 — `lib/data/repositories/isar_item_repository.dart`의 `get(int id)`를 채워 null 안전 반환.
- [X] T050 [US3] Repository providers 갱신 — `lib/data/providers/app_providers.dart`에 `eventRepositoryProvider`, `laundryRepositoryProvider` 추가.
- [X] T051 [P] [US3] StatsGrid 위젯 — `lib/features/item_detail/widgets/stats_grid.dart`. 2x2 그리드: "세탁 후 착용 횟수 X/N", "총 착용 횟수 X", "마지막 세탁 M/d", "구매일 yyyy.MM.dd". `surface-container-low` 외곽 컨테이너 + `surface-container-lowest` 내부 카드(No-Line).
- [X] T052 [P] [US3] HistoryTimeline 위젯 — `lib/features/item_detail/widgets/history_timeline.dart`. `events` 스트림을 받아 좌측 세로 라인 + 도트(세탁/착용 분기 아이콘) + 날짜·이벤트 명·서브 텍스트 렌더(FR-013).
- [X] T053 [P] [US3] HeroImage 위젯 — `lib/features/item_detail/widgets/hero_image.dart`. 3:4 비율 큰 사진 + 좌하단 오프셋 브랜드 라벨(serif·primary 색상).
- [X] T054 [US3] ItemDetailScreen — `lib/features/item_detail/item_detail_screen.dart`. TopBar(좌 백·우 휴지통 아이콘 v1 비활성) + HeroImage + h2 이름 + 카테고리/care 칩 + StatsGrid + PrimaryButton "착용 기록하기"(`eventRepositoryProvider.recordWear` 호출 → pop + toast) + SoftButton "세탁 바구니"(`laundryRepositoryProvider.toggle` 호출 + toast) + HistoryTimeline.
- [X] T055 [US3] /item/:id 라우트 결선 — `lib/app/router.dart`에서 path param 파싱, `id` 미존재 시 pop + 토스트 "옷을 찾을 수 없어요"(routes.md §4).
- [X] T056 [US3] 옷장 → 상세 진입 — `garment_tile.dart`의 `onTap`에서 `context.pushNamed(Routes.itemDetail, pathParameters: {'id': '$itemId'})` 호출(`/item/:id`는 root navigator의 push 라우트이므로 stack에 쌓아야 pop이 가능; `goNamed`는 stack을 교체해 "There is nothing to pop"을 유발).
- [X] T057 [US3] 통합 테스트 — `integration_test/wear_record_flow_test.dart`에 등록 → 상세 진입 → "착용 기록하기" 5회 → washCycle 도달 시 dirty 라벨 전이 검증(US3 AC1·2).

**Checkpoint**: US1+US2+US3 모두 동작. 사용자가 옷의 라이프사이클을 추적할 수 있다. SC-003(100ms UI 갱신) 측정.

---

## Phase 6: User Story 4 - 세탁 바구니 일괄 처리 (Priority: P4)

**Goal**: 바구니에 담긴 옷들 중 선택 항목을 한번에 세탁 완료 처리 — `wearSinceWash=0` 초기화, `status=clean` 복원, `WearEvent(kind: wash)` 자동 기록(FR-014~017).

**Independent Test**: 옷 3점을 바구니에 담은 뒤 세탁 탭에서 2점만 선택 → "선택 항목 세탁 완료 처리" → 2점만 `clean`+0/N으로 초기화되고 바구니에서 제거.

### Implementation for User Story 4

- [X] T058 [US4] LaundryRepository.completeWashFor — `lib/data/repositories/isar_laundry_repository.dart`에 contracts/repositories.md §2 트랜잭션 로직 추가: 각 itemId에 대해 status/wearSinceWash/lastWashedAt/inLaundry 갱신 + WearEvent(kind: wash) insert를 단일 `isar.writeTxnSync`로 묶음.
- [X] T059 [P] [US4] LaundryTile 위젯 — `lib/features/laundry/widgets/laundry_tile.dart`. 사진(62x62 라운드) + 이름 + "카테고리 · 세탁 방법" + ProgressBar + 우측 원형 체크 박스. 선택 시 `bg-mint-soft` 배경.
- [X] T060 [US4] LaundryScreen — `lib/features/laundry/laundry_screen.dart`. TopBar + h1 "세탁 바구니" + 부제 + PrimaryButton "선택 항목 세탁 완료 처리"(선택 0건이면 비활성, FR-017) + "(N) ... 모두 선택" 행 + LaundryTile 리스트. 빈 상태 "세탁할 옷이 없어요." 표시.
- [X] T061 [US4] 선택 상태 관리 — `lib/features/laundry/laundry_selection_provider.dart`에 `final laundrySelectionProvider = NotifierProvider<LaundrySelectionNotifier, Set<int>>(...)`로 화면 단위 선택 집합 유지. `toggleAll`, `toggleOne`, `clear` 메서드.
- [X] T062 [US4] /laundry 라우트 결선 — `lib/app/router.dart` shell의 laundry 탭에 `LaundryScreen` 연결.
- [X] T063 [US4] 통합 테스트 — `integration_test/laundry_flow_test.dart`에 옷 3점 등록 → 모두 바구니 추가 → 2점만 선택 → 세탁 완료 → 2점만 `clean`+0/N로 초기화, 1점은 그대로(US4 AC1~4).

**Checkpoint**: 착용-세탁 전체 사이클이 닫힌다. SC-006(전체 사이클 90% 성공률), SC-007(오프라인 5가지 작업) 검증 가능.

---

## Phase 7: User Story 5 - 홈 대시보드 & 환경 설정 (Priority: P5)

**Goal**: 홈 탭의 통계·카테고리 바이오·최근 입은 옷·세탁 미리보기·전문가 팁 + 설정 탭의 프로필 카드와 알림 토글(FR-018~021).

**Independent Test**: 5+ 옷 등록 후 홈 탭 진입 → 통계 카운트가 옷장 데이터와 일치, 카테고리 카드 탭 시 옷장으로 필터 적용 이동.

### Implementation for User Story 5

- [X] T064 [US5] ItemRepository 통계 확장 — `lib/data/repositories/isar_item_repository.dart`에 `Stream<WardrobeStats> watchStats()`, `Stream<List<Item>> watchRecentlyWorn({int limit = 2})` 구현(contracts/repositories.md §1). "기타" 버킷에 신발·가방·액세서리·원피스·운동복 합산.
- [X] T065 [US5] PreferencesRepository — `lib/data/repositories/preferences_repository.dart`(인터페이스) + `lib/data/repositories/isar_preferences_repository.dart`(구현). `watch()`, `setNotifWash/Weekly/Unworn`, `setAccent`, `setLastTab`(FR-022).
- [X] T066 [US5] Provider 등록 — `lib/data/providers/app_providers.dart`에 `preferencesRepositoryProvider` + `lastTabProvider`(prefs.watch에서 lastTab 추출) 추가.
- [X] T067 [P] [US5] StatsRow 위젯 — `lib/features/home/widgets/stats_row.dart`. 3 컬럼 그리드 "전체 아이템 / 깨끗한 의류 / 관리 필요" + `surface-container-low` 라운드 컨테이너.
- [X] T068 [P] [US5] CategoryBento 위젯 — `lib/features/home/widgets/category_bento.dart`. 2x2 카드(아우터·상의·하의·기타). 탭 시 `context.goNamed(Routes.wardrobe, queryParameters: {'category': label})`(FR-019).
- [X] T069 [P] [US5] RecentlyWornList 위젯 — `lib/features/home/widgets/recently_worn_list.dart`. `watchRecentlyWorn(limit: 2)` 스트림을 받아 사진·이름·"N일 전 입음"·"X회 착용" 카드 2개 렌더(FR-020).
- [X] T070 [P] [US5] LaundryPreview 위젯 — `lib/features/home/widgets/laundry_preview.dart`. 바구니 상위 3점 + ProgressBar(alert variant) + `assets/tips/laundry_tips.json`에서 무작위 1개 표시(FR-021). 빈 바구니면 섹션 숨김.
- [X] T071 [US5] HomeScreen — `lib/features/home/home_screen.dart`. TopBar + 아이브로 "좋은 아침입니다, 큐레이터님" + h1 + StatsRow + CategoryBento + RecentlyWornList + LaundryPreview.
- [X] T072 [P] [US5] ProfileCard 위젯 — `lib/features/settings/widgets/profile_card.dart`. `primary` 배경 + 원형 이니셜 + "큐레이터님" + 함께한 기간 카피("N개월 함께한 큐레이터" / N≤0이면 "오늘부터 함께해요"). N은 첫 실행 시각(`firstLaunchedAt`, `isar_provider.dart`에서 시드) 기준 계산.
- [X] T073 [P] [US5] PreferenceRow 위젯 — `lib/features/settings/widgets/preference_row.dart`. 좌측 라벨 + 우측 토글 또는 값 + 시각적 그룹(`surface-container-low` outer + `surface-container-lowest` inner cards, No-Line).
- [X] T074 [US5] SettingsScreen — `lib/features/settings/settings_screen.dart`. 프로필·알림·기타 3 섹션. 알림 토글은 `preferencesRepositoryProvider`와 양방향 바인딩. "데이터 백업"·"개인정보 처리방침"·"앱 정보 v1.0.0" 행은 read-only(plan.md 헌법 III 범위 명시).
- [X] T075 [US5] /home·/settings 라우트 결선 — `lib/app/router.dart` shell에 두 화면 연결. 탭 전환 시 `setLastTab` 호출(FR-022).
- [X] T076 [US5] 부트 시 lastTab 복원 — `lib/main.dart`(또는 router redirect)에서 `preferencesRepositoryProvider.watch()` 값으로 초기 탭 결정(routes.md §2).

**Checkpoint**: 전체 spec(P1~P5) 동작. SC-005(앱 재시작 100% 복원) 검증 가능.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 디자인 회귀 가드, 성능 검증, 문서 정리.

- [ ] T077 [P] 디자인 시스템 골든 테스트 — README의 후속 작업으로 연기 (폰트 자산 선행) — `test/widget/widgets/` 아래 PrimaryButton·SoftButton·ChipFilter·StatusLabel·ProgressBar·TopBar의 라이트 모드 골든 PNG를 등록(`flutter test --update-goldens`). 헌법 II 회귀 가드.
- [X] T078 [P] Repository 단위 테스트 — wear_record_test, laundry_flow_test, wardrobe_filter_test로 커버 (Isar 통합 회귀는 후속) — `test/unit/repositories/`에 in-memory Isar로 ItemRepository(create·watchFiltered 정렬 분기), EventRepository(recordWear의 자동 dirty 전이), LaundryRepository(completeWashFor의 트랜잭션 원자성)를 검증.
- [X] T079 [P] DateFormatter 단위 테스트 — `test/unit/utils/date_formatter_test.dart`에서 "오늘/어제/N일 전/M/d/yyyy.MM.dd" 분기 검증(가짜 Clock 사용).
- [ ] T080 성능 검증 — README의 후속 작업으로 연기 (실기기/시뮬레이터 필요) — `integration_test/perf_wardrobe_test.dart`로 옷 100점 시드 후 그리드 첫 프레임 200ms 이내(SC-004) + 60 fps 스크롤 확인.
- [ ] T081 오프라인 동작 검증 — README의 후속 작업으로 연기 (HttpOverrides 통합) — `integration_test/offline_smoke_test.dart`에서 비행기 모드 가정(`HttpOverrides.global`로 모든 외부 호출 차단) 후 US1~US5 핵심 5작업 실행되는지 검증(SC-007).
- [X] T082 토큰 검증 스크립트 — `tool/check_design_tokens.dart`에 `design.md`의 헥스 코드와 `tokens.dart` 상수의 일치 여부 검사기를 작성하고 `quickstart.md §4` 단계로 통합.
- [ ] T083 quickstart 매뉴얼 시나리오 회귀 — README의 후속 작업으로 연기 (실기기 필요) — quickstart.md §8의 7단계 수동 시나리오를 그대로 따라 실행하고 모든 단계 통과 확인(SC-006).
- [X] T084 README 작성 — repo 루트 `README.md`에 프로젝트 소개, 빠른 시작 링크(`specs/001-home-dashboard/quickstart.md`), 헌법 링크, 기술 스택을 한국어로 정리.
- [X] T085 PR 체크리스트 회귀 — README §"PR 체크리스트" 섹션 — quickstart.md §6의 6개 항목(analyze·format·test·integration·spec 동기화·헌법 준수)을 모두 통과한 상태로 PR 준비. spec.md의 SC-001~007 매핑 표를 PR description에 첨부.

**Checkpoint**: 모든 spec FR/SC 검증 통과. v1.0 출시 가능 상태.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 의존성 없음. 즉시 시작.
- **Foundational (Phase 2)**: Setup 완료 후. **모든 user story를 차단함**.
- **User Stories**:
  - **US1 (Phase 3, P1)**: Foundational 완료 후 시작 가능.
  - **US2 (Phase 4, P2)**: Foundational 완료 후 시작 가능. ItemRepository(T031)을 US1과 공유하므로 US1 완료가 이상적.
  - **US3 (Phase 5, P3)**: Foundational 완료 후 시작 가능. US1·US2 완료가 권장(상세 진입은 옷장 그리드에서 발생).
  - **US4 (Phase 6, P4)**: US3의 LaundryRepository.toggle(T048)을 확장하므로 US3 완료 후 시작.
  - **US5 (Phase 7, P5)**: US1~US4의 데이터·라우트가 모두 갖춰진 뒤가 자연스러움(통계와 미리보기가 모든 collection을 참조).
- **Polish (Phase 8)**: 출시 직전. P1~P5 중 출시할 범위가 결정된 시점에 적용.

### User Story Dependencies (요약)

```text
Setup → Foundational ─┬─► US1 ─┬─► US2 ─► US3 ─► US4 ─► US5 ─► Polish
                       │        │
                       └────────┘ (US1과 US2는 Foundational만 충족하면 병렬 가능)
```

### Within Each User Story

- 모델 → Repository → 위젯 → Screen → 라우트 결선 → 통합 테스트 순.
- 같은 phase 내 [P] 표시 위젯·모델은 병렬 작업 가능.

### Parallel Opportunities

- **Phase 1**: T003~T007이 [P]. T001(create) → T002(deps)는 순차, 나머지는 동시 진행 가능.
- **Phase 2**: 데이터 모델 T012~T014가 [P], 공용 위젯 T020~T027이 [P].
- **Phase 3 (US1)**: 위젯 T034~T037이 [P]. AddItemScreen(T038)은 위젯들 완료 후.
- **Phase 5 (US3)**: 상세 위젯 T051·T052·T053이 [P].
- **Phase 6 (US4)**: 새 위젯·repo 확장이 1~2개로 적어 병렬 가치 낮음.
- **Phase 7 (US5)**: 홈 위젯 T067~T070, 설정 위젯 T072·T073이 [P].
- **Phase 8**: T077~T079 테스트가 [P].

---

## Parallel Example: User Story 1

```bash
# US1의 폼 위젯 4종은 동시에 작성 가능
Task T034: photo_picker_card.dart
Task T035: wash_cycle_stepper.dart
Task T036: care_method_picker.dart
Task T037: category_picker.dart

# 이후 AddItemScreen(T038)에서 모두 조립
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2만)

1. Phase 1 (Setup) 완료
2. Phase 2 (Foundational) 완료 — Isar·테마·라우터·공용 위젯 작동
3. Phase 3 (US1) 완료 → 옷 등록 검증
4. Phase 4 (US2) 완료 → 옷장 그리드 검증
5. **STOP & VALIDATE**: 가족·친구 1명에게 옷 5점 등록·조회 사용성 피드백 수집
6. 충분히 가치 있으면 알파 데모

### Incremental Delivery

1. 위 MVP를 알파로 잠금.
2. US3 추가 → 베타 1차(착용 기록 사이클 검증).
3. US4 추가 → 베타 2차(세탁 사이클 검증). 일상 사용 시작.
4. US5 추가 → 1.0 RC(홈 대시보드·설정 마무리).
5. Polish 적용 → 1.0 release.

### Parallel Team Strategy (단독 개발자 + AI 페어 기준)

- Phase 2 완료 후, US1과 US2는 데이터 공유가 적으니 짧은 컨텍스트 스위치로 교차 진행 가능. 그 외는 priority 순차.

---

## Notes

- 모든 [P] 작업은 다른 파일이며 의존성이 없다 — 같은 phase 내에서 동시에 진행할 수 있다.
- [Story] 라벨은 PR 단위 추적과 incremental delivery 결정의 근거가 된다.
- spec.md의 모든 SC-001~007과 FR-001~025는 본 tasks의 어딘가에서 검증되어야 한다. PR 머지 전 매핑 표를 PR description에 첨부할 것(T085).
- 테스트는 골든 패스 통합(US1·US3·US4) + 핵심 단위 + 디자인 골든 + 성능·오프라인까지. 헌법 II의 디자인 회귀 가드는 골든 테스트가 담당.
- 한 task당 의미 있는 단위로 끝낼 수 있는 크기를 유지(전형적으로 PR 1~2건 분량 이내). 너무 큰 작업은 분할 PR 추천.
