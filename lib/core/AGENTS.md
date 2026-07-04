# AGENTS.md — lib/core (공용 인프라)

특정 기능에 속하지 않는 공용 인프라 레이어다: 영속화 유틸, 순수 유틸, 재사용 위젯.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
core/
├── persistence/
│   ├── isar_provider.dart  # Isar 인스턴스 열기/제공
│   └── image_store.dart    # 이미지 파일 sandbox 저장 (documents/items/)
├── utils/
│   ├── clock.dart          # 시간 추상화 (테스트에서 고정 시간 주입용)
│   └── date_formatter.dart # 한국어 날짜 포맷
└── widgets/                # 디자인 시스템 공용 위젯 (bottom_nav, chip_filter, toast, …)
```

## 이 레이어의 규칙

- **의존 방향의 최하단**: `core`는 `features/`, `data/`, `app/`을 import하지 않는다.
  상위 레이어 개념(Item, WearEvent 등 도메인 모델)이 필요해지면 위치가 잘못된 것이다.
- **공용 위젯은 디자인 토큰만 사용한다**: `lib/app/theme/`의 토큰 외 하드코딩 색상·간격 금지.
  (theme는 Theme.of(context) / ThemeExtension 경유로 접근한다.)
- 2개 이상의 feature에서 쓰이는 위젯만 `core/widgets/`에 둔다. 단일 feature 전용 위젯은
  해당 `features/<feature>/widgets/`에 둔다.
- 시간 의존 로직은 `DateTime.now()` 직접 호출 대신 `clock.dart`를 주입받는다 (테스트 격리).
- `utils/`의 순수 로직은 `test/unit/`에 단위 테스트를 반드시 갖춘다 (예: `date_formatter_test.dart`).
