# AGENTS.md — lib/core (공용 인프라)

특정 기능에 속하지 않는 공용 인프라 레이어다: 영속화 유틸, 순수 유틸, 재사용 위젯.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
core/
├── persistence/
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

## 접근성 컨벤션 (#49, spec FR-024a·SC-007a)

- **최소 터치 영역 48×48dp**: 시각 크기가 48보다 작은 탭 컨트롤(아이콘 버튼, 체크 원, 칩, 스테퍼 ± 등)은
  시각 크기를 유지한 채 `widgets/min_touch_target.dart`의 `MinTouchTarget(onTap:, child:)`으로 감싼다.
  child가 자신의 InkWell·Semantics를 그대로 갖고, 래퍼는 바깥 여백 탭만 같은 `onTap`으로 전달하며 시맨틱
  노드를 만들지 않는다. 레이아웃이 커진 만큼 주변 패딩을 줄여 시각 위치를 맞춘다.
  처음부터 48 영역 전체가 잉크 영역인 버튼(`TopBar` 아이콘)은 `SizedBox.square(minTouchTarget)` + `Center`로 둔다.
  Material `IconButton`·`PopupMenuButton`은 기본 48 영역이므로 `visualDensity`·`constraints`로 줄이지 않는다.
- **선택 상태 시맨틱**: 색만으로 상태를 표시하지 않는다.
  - 탭·칩·단일 선택 타일: `Semantics(button: true, selected: …)`. 단일 선택 그룹은 `inMutuallyExclusiveGroup: true`.
  - 체크(다중 선택): `Semantics(checked: …)` + 라벨("<옷 이름> 선택"). 비선택도 빈 원/박스 윤곽(`controlOutline`)을 그린다.
  - 타일 전체가 체크 컨트롤이면 타일 노드에 `checked`를 싣고, 장식 표시는 `ExcludeSemantics`로 감싼다.
- **검증**: `test/feature/touch_target_a11y_test.dart`처럼 `tester.getSize`/`getSemantics(...).rect`로 48 이상,
  `isSemantics(isSelected/isChecked)`로 상태, 320dp·`TextScaler.linear(2)`에서 넘침 없음과 탭 동작을 확인한다.
