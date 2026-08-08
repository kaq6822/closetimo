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
- Android: `/data/data/com.example.closetimo/files/`

---

## 4. 디자인 시스템 검증

`design.md`의 토큰 → `lib/app/theme/tokens.dart` 매핑이 1:1인지 확인:

```bash
# 토큰 누락·오타 검증 스크립트 (Phase 1 task에서 추가됨)
dart run tool/check_design_tokens.dart
```

위젯 골든 테스트(헌법 II 회귀 가드):

```bash
flutter test --update-goldens   # 의도된 디자인 변경 시
flutter test                    # PR 검증 시
```

---

## 5. 테스트 실행

```bash
# 단위 + 위젯 + 골든
flutter test

# 통합(E2E) — emulator·simulator 필요. 실제 Isar 저장소를 사용하므로
# 결정적 결과를 위해 실행 전 앱을 삭제해 빈 상태에서 시작한다.
xcrun simctl uninstall booted com.closetimo.closetimoApp   # iOS 시뮬레이터 기준
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/full_flow_verification_test.dart \
  -d <device-id>
```

통합 테스트는 등록→옷장→상세(착용·세탁)→세탁 완료→설정→수정→삭제 전 여정을
순회하며 단계별 스크린샷을 `build/ios_verify_shots/`에 저장한다(UI 육안 검증용).

테스트 시 Isar Plus는 임시 디렉토리 인스턴스를 사용하고, 최초 실행에 native test core를
시스템 임시 디렉토리에 준비한다(`test/support/isar_plus_test_support.dart`).

---

## 6. 변경사항 검증 체크리스트 (PR 전)

1. `flutter analyze` — 경고 0
2. `dart format --set-exit-if-changed .` — 포맷 일관
3. `flutter test` — 단위·위젯·골든 통과
4. `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/full_flow_verification_test.dart` — E2E 통과
5. spec.md의 변경된 FR이 있는 경우 본 plan과 contracts/ 갱신
6. `.specify/memory/constitution.md`의 4개 원칙 위반 없음 확인

---

## 7. 자주 만나는 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| 테스트에서 Isar Plus native core 준비 실패 | 네트워크와 Xcode Command Line Tools의 `clang` 사용 가능 여부 확인 후 `flutter test -j 1` 재실행 |
| 빌드 시 `.g.dart` 파일 충돌 | 생성 파일을 직접 수정하지 말고 원본 모델 수정 후 `dart run build_runner build` |
| iOS 빌드 `min iOS version` 경고 | `ios/Podfile`의 `platform :ios, '13.0'` 확인 |
| Android Pretendard 폰트가 적용되지 않음 | `pubspec.yaml`의 `fonts:` 섹션에 `Pretendard-Regular.otf` 누락 여부 확인 |
| 한국어 텍스트가 깨짐 | `MaterialApp`의 `localizationsDelegates`에 `GlobalMaterialLocalizations.delegate`, `supportedLocales`에 `Locale('ko', 'KR')` 포함 확인 |

---

## 8. 첫 실행 후 검증 시나리오 (수동)

1. 앱 실행 → `/home` 진입, 통계 0/0/0 표시 → 헤더 "좋은 아침입니다, 큐레이터님" 노출.
2. 우상단 `+` 탭 → `/add-item` → 명칭 "테스트 코트" 입력 → 카테고리 "아우터" 선택 → "등록하기" → 토스트 "새 옷이 옷장에 등록됐어요" → `/wardrobe` 또는 직전 화면으로 자동 복귀.
3. `/wardrobe` 진입 → 방금 등록한 옷이 그리드 최상단에 표시되고 "깨끗함" 라벨 보임.
4. 옷 타일 탭 → 상세 진입 → "착용 기록하기" 1회 탭 → 토스트 노출 → 카운터 1/5(washCycle 기본 5) 표시.
5. 4번을 4회 추가 반복 → 5/5 도달 시 상태가 `dirty`로 전환되고 "세탁 필요" 라벨로 변경.
6. 상세에서 "세탁 바구니" 토글 → 토스트 "세탁 바구니에 담겼어요" → 하단 탭 `/laundry` 진입 → 옷 표시 → 체크 → "선택 항목 세탁 완료 처리" → 카운터 0/5로 초기화, 상태 `clean` 복원.
7. 앱 강제 종료 → 재실행 → 모든 데이터·마지막 탭 보존 확인.

위 시나리오는 spec.md의 SC-001/003/005/006/007에 대응되며, integration_test로 자동화된다.

---

**Status**: 환경 부트스트랩 절차 확정.
