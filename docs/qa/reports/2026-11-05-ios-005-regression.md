# iOS 실기기 회귀 QA 리포트 — spec 005 포함 앱 전체 — 2026-11-05

같은 날 Android 회귀: [2026-11-05-android-005-regression.md](2026-11-05-android-005-regression.md)

## 1. 환경

| 항목 | 값 |
|---|---|
| 대상 커밋 | `8b285b2` (feat/005-wardrobe-attributes-ai, PR #57) — D-01 수정(`01c86b5`) 포함 |
| 기기 | iPhone 15 Pro (iPhone16,1), iOS 27.0.1 (24A446) — USB 실기기, ko-KR |
| 빌드 | E2E는 debug, `perf_wardrobe_test`만 profile. 최소 배포 버전 iOS 15.0 |
| 도구 | Flutter 3.44.6 stable, Xcode 27.2, `flutter drive` + `test_driver/integration_test.dart` |

## 2. 레이어별 결과

| 레이어 | 결과 | 근거 |
|---|---|---|
| L0 정적 | PASS | `flutter analyze` 0건 |
| L1 단위·위젯 | PASS | `flutter test` 476개 통과 |
| L3 자동 E2E | PASS | 6종 모두 통과(아래). 각 테스트 전 `xcrun devicectl device uninstall app`으로 앱 삭제 |
| L4 탐색 QA | 미실시 | iOS에는 Android CLI 같은 탐색 하네스가 없어 이번 회차는 E2E까지만 진행 |

| E2E | 결과 | 소요 |
|---|---|---|
| `full_flow_verification_test` | PASS | 178s |
| `offline_smoke_test` | PASS | 106s |
| `restart_persistence_test` | PASS | 86s |
| `backup_restore_test` | PASS | 81s |
| `attributes_vision_test` (`E2E_VISION_STRICT=true`) | PASS | 99s |
| `perf_wardrobe_test` (profile) | PASS | 98s |

## 3. 사진 분석 (iOS Vision·Foundation Models)

- 기능 확인: 배경 제거 true, 분류 true, 기기 내 AI `available`.
- 합성 티셔츠 이미지 → 배경 제거본 생성, 대표 색상 `[navy]`. 원본 사진 색상 `[navy, white]`.
- 기기 내 AI 응답: `top/tshirt [navy]` — 종류·세부 종류·색상 모두 맞음.
- 분류 라벨은 빈 값이었다(합성 이미지라 그런 것으로 보이며, 엄격 모드도 라벨은 검사하지 않음). 실제 사진 정확도는
  T019 측정(종류·세부 종류 9/11)을 따른다.

## 4. 성능 (profile, 옷 100벌, 5회 반복)

- SC-004 조건 변경→화면 반영: 8개 시나리오 중앙값 18.4~19.0ms, 최대 23.7ms(예산 200ms) — 모두 PASS.
  Android A23 같은 날 최대 66.8ms.
- 검색 갱신 프레임 중앙값 1.08ms, 스크롤 9프레임 중 60fps 초과 0%.

## 5. 결함·관찰

| ID | 등급 | 요약 | 상태 |
|---|---|---|---|
| O-9 | 하네스 | `005_08_settings_photo` 스크린샷에 설정 맨 위(알림)만 찍히고 사진 분석 항목은 화면 밖이다. 판정은 통과지만 스크린샷으로 확인할 수 없다 | 관찰 |

앱 결함 0건, 크래시 0건.

## 6. 정리

- 기기에는 마지막 `perf_wardrobe_test`의 profile 빌드(`com.closetimo.app`)가 남아 있다.
- 스크린샷 50장: `build/ios_verify_shots/`, 로그: `build/ios_qa/`(Git 추적 대상 아님).
