# 옷장이모(Closetimo)

> 옷장을 관리하는 도구가 아니라, 큐레이션하는 경험을 위한 모바일 앱.

옷장이모는 **iOS · Android** 단일 코드베이스(Flutter)로 만든 개인용 의류 관리 앱입니다. "옷을 몇 번 입었는지 / 언제 빨았는지"를 자동으로 추적해 세탁 사이클을 줄이고, 그 위에 에디토리얼 부티크의 시각 언어("The Digital Atelier")를 입혔습니다.

## 핵심 기능 (MVP v1)

| 사용자 흐름 | 동작 | 명세 |
|---|---|---|
| **옷 등록** | 사진·명칭·카테고리·세탁 주기·세탁 방법을 입력해 옷장에 추가 | US1 / FR-001~004 |
| **옷장 탐색** | 카테고리 필터·검색·정렬로 빠르게 옷 찾기 | US2 / FR-005~008 |
| **착용 기록** | 옷 상세에서 "착용 기록하기" 한 번으로 카운터 +1, 세탁 주기 도달 시 자동 `dirty` 전이 | US3 / FR-009~013 |
| **세탁 바구니** | 옷을 바구니에 담고 선택 항목만 일괄 세탁 완료 처리 | US4 / FR-014~017 |
| **홈 대시보드** | 전체/깨끗/관리필요 통계 + 카테고리 분포 + 최근 입은 옷 + 세탁 미리보기·전문가 팁 | US5 / FR-018~021 |
| **환경 설정** | 알림 토글, 마지막 탭 복원, 액센트 색상 (v1.1 예정) | US5 / FR-022 |

## 기술 스택

- **Flutter** 3.27+ / **Dart** 3.5+
- **Isar** 3.x — 디바이스 로컬 NoSQL DB (헌법 III: 로컬 우선 데이터 소유권)
- **Riverpod** — 컴파일 안전한 상태 관리, Isar `watchLazy`와 자연스러운 결합
- **go_router** — 선언적 라우팅, 4탭 `StatefulShellRoute.indexedStack`
- **image_picker** + `path_provider` — 카메라/앨범 사진 + sandbox 사본 저장

자세한 결정 근거는 [specs/001-home-dashboard/research.md](specs/001-home-dashboard/research.md).

## 빠른 시작

```bash
# 1. 의존성 + 코드 생성
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 2. iOS 의존성 (macOS만)
cd ios && pod install && cd -

# 3. 실행
flutter run                                       # 기본
flutter run --dart-define=SEED_DEMO=true          # 데모 시드 (개발용)

# 4. 검증
flutter analyze
flutter test
dart run tool/check_design_tokens.dart            # 디자인 토큰 일치 (헌법 II 가드)
```

전체 셋업 가이드는 [specs/001-home-dashboard/quickstart.md](specs/001-home-dashboard/quickstart.md).

## 프로젝트 구조

```
lib/
├── app/                       # 부트 · 테마 · 라우팅
│   ├── router.dart
│   └── theme/{tokens,typography,app_theme}.dart
├── core/
│   ├── persistence/           # Isar provider · 이미지 sandbox
│   ├── utils/                 # Clock · date_formatter
│   └── widgets/               # 디자인 시스템 공용 위젯
├── features/
│   ├── home/                  # US5 홈
│   ├── wardrobe/              # US2 옷장
│   ├── item_detail/           # US3 상세
│   ├── add_item/              # US1 등록
│   ├── laundry/               # US4 세탁
│   └── settings/              # US5 설정
└── data/
    ├── models/                # @collection Isar 컬렉션
    ├── repositories/          # 추상 + Isar 구현
    └── providers/             # Riverpod providers

specs/001-home-dashboard/      # spec · plan · research · data-model · contracts · tasks
.specify/memory/               # 헌법 · 디자인 시스템 문서
```

## 헌법 (옷장이모 Constitution)

본 프로젝트는 [`.specify/memory/constitution.md`](.specify/memory/constitution.md)에 4개 원칙을 잠가두고 모든 변경이 이를 충족하는지 PR 단위로 검증합니다.

1. **큐레이션 우선 사용자 흐름** (NON-NEGOTIABLE) — 핵심 작업 3 탭 이내
2. **디자인 시스템 일관성** — `design.md` 토큰 외 색상·간격·라운딩 금지
3. **로컬 우선 데이터 소유권** — Isar + 사용자 트리거 백업만; 외부 SDK·서버 동기화 금지
4. **Spec 주도 변경 관리** — spec/plan/tasks 산출물 없는 PR 금지

## PR 체크리스트 (T085)

PR 머지 전 모든 항목을 통과한다.

- [ ] `flutter analyze` — 경고 0
- [ ] `flutter test` — 단위·feature 테스트 통과
- [ ] `dart run tool/check_design_tokens.dart` — design.md ↔ tokens.dart 일치
- [ ] spec.md FR-NNN ↔ 코드 매핑 PR description에 첨부
- [ ] 헌법 4원칙 위반 없음 — 위반 시 plan.md `Complexity Tracking`에 정당화

## 후속 작업 (v1 → v1.1)

이 v1 MVP 이후의 task는 [`specs/001-home-dashboard/tasks.md`](specs/001-home-dashboard/tasks.md)와 후속 spec에서 관리됩니다.

- **폰트 자산 다운로드** — `assets/fonts/README.md` 가이드로 Manrope·Inter·Pretendard 추가
- **골든 테스트** — 디자인 시스템 위젯 회귀 가드 (폰트 자산 선행)
- **성능 시나리오** — 100점 옷 그리드 200ms 측정 (실기기/시뮬레이터 필요)
- **오프라인 시나리오** — `HttpOverrides`로 네트워크 격리 자동화
- **Spacing 토큰 정리** — 각 phase reviewer가 지적한 raw spacing 잔존을 모두 토큰화
- **Isar 통합 테스트** — in-memory `Isar.openSync`로 production repository를 검증하는 통합 테스트
- **알림 푸시 스케줄링** — 세탁 알림 토글의 실제 발송 (별도 spec)
- **iCloud / Google Drive 백업** — 진입점만 v1, 실제 백업/복원은 별도 spec
- **Isar 4.x 마이그레이션** — Rust 코어 release 시점

## 라이선스 / 자산

- 코드: 본 저장소 라이선스 정책에 따름.
- 폰트(Manrope · Inter · Pretendard): SIL OFL, 다운로드 가이드는 [`assets/fonts/README.md`](assets/fonts/README.md).
- 디자인 패키지의 의류 샘플 이미지는 개발 시드 전용이며 사용자 환경엔 자동 주입되지 않습니다.
