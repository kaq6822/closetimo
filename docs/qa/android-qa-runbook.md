# Android QA 런북 — 옷장이모

Android 기기에서 출시 전(또는 회귀) QA를 수행하는 에이전트·개발자용 절차서다.
사람이 없어도 에이전트가 이 문서만 읽고 같은 품질로 QA를 반복할 수 있도록 쓴다.
회차별 결과는 [reports/](reports/)에 남기고, 이 문서는 **절차와 함정**만 담는다.

## 0. 먼저 읽을 것

| 목적 | 문서 |
|---|---|
| 합격 기준(FR/SC/AC) | [specs/001-home-dashboard/spec.md](../../specs/001-home-dashboard/spec.md), [specs/002-item-edit-delete/spec.md](../../specs/002-item-edit-delete/spec.md) |
| 화면 전환 계약 | [contracts/routes.md](../../specs/001-home-dashboard/contracts/routes.md) |
| 직전 회차 결과·미해결 결함 | [reports/](reports/) 최신 파일 |

직전 리포트의 "미해결" 항목은 이번 회차에서 **반드시 재확인**한다(회귀 여부 판정).

## 1. 기기 선택 규칙

1. `ANDROID_SERIAL`이 지정되어 있으면 그 기기를 쓴다.
2. USB 실기기(`adb devices`에서 `emulator-*`가 아닌 `device`)를 우선한다.
   — 저사양 실기기에서만 드러나는 타이밍·성능 문제가 있다(§6 함정 5).
3. 실기기가 없으면 실행 중인 에뮬레이터, 그것도 없으면 `android emulator list`의 첫 AVD를
   `android emulator start <avd>`로 부팅한다(`QA_AVD`로 지정 가능).

이 규칙은 `tool/qa/android_qa.sh`의 `qa_pick_device`에 구현되어 있다. 직접 고르지 말고 헬퍼를 source한다.

> 실기기는 **사용자의 개인 폰**일 수 있다. 다른 앱·갤러리·설정을 건드리지 않는다(§6 함정 1, 2, 7).

## 2. QA 레이어와 실행 순서

앞 레이어가 실패하면 뒤로 가지 않는다.

| 레이어 | 명령 | 합격 기준 |
|---|---|---|
| L0 정적 | `flutter analyze` · `dart run tool/check_design_tokens.dart` | 경고 0, 토큰 일치 |
| L1 단위·위젯 | `flutter test` | 전부 통과 |
| L2 빌드 | `flutter build apk --release` | 성공. APK 메타 점검(§3) |
| L3 자동 E2E | `tool/qa/run_android_e2e.sh` | 4종 PASS, perf는 profile 수치로 판정 |
| L4 탐색 QA | `source tool/qa/android_qa.sh` 후 §4 체크리스트 | 결함은 리포트에 P0~P3로 기록 |
| L5 환경 변화 | §5 | 크래시 0, 레이아웃 붕괴 없음 |

## 3. release APK 점검 (L2)

```bash
AAPT=$(ls -d ~/Library/Android/sdk/build-tools/*/ | tail -1)aapt2
$AAPT dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "^package|targetSdk|application-label"
$AAPT dump permissions build/app/outputs/flutter-apk/app-release.apk
grep -n signingConfig android/app/build.gradle.kts
```

- `application-label`이 제품명(옷장이모)인지 — 런처 아이콘 아래 표시되는 이름이다.
- 권한에 `INTERNET`이 **없어야** 한다(헌법 III 로컬 우선). 있으면 P0.
- release `signingConfig`가 debug 키면 스토어 업로드 불가 → P0(출시 차단).
- `versionCode`/`versionName`이 이번 출시 값인지.

## 4. 탐색 QA 체크리스트 (L4)

`source tool/qa/android_qa.sh && qa_install_release` 로 클린 설치 후 순서대로 진행한다.
각 항목은 spec 근거를 갖는다. 결과는 PASS/FAIL/관찰로 리포트에 기록한다.

### 등록 (001 US1)
- [ ] 명칭 비었을 때 "저장"·"등록하기" 비활성(`descs`에서 clickable 없음) — FR-002
- [ ] 공백만 입력해도 비활성
- [ ] 사진: 앨범 선택 → 첨부 표시, 카메라/앨범 **취소** 시 크래시 없음 — FR-001/003
- [ ] 세탁 주기 +/− 반영, 등록 후 상세에서 동일 값 — AC1-3
- [ ] dirty 상태 back → "작성을 그만두시겠어요?" 다이얼로그 — routes §4
- [ ] 등록 토스트 "새 옷이 옷장에 등록됐어요", 그리드 최상단 노출 — AC1-1, FR-004

