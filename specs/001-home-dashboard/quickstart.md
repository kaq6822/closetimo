# Quickstart: 옷장이모 MVP 개발 환경 부트스트랩

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 개발자가 로컬에서 옷장이모 MVP를 빌드·실행·테스트할 수 있도록 안내한다. 본 문서의 단계는 `tasks.md`(`/speckit-tasks` 산출물)의 Phase 1: Setup의 기반이다.

---

## 1. 사전 요구사항

| 도구 | 버전 | 설치 검증 |
|---|---|---|
| Flutter SDK | 3.44.x stable | `flutter --version` |
| Dart | 3.12+ (Flutter 번들) | `dart --version` |
| Xcode | 15+ (iOS 빌드) | `xcodebuild -version` |
| Android Studio | Hedgehog 2023.1+ (또는 cmdline-tools 11+) | `sdkmanager --version` |
| Android SDK | API 36 (compile) / API 24+ (min) | `sdkmanager --list` |

`flutter doctor`에서 모든 항목 ✓일 것.

---

## 2. 의존성 설치

```bash
# 1. 패키지
flutter pub get

# 2. 코드 생성 (isar collections, freezed, json_serializable)
dart run build_runner build
```

코드 생성 산출물:
- `lib/data/models/*.g.dart` — Isar 컬렉션 어댑터
- `lib/features/**/forms/*.freezed.dart` — 폼 state
- `assets/tips/laundry_tips.g.dart` — 팁 풀 직렬화 (선택)

개발 중 hot codegen이 필요한 경우 별도 터미널에서:

```bash
dart run build_runner watch
```

---

## 3. 실행

```bash
# iOS 시뮬레이터 (iPhone 15)
flutter run -d "iPhone 15"

# Android 에뮬레이터
flutter run -d <android-device-id>

# 데모 시드 데이터 포함 (개발 빌드 전용)
flutter run --dart-define=SEED_DEMO=true
```

첫 실행 시 sandbox에 주 저장소(`closetimo_plus.isar` + `.lock`)가 생성된다. 업데이트
설치에서는 기존 `closetimo.isar`를 읽어 새 저장소로 이전하되 원본 파일은 보존한다. 위치:
- iOS: `<simulator>/data/Containers/Data/Application/<UUID>/Documents/`
- Android: `/data/data/com.closetimo.app/files/`

앱 ID는 Android `applicationId`·iOS 번들 ID 모두 `com.closetimo.app`이다(스토어 게시 후 변경 불가).
스토어용 release 빌드(`flutter build appbundle`)는 업로드 키가 필요하다 —
[docs/release/android-signing.md](../../docs/release/android-signing.md).

---

## 4. 디자인 시스템 검증

`design.md`의 토큰 → `lib/app/theme/tokens.dart` 매핑과 하드코딩 여부를 확인:

```bash
# 색상 토큰 일치(핵심 13색) + lib/ 하드코딩 간격 검사 (헌법 II 가드)
dart run tool/check_design_tokens.dart
```

검사 로직은 `tool/design_token_check.dart`에 있고, 정상·위반 사례는
`test/unit/design_token_check_test.dart`가 검증한다. 스캔 대상은
`EdgeInsets.*` 인자, `SizedBox(height|width:)`, `GridView`/`Wrap`의 간격 이름자다.
계산값(키보드 inset)과 주석·간격이 아닌 숫자(행간격, 맵 키)는 검사 대상이 아니다.

위젯 골든 테스트(헌법 II 회귀 가드):

```bash
flutter test test/widget/design_system_golden_test.dart --update-goldens  # 의도된 디자인 변경 시
flutter test test/widget/design_system_golden_test.dart                  # PR 검증 시
```

골든은 폰트(Manrope/Inter/Pretendard + MaterialIcons)·화면 크기·픽셀 밀도·테마·
로케일을 `test/widget/golden_harness.dart`가 고정한다. 기준 이미지를 갱신한 뒤에는
**육안으로 확인**하고 일반 `flutter test`에서도 통과하는지 확인한다.

---

## 5. 테스트 실행

```bash
# 단위 + 위젯 + 골든
flutter test

# 통합(E2E) — emulator·simulator 필요. 실제 Isar 저장소를 사용하므로
# 결정적 결과를 위해 실행 전 앱을 삭제해 빈 상태에서 시작한다.
xcrun simctl uninstall booted com.closetimo.app   # iOS 시뮬레이터 기준
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/full_flow_verification_test.dart \
  -d <device-id>
```

통합 테스트 4종과 각각의 검증 범위:

