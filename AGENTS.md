# AGENTS.md — 옷장이모(Closetimo)

모든 AI 에이전트(Claude, Codex, Gemini 등)와 개발자가 공통으로 따르는 프로젝트 규칙이다.
하위 도메인 디렉토리(`lib/app`, `lib/core`, `lib/data`, `lib/features`)에는 해당 레이어 전용
AGENTS.md가 별도로 있으므로, 그 디렉토리에서 작업할 때 함께 참조한다.

## 프로젝트 개요

- **제품**: 옷장이모(Closetimo) — 큐레이팅하는 디지털 옷장 (옷장 관리 + 세탁 워크플로 MVP)
- **플랫폼**: Flutter 단일 코드베이스, iOS 13+ / Android API 24+ (휴대폰 폼팩터 한정)
- **아키텍처**: 로컬 우선(오프라인 동작), 백엔드 없음, 외부 SDK·분석 도구·서버 동기화 금지
- **기술 스택**: Dart 3.12+ / Flutter 3.44 stable, Isar Plus 1.3.x(로컬 NoSQL), Riverpod(상태 관리),
  go_router(라우팅), freezed(불변 모델), image_picker + path_provider(이미지), intl(ko 로케일)

## Spec 주도 개발

모든 변경은 spec 문서에 근거한다. 현재 활성 feature의 산출물:

- [specs/001-home-dashboard/plan.md](specs/001-home-dashboard/plan.md) — 구현 계획 (기술 컨텍스트, 프로젝트 구조, 명령어)
- [specs/001-home-dashboard/spec.md](specs/001-home-dashboard/spec.md) — 기능 요구사항 (FR/SC)
- [specs/001-home-dashboard/research.md](specs/001-home-dashboard/research.md) — 기술 결정
- [specs/001-home-dashboard/data-model.md](specs/001-home-dashboard/data-model.md) — Isar 스키마
- [specs/001-home-dashboard/contracts/routes.md](specs/001-home-dashboard/contracts/routes.md) — 네비게이션 계약
- [specs/001-home-dashboard/contracts/repositories.md](specs/001-home-dashboard/contracts/repositories.md) — 데이터 접근 계약
- [specs/001-home-dashboard/quickstart.md](specs/001-home-dashboard/quickstart.md) — 개발 환경 부트스트랩

## 언어 규칙

- **주석, 문서(README·spec·설계 문서), 커밋 메시지 본문 등 모든 서술형 텍스트는 한국어로 작성한다.**
  - dartdoc(`///`) 주석도 한국어로 작성한다.
  - 기술 용어와 코드 식별자(클래스명, 함수명, 변수명)는 원문(영문) 그대로 유지한다.
- **로그 메시지는 영문으로 작성한다.**
  - `debugPrint`, logger 호출, assert/Exception 메시지 등 런타임에 출력되는 문자열이 대상이다.
  - 예: `debugPrint('Failed to load image: $path');` (O) / `debugPrint('이미지 로드 실패');` (X)
- 사용자에게 노출되는 UI 문자열은 한국어 1차(`intl` ko 로케일)를 따른다. 로그 규칙과 혼동하지 말 것.

## 테스트 규칙

- **기능을 구현하거나 기존 코드를 수정한 뒤에는 반드시 해당 변경을 검증하는 테스트 코드를 작성한다.**
  - 새 기능: 동작을 검증하는 테스트를 함께 추가한다.
  - 버그 수정: 재발을 방지하는 회귀 테스트를 추가한다.
  - 기존 동작 변경: 영향을 받는 기존 테스트를 갱신한다.
- 테스트 배치:
  - `test/unit/` — 순수 로직 단위 테스트 (예: `date_formatter_test.dart`)
  - `test/feature/` — 화면·플로우 위젯 테스트 (예: `add_item_flow_test.dart`)
  - `integration_test/` — 실기기(시뮬레이터) E2E. `flutter drive`로 실행하며
    단계별 스크린샷을 남긴다. 실제 Isar를 쓰므로 실행 전 앱 삭제로 초기화한다.
- Isar 의존 테스트는 in-memory 인스턴스로 격리한다. 시간 의존 로직은 `lib/core/utils/clock.dart`를 주입해 고정한다.
- `test.skip` / `.only` / 빈 스텁 테스트는 완료 증거가 아니다. 남겨두지 말 것.

## 빌드 검증 규칙

- **코드 수정 및 기능 구현 이후에는 빌드하여 이상이 없는지 반드시 확인한다.** 최소 순서:

  ```bash
  # 1. 정적 분석 — 경고·에러 0이어야 한다
  flutter analyze

  # 2. 전체 테스트
  flutter test

  # 3. 빌드 확인 (플랫폼 중 하나 이상)
  flutter build ios --no-codesign --debug   # macOS
  flutter build apk --debug                 # Android
  ```

- 모델(`lib/data/models/`)이나 freezed 클래스를 수정한 경우 빌드 전에 코드 생성을 먼저 실행한다:

  ```bash
  dart run build_runner build
  ```

- analyze 경고, 테스트 실패, 빌드 실패가 남아 있는 상태로 작업을 완료로 보고하지 않는다.

## 자주 쓰는 명령어

```bash
flutter pub get                                        # 의존성 설치
dart run build_runner build                              # 코드 생성 (Isar Plus, freezed)
dart run build_runner watch                              # 개발 중 hot codegen
flutter run -d "iPhone 15"                             # iOS 시뮬레이터 실행
flutter analyze                                        # 정적 분석
flutter test                                           # 전체 테스트
flutter test test/unit/date_formatter_test.dart        # 단일 테스트 파일
dart run tool/check_design_tokens.dart                 # 디자인 토큰 하드코딩 검사
# 실기기 E2E (사전: xcrun simctl uninstall booted com.closetimo.closetimoApp)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/full_flow_verification_test.dart -d <device-id>
```

## 프로젝트 구조

```text
lib/
├── main.dart          # 엔트리 포인트
├── app/               # 앱 셸: 라우팅(go_router), 테마·디자인 토큰 → lib/app/AGENTS.md
├── core/              # 공용 인프라: 영속화, 유틸, 공용 위젯 → lib/core/AGENTS.md
├── data/              # 데이터 레이어: Isar 모델, repository, provider → lib/data/AGENTS.md
└── features/          # 화면 단위 기능 모듈 (home, wardrobe, …) → lib/features/AGENTS.md
test/
├── unit/              # 순수 로직 단위 테스트
├── feature/           # 화면·플로우 위젯 테스트
└── support/           # 테스트 인프라 (Isar native core 준비 등)
integration_test/      # 실기기 E2E (flutter drive + 스크린샷)
test_driver/           # integration_test 스크린샷 수집 드라이버
specs/                 # spec 주도 개발 산출물
tool/                  # 개발 보조 스크립트
```

## 공통 코드 규칙

- **디자인 토큰 일관성**: 색상·간격·라운딩·타이포는 `lib/app/theme/`의 토큰만 사용한다.
  위젯에서 하드코딩된 `Color(0x...)`, 임의 숫자 간격 사용 금지. `tool/check_design_tokens.dart`로 검사한다.
- **레이어 의존 방향**: `features → data → core`, `features → core`, `app → features`.
  역방향 의존(예: `core`가 `features`를 import) 금지.
- **로컬 우선**: 네트워크 호출, 외부 분석 SDK, 서버 동기화 코드를 추가하지 않는다 (프로젝트 헌법 III).
- 생성 파일(`*.g.dart`, `*.freezed.dart`)은 직접 수정하지 않는다. 원본 수정 후 build_runner를 실행한다.