### 옷장 (001 US2)
- [ ] 카테고리 칩 필터 — AC2-1
- [ ] 검색: 소문자로 이름·브랜드 매칭, 없는 단어 → "검색 결과가 없습니다." — FR-006, AC2-2
- [ ] 정렬 3종 순서 — FR-007
- [ ] "깨끗함"(착용 0) / "세탁 필요"(dirty) 라벨 — FR-008
- [ ] 검색 후 상세 갔다가 돌아왔을 때 키보드가 다시 뜨지 않는지

### 상세·착용 (001 US3)
- [ ] 착용 기록 시트: 80자에서 입력 차단 + 80/80 — edge case
- [ ] 기록 후 카운터 +1, 토스트 "오늘의 착용이 기록되었어요" — AC3-1
- [ ] 주기 도달 시 dirty → 옷장 "세탁 필요" — AC3-3, FR-011 (주기 1 옷은 1회에 전환)
- [ ] 타임라인 long-press → 메모 편집(카운터 불변) / 기록 삭제(카운터 −1, 상태 복귀) — FR-010a/b
- [ ] 세탁 바구니 토글 → 라벨 "바구니에서 제외" + 토스트 — AC3-4

### 세탁 (001 US4)
- [ ] 선택 0건이면 완료 버튼 비활성 — AC4-3
- [ ] 모두 선택 ↔ 선택 해제 토글 — AC4-2
- [ ] N점 완료 → "N점의 세탁이 완료됐어요", 목록에서 제거, 0/N·clean — AC4-1
- [ ] 빈 바구니 "세탁할 옷이 없어요." — AC4-4

### 홈·설정 (001 US5)
- [ ] 통계(전체/깨끗/관리 필요)가 옷장과 일치 — AC5-1
- [ ] 카테고리 카드 탭 → 옷장 + 해당 필터. **옷장 탭을 한 번 연 뒤에도** 확인 — AC5-2, FR-019
- [ ] 신발·가방 등은 "기타" 카드에 합산 — edge case
- [ ] 최근 입은 옷 ≤2, 세탁 바구니 미리보기 ≤3 + 팁 — FR-020/021
- [ ] 토글 변경 → `am force-stop` → 재실행 시 유지, 마지막 탭 복원 — AC5-3, SC-005

### 수정·삭제 (002)
- [ ] 수정 prefill, 명칭 비우면 "수정 완료" 비활성 — 002 FR-001/003
- [ ] 세탁 주기 변경 시 상태 재평가(dirty↔clean) + "옷 정보를 수정했어요" — 002 FR-004/006
- [ ] 삭제 확인 다이얼로그 → "옷을 옷장에서 삭제했어요" → 옷장·홈·바구니에서 사라짐 — 002 FR-009/012

### 공통
- [ ] 각 단계 후 `crashcheck` 출력이 비어 있음
- [ ] 콜드 스타트 `TotalTime`(첫 설치 직후 값 제외) 기록

## 5. 환경 변화 (L5)

기기 설정을 바꾸기 전에 **원래 값을 기록**하고 끝나면 반드시 복원한다.

```bash
# 원래 값 기록
FS=$(adb shell settings get system font_scale | tr -d '\r')
NM=$(adb shell cmd uimode night | awk '{print $3}')                 # yes/no/auto
AR=$(adb shell settings get system accelerometer_rotation | tr -d '\r')
UR=$(adb shell settings get system user_rotation | tr -d '\r')
# 변경
adb shell settings put system font_scale 1.3        # 이후 2.0
adb shell cmd uimode night yes                       # 다크 모드
adb shell settings put system accelerometer_rotation 0; adb shell settings put system user_rotation 1   # 가로
# 복원 (기록한 값으로)
adb shell settings put system font_scale "$FS"; adb shell cmd uimode night "$NM"
adb shell settings put system user_rotation "${UR/null/0}"; adb shell settings put system accelerometer_rotation "$AR"
```

- 백그라운드 복원: 앱에서 `home`(헬퍼) → `adb shell am kill com.closetimo.closetimo_app` → `launch` → 마지막 탭·데이터 확인.
- 메모리: `adb shell dumpsys meminfo com.closetimo.closetimo_app | grep "TOTAL PSS"`.

## 6. 하네스 함정 (실제 사고에서 나온 규칙)

1. **입력 전 전면 앱 확인.** 옷장 탭에서 back은 앱을 종료한다. 종료 후 보낸 탭·텍스트·back이
   그 아래 있던 사용자의 다른 앱에 들어간 사고가 있었다. → 모든 입력은 `guard()`를 거친다.
   카메라 등 외부 앱에 입력이 필요하면 `QA_ALLOW_PKG=<pkg>`로 1회만 허용한다.
