# Android 출시 전 QA 리포트 — 2026-09-27

절차: [android-qa-runbook.md](../android-qa-runbook.md)

## 1. 환경

| 항목 | 값 |
|---|---|
| 커밋 | `72c37bd` (main) + 이번 회차 하네스 변경 |
| 기기 | Samsung Galaxy A23 5G (SM-A235N), Android 14 / API 34, 1080×2408, 450dpi — USB 실기기 |
| 빌드 | 탐색 QA: `app-release.apk` (80.5MB, universal) / E2E: debug, perf만 profile |
| 도구 | Android CLI 1.0.15985488, Flutter 3.47.4 (AGENTS.md 명시 3.44와 다름 → §5) |

## 2. 레이어별 결과

| 레이어 | 결과 | 비고 |
|---|---|---|
| L0 정적 | PASS | analyze 0건, 디자인 토큰 13종 일치 |
| L1 단위·위젯 | PASS | 67개 통과 |
| L2 빌드 | PASS, 단 **P0 2건** | release 빌드 성공. 서명·런처 라벨 결함(F-01, F-02) |
| L3 자동 E2E | PASS (하네스 수정 후) | 4종 통과. 수정 전에는 Android에서 전부 실패(§4) |
| L4 탐색 QA | FAIL 1건(P1) | 홈 카테고리 카드 필터(F-03) |
| L5 환경 변화 | PASS | 글꼴 1.3/2.0, 다크 모드, 가로, 프로세스 kill 복원 — 크래시 0 |

측정치: 콜드 스타트 554~700ms(첫 설치 직후 1.97s 제외), PSS 약 130MB,
옷장 100점 첫 프레임 **45~62ms**·스크롤 평균 **11.9~15.4ms/frame**(profile 3회, SC-004 기준 200ms 충족).
`tool/qa/run_android_e2e.sh` 최종 실행(리뷰 반영 후): 4종 PASS, 스크린샷 30장.
debug 모드 측정치(766ms)는 판정에 쓰지 않았다.

### 합격 항목 요약

- 001 US1: 명칭 빈값·공백만 입력 시 비활성, 사진 첨부/카메라·앨범 취소, 주기 +5 → 10 반영, dirty-back 다이얼로그, 등록 토스트·최상단 노출
- 001 US2: 카테고리 칩 필터, 소문자 이름·브랜드 검색, 빈 결과 문구, 정렬 3종, 깨끗함/세탁 필요 라벨
- 001 US3: 메모 80자 차단(80/80), 착용 +1·토스트, 주기 도달 dirty(주기 1은 1회에 즉시), 메모 편집(카운터 불변), 기록 삭제(카운터 −1·clean 복귀), 바구니 토글
- 001 US4: 0건 비활성, 모두 선택↔선택 해제, "2점의 세탁이 완료됐어요", 빈 바구니 문구
- 001 US5: 통계·카테고리 합산(신발→기타), 최근 입은 옷 2점, 바구니 미리보기+팁, 토글·마지막 탭·데이터가 `force-stop` 후 유지(SC-005)
- 002: 수정 prefill, 주기 변경 시 dirty→clean 재평가·토스트, 삭제 다이얼로그·토스트·전 화면에서 제거
- 헌법 III: release APK에 `INTERNET` 권한 자체가 없음(오프라인 구조적 보장)

## 3. 결함

