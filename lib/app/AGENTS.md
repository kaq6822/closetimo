# AGENTS.md — lib/app (앱 셸)

라우팅과 테마(디자인 토큰)를 담당하는 앱 셸 레이어다.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
app/
├── router.dart        # go_router 라우트 정의
└── theme/
    ├── tokens.dart    # 디자인 토큰 (색상·간격·라운딩) — "The Digital Atelier"
    ├── typography.dart# 타이포 토큰 (TextTheme)
    └── app_theme.dart # ThemeData 조립
```

## 이 레이어의 규칙

- **라우트 변경은 반드시 [contracts/routes.md](../../specs/001-home-dashboard/contracts/routes.md)와 동기화한다.**
  계약에 없는 라우트를 임의로 추가하지 않는다. 계약 변경이 먼저다.
- push 방식 진입 화면(itemDetail, addItem 등)은 `pushNamed`로 호출한다. `goNamed`와 혼용하지 말 것.
- **디자인 토큰의 단일 진실 원천**: 색상·간격·라운딩·타이포 값은 이 디렉토리의 `theme/`에서만 정의한다.
  다른 레이어에서 필요한 값이 없으면 여기에 토큰을 추가한 뒤 사용한다.
- 토큰 정의는 `.specify/memory/design.md`("The Digital Atelier")를 근거로 한다. 임의 값 추가 금지.
- 토큰 변경 후 `dart run tool/check_design_tokens.dart`로 하드코딩 위반이 없는지 확인한다.
- 이 레이어는 `features/`를 import할 수 있다(라우트 → 화면 연결). 반대 방향은 라우트 이름 상수로만 참조한다.
