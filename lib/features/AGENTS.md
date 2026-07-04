# AGENTS.md — lib/features (기능 모듈)

화면 단위 기능 모듈 레이어다. 각 모듈은 화면(Screen) + 전용 위젯 + 화면 로컬 상태로 구성된다.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
features/
├── home/         # 홈 대시보드 (통계, 카테고리 벤토, 최근 착용, 세탁 미리보기)
├── wardrobe/     # 옷장 그리드 (필터 바, 의류 타일)
├── item_detail/  # 옷 상세 (히어로 이미지, 착용 기록, 히스토리 타임라인)
├── add_item/     # 옷 등록 (사진, 카테고리, 세탁 방법, freezed draft 폼 state)
├── laundry/      # 세탁 바구니 (선택 provider, 세탁 완료 처리)
└── settings/     # 설정 (프로필, 환경설정)
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