| ID | 등급 | 요약 | 근거 | 상태 |
|---|---|---|---|---|
| F-01 | P0 | release 빌드가 **debug 키로 서명**됨. Play 업로드 불가 | `android/app/build.gradle.kts` `buildTypes.release.signingConfig = debug` | 해결 (#11) — `key.properties` 업로드 키 서명, 키 없으면 AAB 빌드 실패. 실제 업로드 키 생성·Play App Signing 등록은 사용자 작업으로 남음 |
| F-02 | P0 | 런처 앱 이름이 `closetimo_app` | `android/app/src/main/AndroidManifest.xml` `android:label`; aapt `application-label:'closetimo_app'`. iOS `CFBundleDisplayName`도 "Closetimo App" | 해결 — ko "옷장이모"·그 외 "Closetimo" 로케일별 적용 (#12). release 빌드 재검증: aapt `application-label:'Closetimo'`, `application-label-ko:'옷장이모'` |
| F-03 | P1 | 옷장 탭을 한 번 연 뒤에는 홈 카테고리 카드가 **필터를 적용하지 못함**(전체 목록 + 이전 스크롤 위치) — FR-019/AC5-2 위반 | `lib/features/wardrobe/wardrobe_screen.dart:26` `late _category = widget.initialCategory`가 최초 1회만 평가되고 `didUpdateWidget` 없음. `StatefulShellRoute.indexedStack`이 State를 보존. 관련 테스트 없음 | 해결 (#13) |
| F-04 | P2 | 검색창 포커스 상태로 상세 진입 → 복귀 시 **키보드가 자동으로 다시 올라와** 그리드를 가림 | 재현: 옷장 검색창 탭 → 키보드 닫기 → 타일 탭 → back → `mInputShown=true` | 해결 (#14) — 검색 필드 `onTapOutside` 포커스 해제. A23에서 재현 절차 후 `mInputShown=false` |
| F-05 | P2 | spec 드리프트: 착용 기록 후 상세 화면 **유지**로 변경됐으나 spec AC3-1·routes.md §3·tasks T054는 "직전 화면으로 pop" | 커밋 `33068f3`. 코드가 의도된 동작이면 spec 갱신 필요 | 미해결 (#15) |
| F-06 | P2 | v1에 없는 기능을 약속하는 UI: 등록 화면 "설정한 횟수만큼 착용하면 세탁 알림을 보냅니다.", 알림 토글 3종(발송 구현·권한 없음), chevron만 있고 눌리지 않는 "데이터 백업"·"개인정보 처리방침" | `add_item_screen.dart:295`, `settings_screen.dart:90-91`, README "후속 작업" | 미해결 (#16) |
| F-07 | P2 | 접근성: 상단 `+`, 입력 필드, 세탁 주기 ±, 세탁 바구니 체크박스, 설정 스위치에 라벨 없음(TalkBack이 이름 없이 읽음). 체크 상태 미노출. 토스트는 live region 아님 | `android layout`에서 `content-desc` 빈 값 | 해결 (#17) — 라벨·checked·toggled·liveRegion 추가. A23 `android layout`에서 +·뒤로·±·체크·스위치 content-desc 확인(입력 필드는 hintText로 노출돼 덤프에는 안 보임). 인수 잔여 D-1~D-3(칩 selected, 세탁 타일 "<옷 이름> 상세 보기", 설정 행 전체 탭 토글) 후속 반영. 통합 QA N-01(첨부 사진 영역 "의류 사진 변경")·N-03(세탁 타일 이름 먼저 낭독) 반영 |
| F-08 | P3 | 홈 인사말이 시간과 무관하게 "좋은 아침입니다" | `home_screen.dart:58` | 미해결 (#18) |
| F-09 | P3 | 영문 라벨 혼재: "REQUIRED", "DRY CLEAN/MACHINE/HAND WASH"(상세에선 "기계세탁"). 글꼴 2.0에서 "MACHI/NE" 단어 중간 줄바꿈 | `add_item_screen.dart:399`, `lib/data/models/item.dart:104-106` | 미해결 (#19) |
| F-10 | P3 | 세로 고정 안 됨. 가로에서 하단 탭이 화면 1/3 차지(폰 전용 제품) | `setPreferredOrientations` 호출 없음 | 결정 필요 (#20) |
| F-11 | P3 | 옷장 첫 타일이 화면 하단(fold)에서 시작. 검색어 지우기(✕) 없음 | 스크린샷 | 백로그 (#21) |
| F-12 | P3 | 상세 화면 토스트가 방금 누른 버튼 위를 덮음(`bottom: 100` 고정) | `lib/core/widgets/toast.dart` | 해결 (#22) — 상세 화면에 머무는 토스트를 상단바 아래로 배치(`ToastPlacement.top`). A23에서 버튼 비겹침 확인. 통합 QA N-02(수정 저장 토스트도 상단) 반영 |
| F-13 | P3 | 사진 없는 옷의 플레이스홀더가 단색 박스. `assets/images/upload-placeholder.png`는 미사용 | `hero_image.dart:79`, `garment_tile.dart:150` | 백로그 (#23) |
| F-14 | P3 | 수정 화면에서 변경이 없어도 "저장" 활성 | — | 백로그 (#24) |

출시 전 결정 필요: `applicationId`가 `com.closetimo.closetimo_app`(Gradle TODO 주석 잔존). 스토어 게시 후 변경 불가. (#25) → 해결: Android `applicationId`·iOS 번들 ID 모두 `com.closetimo.app`으로 확정.

빌드 경고: Kotlin Gradle Plugin 2.2.20(`android/settings.gradle.kts:23`)에 대해 Flutter가 "곧 지원 중단, 2.3.20 이상으로 올릴 것"을 경고한다. 출시 차단은 아니지만 SDK 업그레이드 전에 처리할 것. (#26)

참고: universal APK 80.5MB는 3개 ABI 합산이다. 스토어는 AAB(`flutter build appbundle`)로 올리면 기기별로 약 1/3 크기가 된다.
`libisar.so`와 `libisar_plus.so`가 함께 들어있는 것은 spec 003 레거시 마이그레이션용으로 의도된 것이다.

## 4. 하네스 변경

| 변경 | 이유 |
|---|---|
| `integration_test/support/e2e_helpers.dart` 신설: `takeShot`, `pumpUntilFound` | Android는 `convertFlutterSurfaceToImage()` 없이 촬영 시 `StateError`로 4종 모두 실패. 실기기 Isar 스트림 지연으로 검색 단계 플레이키 |
| E2E 3종이 공용 `takeShot` 사용, 검색 직후 `pumpUntilFound` | 위와 동일 |
| `test_driver/integration_test.dart`: `SHOTS_DIR` 환경변수 | iOS/Android 스크린샷 분리(기본값은 기존 `build/ios_verify_shots` 유지) |
| `tool/qa/android_qa.sh` | 기기 자동 선택, 전면 앱 가드, content-desc 탭, 토스트 캡처 등 탐색 QA 헬퍼 |
| `tool/qa/run_android_e2e.sh` | E2E 4종 순차 실행, 테스트별 앱 초기화, perf만 profile |
| 독립 리뷰 반영 | 항상 새 APK 빌드, 에뮬레이터 부팅 대기·빈 시리얼 차단, zsh 단어 분리, `hide_kb` 실패 전파, `home` 헬퍼, `type_ascii` 메타문자 차단, 필터 불일치 시 exit 2, 검색 단계 부정→양성 순서 검증 |

## 5. 사고·환경 메모

- **다른 앱 입력 사고**: 초기 임시 헬퍼가 키보드가 없는 상태에서 back을 보내 옷장이모가 종료됐고,
  이어진 탭 1회·텍스트 "Uniqlo"·back·스와이프가 그 아래 있던 사용자의 다른 앱(`com.cld.flutter.cld_flutter_app`)에
  입력됐다. 새 Activity 시작 로그는 없었으나 해당 앱의 상태 변경 여부는 확인하지 못했다.
  재발 방지로 `guard()`·`hide_kb()`를 도입했다(런북 §6 함정 1·2).
- 기기 설정(글꼴 크기 1.0, 다크 모드 off, 자동 회전 on)은 테스트 후 원래 값으로 복원했다.
- 로컬 Flutter 3.47.4가 `analysis_options.yaml`(exclude 3줄 추가)과 `pubspec.lock`(SDK 고정 패키지 5종)을
  자동 수정했다. 이번 회차 변경에서는 제외하고 되돌렸다. 팀 SDK 버전을 AGENTS.md와 맞추거나 문서를 갱신할 것.
