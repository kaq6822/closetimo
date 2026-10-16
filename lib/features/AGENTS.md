# AGENTS.md — lib/features (기능 모듈)

화면 단위 기능 모듈 레이어다. 각 모듈은 화면(Screen) + 전용 위젯 + 화면 로컬 상태로 구성된다.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
features/
├── home/         # 홈 대시보드 (통계, 카테고리 벤토, 최근 착용, 세탁 미리보기)
├── wardrobe/     # 옷장 그리드 (필터 바, 의류 타일, selection/ 다중 선택 인프라)
├── item_detail/  # 옷 상세 (히어로 이미지, 착용 기록, 히스토리 타임라인)
├── add_item/     # 옷 등록 (사진, 카테고리, 세탁 방법, freezed draft 폼 state)
├── laundry/      # 세탁 바구니 (선택 provider, 세탁 완료 처리)
├── settings/     # 설정 (프로필, 환경설정, 옷 관리 > 보관함·태그 관리 진입)
├── archive/      # 보관함 (보관한 옷 확인·복원, #44)
└── tags/         # 태그 관리 (이름 변경·병합·삭제, #46)
```

각 모듈 내부 구조: `<feature>_screen.dart`(진입점) + `widgets/`(전용 위젯) + 필요 시 폼/선택 state 파일.

## 이 레이어의 규칙

- **데이터 접근은 repository 인터페이스로만 한다**: `lib/data/repositories/`의 추상 인터페이스를
  Riverpod provider(`app_providers.dart`) 경유로 주입받는다. Isar 구현체 직접 import 금지.
- **화면·흐름은 [spec.md](../../specs/001-home-dashboard/spec.md)의 FR/SC에 근거한다.**
  화면 간 이동은 [contracts/routes.md](../../specs/001-home-dashboard/contracts/routes.md) 계약을 따르고,
  push 진입(itemDetail, addItem)은 `pushNamed`를 사용한다.
- **디자인 토큰만 사용한다**: 색상·간격·라운딩·타이포는 `lib/app/theme/` 토큰 경유.
  하드코딩 발견 시 `dart run tool/check_design_tokens.dart`가 실패한다.
- 폼 state는 freezed 불변 모델로 작성한다 (예: `add_item/new_item_draft.dart`).
  수정 후 build_runner 실행, `*.freezed.dart` 직접 수정 금지.
- 해당 feature 전용 위젯은 `<feature>/widgets/`에 둔다. 2개 이상 feature에서 재사용되면
  `lib/core/widgets/`로 승격한다.
- 화면·플로우 변경 시 `test/feature/`에 위젯 테스트를 추가·갱신한다
  (예: `add_item_flow_test.dart`, `wear_record_test.dart`).

## 옷장 다중 선택 인프라 (`wardrobe/selection/`, #43)

다중 착용 기록(#39)·일괄 편집(#46)은 아래 구조를 재사용하고 **액션만 추가**한다.

- `item_selection.dart`
  - `ItemSelection { bool active; Set<int> ids; int count; contains(id) }` — 불변 값.
  - `wardrobeSelectionProvider` (`ItemSelectionController`):
    `start([id])` 모드 진입(길게 누르기) · `toggle(id)` · `selectAll(ids)` ·
    `clear()` 선택만 비움(모드 유지) · `exit()` 모드 종료 · `retainOnly(visibleIds)`
    목록에서 사라진 옷 선택 해제.
- `selection_action_bar.dart`
  - `SelectionActionBar(count, filterSummary, onSelectAll, onClear, onExit, actions)` —
    선택 수·필터 조건 요약·모두 선택·선택 초기화·종료를 공통 표시한다.
  - `SelectionAction(label, icon, onPressed)` — 선택 0개면 바가 자동 비활성화한다.
- 화면 배선(`wardrobe_screen.dart`): 목록 emit마다 `retainOnly`, 홈 카드 진입으로 필터가
  바뀌면 `exit`, 시스템 뒤로 가기는 선택 모드에서 `exit`. 필터 요약은
  `wardrobe/filter_summary.dart`의 `describeItemFilter(ItemFilter)`.
- 타일(`GarmentTile`)은 선택 모드에서 탭=토글, 우상단에 선택 표시, 빠른 동작 메뉴 숨김.
- 현재 액션: `바구니에 담기`(#43), `태그`(#46, `selection/bulk_tag_action.dart`의 `bulkTagAction` —
  액션 1개를 돌려주는 함수로 분리해 `actions` 목록에 한 줄만 추가).
- 새 액션 추가 예: `SelectionAction(label: '착용 기록', icon: …, onPressed: () => …(selection.ids))`
  를 `wardrobe_screen.dart`의 `actions`에 넣고, 완료 후 `exit()` + 토스트. 여러 옷 쓰기는
  repository에 일괄 메서드를 계약(contracts/repositories.md) 먼저 추가해 원자적으로 처리한다.

## 사용자 태그 (#46)

- 태그 정규화·집계는 `lib/data/models/item_tags.dart`(`normalizeTags`, `parseTagInput`, `summarizeTags`)만 쓴다.
- 태그 목록·사용 수는 `tagUsageProvider`(전체 옷 스트림 집계)로 읽고, 여러 옷 쓰기는 `tagRepositoryProvider`로 한다.
- 기본 노출은 사용성 평가 전까지 접힘이다(폼 "추가 정보 (선택)" 안, 옷장 `태그` 칩 1개).
  노출을 늘리려면 docs/product/2026-10-17-attribute-usability-evaluation-plan.md 결과를 근거로 spec을 먼저 갱신한다.