2. **키보드 닫기에 back을 쓰지 말 것.** 키보드가 없으면 back은 화면 pop/앱 종료다. → `hide_kb()`.
3. **좌표 대신 content-desc.** 키보드·스크롤로 좌표가 계속 바뀐다(세탁 주기 +를 다른 요소에 탭한 사례).
   → `tap "<라벨>"`. 상단바 `+`("옷 등록")·뒤로("뒤로 가기")·세탁 주기 ±("착용 횟수 줄이기/늘리기")·
   세탁 바구니 체크("<옷 이름> 선택")·설정 알림(행 라벨 "세탁 알림" 등, 행 전체 탭으로 토글)은
   접근성 라벨로 찾는다(#17). 세탁 바구니 타일의 상세 진입은 `tap "<옷 이름> 상세 보기" contains`다
   (content-desc 뒤에 분류·착용 값이 붙는다). 카테고리 칩은 라벨 + `selected` 상태로 노출된다.
   사진 영역은 "의류 사진 등록"(사진 없음) / "의류 사진 변경"(첨부됨)이다.
   **입력 필드만 예외**다. Flutter는 EditText의 라벨을 content-desc가 아닌 hintText로 내보낸다.
   TalkBack은 이 값을 읽지만 `android layout`·`uiautomator dump`에는 나오지 않는다.
   그래서 필드는 `field_below "<필드 이름>"`(이름 텍스트 바로 아래 첫 입력 필드)으로 찾는다.
   필드 값이 `text`로 노출되므로 `tap "<부분 문자열>" contains`는 입력한 검색어와도 매칭될 수 있다.
   타일처럼 필드에 없는 고유 문자열(예: "마지막 세탁")을 쓴다.
4. **키보드가 떠 있는 상태의 swipe는 키 길게 누르기가 된다.** 삼성 키보드에서 '6' 롱프레스로 '⅚'가
   입력된 사례. → swipe 전 `hide_kb`.
5. **실기기 E2E의 Isar 스트림 지연.** 실제 Isar `watch`는 비동기 I/O라 `pumpAndSettle`이 기다리지 않는다.
   저사양 기기에서만 실패한다. → `integration_test/support/e2e_helpers.dart`의 `pumpUntilFound`.
6. **Android 스크린샷은 surface 변환 필요.** `takeScreenshot` 전 `convertFlutterSurfaceToImage()` 미호출 시
   `StateError`. → `takeShot()` 헬퍼가 처리한다.
7. **개인 갤러리.** 사진 선택기에는 사용자의 실제 사진이 보인다. 인물·개인 정보가 없는 이미지(스크린샷 등)를
   고르고, 스크린샷 파일을 외부에 공유하지 않는다.
8. **토스트는 2초.** `descs`(layout 덤프)는 1초 이상 걸려 놓치기 쉽다. → `tap_shot`으로 탭 직후 캡처.
9. **한글 입력 불가.** `adb shell input text`는 ASCII만 된다. Ctrl+A 조합도 Flutter 필드에서 동작하지 않는다.
   → 탐색 QA는 ASCII 데이터로, 한글 입력·검색은 L3 E2E(`enterText`)로 검증한다. 필드 비우기는 `clear_field`.
10. **성능은 profile로만.** `flutter drive` 기본은 debug(JIT)라 수치가 5~10배 나쁘다(766ms vs 62ms 실측).
11. **Flutter 버전 드리프트.** 로컬 SDK가 AGENTS.md 명시 버전과 다르면 `flutter analyze`/`pub get`이
    `analysis_options.yaml`·`pubspec.lock`을 자동 수정한다. QA 종료 시 `git status`로 확인하고
    의도하지 않은 변경은 되돌린다.

## 7. 결함 등급

| 등급 | 기준 | 출시 |
|---|---|---|
| P0 | 출시 불가(스토어 업로드 차단, 데이터 손실, 크래시, 헌법 위반) | 차단 |
| P1 | spec FR/AC 위반으로 핵심 흐름이 틀리게 동작 | 수정 후 출시 권장 |
| P2 | spec과 불일치하는 문서/UX 오해 소지, 접근성 결함 | 출시 후 빠른 패치 가능 |
| P3 | 미관·문구·개선 제안 | 백로그 |

## 8. 리포트 작성

`docs/qa/reports/YYYY-MM-DD-android-<목적>.md`로 저장한다. 필수 섹션:

1. 환경: 커밋 해시, 기기(모델·API·해상도), 빌드 종류, Flutter 버전
2. 레이어별 결과(L0~L5) — 명령과 수치
3. 결함 표: ID · 등급 · 요약 · 재현 절차 · 근거(파일:라인/스크린샷) · 상태
4. 직전 회차 미해결 항목의 재확인 결과
5. 하네스 자체의 변경·새로 발견한 함정(→ 이 런북 §6에 반영)
