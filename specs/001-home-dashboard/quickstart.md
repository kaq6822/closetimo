# Quickstart: 옷장이모 MVP 개발 환경 부트스트랩

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 개발자가 로컬에서 옷장이모 MVP를 빌드·실행·테스트할 수 있도록 안내한다. 본 문서의 단계는 `tasks.md`(`/speckit-tasks` 산출물)의 Phase 1: Setup의 기반이다.

---

## 1. 사전 요구사항

| 도구 | 버전 | 설치 검증 |
|---|---|---|
| Flutter SDK | 3.27.x stable | `flutter --version` |
| Dart | 3.5+ (Flutter 번들) | `dart --version` |
| Xcode | 15+ (iOS 빌드) | `xcodebuild -version` |
| CocoaPods | 1.15+ | `pod --version` |
| Android Studio | Hedgehog 2023.1+ (또는 cmdline-tools 11+) | `sdkmanager --version` |
| Android SDK | API 34 (compile) / API 21+ (min) | `sdkmanager --list` |
| Ruby | 3.0+ (CocoaPods용) | `ruby --version` |

`flutter doctor`에서 모든 항목 ✓일 것.

---

## 2. 의존성 설치

```bash
# 1. 패키지
flutter pub get

# 2. 코드 생성 (isar collections, freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 3. iOS 의존성 (macOS에서만)
cd ios && pod install && cd -
```

코드 생성 산출물:
- `lib/data/models/*.g.dart` — Isar 컬렉션 어댑터
- `lib/features/**/forms/*.freezed.dart` — 폼 state
- `assets/tips/laundry_tips.g.dart` — 팁 풀 직렬화 (선택)

개발 중 hot codegen이 필요한 경우 별도 터미널에서:

```bash
dart run build_runner watch --delete-conflicting-outputs
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

첫 실행 시 sandbox에 Isar DB 파일(`closetimo.isar` + `.lock`)이 생성된다. 위치:
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

# 통합(integration_test) — emulator·simulator 필요
flutter test integration_test/

# 특정 user story 흐름만
flutter test integration_test/add_item_flow_test.dart
```

테스트 시 Isar는 메모리 인스턴스를 사용(`test/helpers/isar_test_helper.dart`).

---

## 6. 변경사항 검증 체크리스트 (PR 전)

1. `flutter analyze` — 경고 0
2. `dart format --set-exit-if-changed .` — 포맷 일관
3. `flutter test` — 단위·위젯·골든 통과
4. `flutter test integration_test/` — E2E 통과
5. spec.md의 변경된 FR이 있는 경우 본 plan과 contracts/ 갱신
6. `.specify/memory/constitution.md`의 4개 원칙 위반 없음 확인

---

## 7. 자주 만나는 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `Isar.openSync()` 에서 `dylib not found` (macOS dev) | `flutter pub get` 후 `flutter run` 1회 실행해 isar_flutter_libs를 캐시. |
| 빌드 시 `.g.dart` 파일 충돌 | `dart run build_runner build --delete-conflicting-outputs` |
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