| target | 검증 대상 | 범위 한계 |
|---|---|---|
| `full_flow_verification_test.dart` | 등록→옷장→상세(착용·메모)→세탁→설정→수정→삭제, 단계별 스크린샷 | SC-006 사용자 성공률은 증명하지 못함 |
| `restart_persistence_test.dart` | 위젯 트리 제거·재구성 후 파일 저장소·마지막 탭 복원 | 실제 프로세스 종료는 `tool/verify_full_flow.sh`로 별도 검증 |
| `offline_smoke_test.dart` | Dart HTTP 차단 상태에서 핵심 5작업 (SC-007) | OS 비행기 모드 전체 오프라인과 동일한 증거가 아님 |
| `perf_wardrobe_test.dart` | 100점 기준 검색·필터·정렬 지연 + 프레임 (SC-004/T080) | profile 빌드는 **실기기에만** 가능. 시뮬레이터는 debug 모드로만 실행된다 |

스크린샷은 `build/ios_verify_shots/`에 저장된다(UI 육안 검증용). 성능 리포트는
앱 Documents 및 호스트 `build/verification/perf_wardrobe_report.txt`에 기록된다. 호스트 리포트는 앱 삭제 이후에도 보존된다.

> 사용자 개인 데이터가 있는 실기기는 임의로 앱을 삭제(초기화)하지 않는다.
> 성능 검증은 시드를 100건 삽입하므로 빈 상태의 전용 테스트 기기에서 수행한다. 공식 성능 판정은 실기기 profile 모드로 실행한다.

테스트 시 Isar Plus는 임시 디렉토리 인스턴스를 사용하고, 최초 실행에 native test core를
시스템 임시 디렉토리에 준비한다(`test/support/isar_plus_test_support.dart`).

---

## 6. 변경사항 검증 체크리스트 (PR 전)

1. `flutter analyze` — 경고 0
2. `dart format --set-exit-if-changed .` — 포맷 일관
3. `flutter test` — 단위·위젯·골든 통과
4. `dart run tool/check_design_tokens.dart` — 색상 토큰 일치 + 하드코딩 간격 0건
5. `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/full_flow_verification_test.dart` — E2E 통과
6. `flutter build ios --no-codesign --debug` — 빌드 통과 (Android 변경 시 `flutter build apk --debug`)
7. spec.md의 변경된 FR이 있는 경우 본 plan과 contracts/ 갱신
8. `.specify/memory/constitution.md`의 4개 원칙 위반 없음 확인

---

## 7. 자주 만나는 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| 테스트에서 Isar Plus native core 준비 실패 | 네트워크와 Xcode Command Line Tools의 `clang` 사용 가능 여부 확인 후 `flutter test -j 1` 재실행 |
| 빌드 시 `.g.dart` 파일 충돌 | 생성 파일을 직접 수정하지 말고 원본 모델 수정 후 `dart run build_runner build` |
| iOS 빌드 `min iOS version` 경고 | `ios/Podfile`의 `platform :ios, '13.0'` 확인 (iOS 의존성은 SwiftPM만 사용하므로 `pod install`이 필요 없다) |
| profile 모드 빌드 실패 (시뮬레이터) | Flutter는 시뮬레이터에서 profile/release 빌드를 지원하지 않는다. 성능 판정은 실기기에서 `--profile`로 실행한다 |
| Android Pretendard 폰트가 적용되지 않음 | `pubspec.yaml`의 `fonts:` 섹션에 `Pretendard-Regular.otf` 누락 여부 확인 |
| 한국어 텍스트가 깨짐 | `MaterialApp`의 `localizationsDelegates`에 `GlobalMaterialLocalizations.delegate`, `supportedLocales`에 `Locale('ko', 'KR')` 포함 확인 |

---

## 8. 첫 실행 후 검증 시나리오 (수동)

1. 앱 실행 → `/home` 진입, 통계 0/0/0 표시 → 헤더 "좋은 아침입니다, 큐레이터님" 노출.
2. 우상단 `+` 탭 → `/add-item` → 명칭 "테스트 코트" 입력 → 카테고리 "아우터" 선택 → "등록하기" → 토스트 "새 옷이 옷장에 등록됐어요" → `/wardrobe` 또는 직전 화면으로 자동 복귀.
3. `/wardrobe` 진입 → 방금 등록한 옷이 그리드 최상단에 표시되고 "깨끗함" 라벨 보임.
4. 옷 타일 탭 → 상세 진입 → "착용 기록하기" → 시트의 "기록" 확정 → 토스트 노출 → 카운터 1/5(washCycle 기본 5) 표시.
5. 4번을 4회 추가 반복 → 5/5 도달 시 상태가 `dirty`로 전환되고 "세탁 필요" 라벨로 변경.
6. 상세에서 "세탁 바구니" 토글 → 토스트 "세탁 바구니에 담겼어요" → 상세에서 뒤로 이동 → 하단 탭 `/laundry` 진입 → 옷 표시 → 체크 → "선택 항목 세탁 완료 처리" → 카운터 0/5로 초기화, 상태 `clean` 복원.
7. 앱 강제 종료 → 재실행 → 모든 데이터·마지막 탭 보존 확인.

위 시나리오는 spec.md의 SC-001/003/005/007에 대응되며, `integration_test/`로 자동화된다.
SC-006(첫 사용자 성공률 90%)은 자동화로 증명할 수 없어 사용자 평가가 필요하다.

---

## 9. 2026-10-07 검증 결과

- 환경: Flutter 3.44.6 / Dart 3.12.2, iPhone 17 Pro · iOS 26.5 시뮬레이터
- 자동화: `flutter analyze` 경고·오류 0건, `flutter test` 102개 통과,
  `dart run tool/check_design_tokens.dart` 통과(색상 13개 일치 + 하드코딩 간격 0건)
- 빌드: iOS `flutter build ios --no-codesign --debug` 성공(`Runner.app` 생성)
- T077 골든: 기준 PNG 14개 생성·육안 확인, 일반 `flutter test`에서 통과 확인.
  색상/간격 토큰을 의도적으로 바꾸면 골든이 실패하는 것까지 확인했다.
- T081 오프라인: 시뮬레이터에서 5작업 통과, 차단된 Dart HTTP 요청 0건,
  스크린샷 8장(`build/ios_verify_shots/0*_offline_*.png`).
  Dart HTTP 경로만 차단하므로 비행기 모드 검증과는 구분된다.
- T083 전체 흐름: 시뮬레이터에서 22단계 통과, 스크린샷 23장
  (`build/ios_verify_shots/`).
- T080 성능: 구형 성능 테스트는 debug 모드에서 복제 필터 로직의 중앙값 0.22~0.92ms가
  측정되었다. 이 측정은 복제 로직의 계산 시간으로 SC-004 통과 증거에서 제외한다. 그리드 sliver lazy화 병목 수정으로 첫 프레임 74.9ms → 20.9ms.
  **단, profile 빌드가 시뮬레이터에서 불가능해 최종 성능 판정은 미완료다.**

**Status**: 환경 부트스트랩 절차 확정. T080의 profile 모드 판정·SC-006 사용자
평가·OS 비행기 모드 검증은 미완료 항목이다.

## 10. 리뷰 후 검증 경로 보완 (2026-10-07)

간격 검사기는 정확한 생성자 괄호 범위로 이름자 EdgeInsets와 다중 행 SizedBox를 검사한다. 기존 검사에서 누락된 32건은 동일 치수의 토큰으로 교체했다. 새로운 회귀 테스트는 주석·문자열·중첩 호출·원본 줄 번호도 검증한다.

전체 흐름의 강제 종료·재실행 검증은 전용 시뮬레이터에서 다음 명령으로 실행한다. 이 명령은 해당 시뮬레이터의 앱 데이터를 초기화한다.

```bash
sh tool/verify_full_flow.sh <simulator-udid>
```

첫 실행은 등록→착용 6회→dirty→세탁→설정 변경을 수행하고, 두 번째 프로세스 실행은 마지막 탭·설정·의류·이벤트 복원 후 수정·삭제를 수행한다. 동일 프로세스의 위젯 재생성이나 hot restart를 강제 종료 검증으로 대체하지 않는다.

성능 테스트는 실제 화면 조건 변경과 production 스트림을 사용하고, 이전 결과를 오인하지 않도록 매 표본 전에 무결과 상태로 바꾼다. 5회 표본의 최댓값을 판정한다. 시뮬레이터 debug 결과는 경로 동작 확인이며 최종 성능 통과를 의미하지 않는다.

리뷰 후 전체 흐름 검증에서 준비 실행과 재실행 모두 통과했다(iPhone 17 Pro / iOS 26.5 Simulator). 준비 실행은 주기 도달 시 dirty 라벨과 세탁 초기화를 확인했고, 재실행에서는 `source=alreadyMigrated, items=1, events=7` 및 마지막 탭·알림 설정·의류·메모·이벤트 assertion이 통과했다. 근거 스크린샷은 `build/ios_verify_shots/11b_wardrobe_dirty.png`, `restart_01_before_terminate.png`, `restart_02_restored_settings.png`이다.

보완한 성능 테스트는 동일 시뮬레이터의 debug 모드에서 통과했다. 100점·8개 조건·각 5회이며, UI 반영 중앙값 범위는 41.28~47.17ms, 전체 최댓값은 90.59ms였다. 검색 갱신 프레임 totalSpan 최댓값은 28.92ms, 스크롤 UI/raster 작업의 16.67ms 예산 초과 표본은 0/19였다. totalSpan의 역수로 FPS를 추정하지 않는다. 이 수치는 debug 경로 검증이며 T080의 전용 실기기 profile 판정은 미완료다. 호스트 리포트 `build/verification/perf_wardrobe_report.txt`는 드라이버가 앱 종료·삭제 전에 수집했다.

최종 검증은 코드 수정 후 순서대로 실행했다. 디자인 토큰 검사 통과, `flutter analyze` 경고·오류 0건, `flutter test` 106개 통과(골든 포함), `flutter build ios --no-codesign --debug` 성공(`build/ios/iphoneos/Runner.app`)이다. 마지막 타일 아래 탭바 회피 여백을 검증하는 스크롤 회귀 테스트도 포함한다. 로그는 `build/verification/review_{tokens,analyze,tests,build}.log`에 보존했다.
