# Android 회귀 QA 리포트 — 2026-09-28

절차: [android-qa-runbook.md](../android-qa-runbook.md) · 직전 회차: [2026-09-27-android-prelaunch.md](2026-09-27-android-prelaunch.md)

## 1. 환경

| 항목 | 값 |
|---|---|
| 대상 커밋 | `010fb23` — **통합 브랜치** `qa/integration-2026-09-28`(로컬, 미머지). main `9585b04` + PR #29 `a8ecece`(#13) + PR #30 `73e14d4`(#11·#25) + PR #31 `0fe8f5a`(#14·#17·#22, 인수 잔여 D-1~D-3 포함) |
| 기기 | Samsung Galaxy A23 5G (SM-A235N), Android 14 / API 34, 1080×2408 — USB 실기기(R59T406SBPV), 로캘 ko-KR |
| 빌드 | 탐색 QA: `app-release.apk` 80.7MB(universal), `android/key.properties` 없음 → debug 키 서명 / E2E: debug, perf만 profile |
| 앱 ID | `com.closetimo.app` (본 회차 당시 기기에 구 ID `com.closetimo.closetimo_app` 설치본이 공존 — 이후 사용자 결정으로 lead가 제거, §7) |
| 도구 | Android CLI 1.0.15985488, Flutter 3.47.4 (AGENTS.md 명시 3.44와 다름, 직전 회차와 동일) |

## 2. 레이어별 결과

| 레이어 | 결과 | 비고 |
|---|---|---|
| L0 정적 | PASS | `flutter analyze` 0건, 디자인 토큰 13종 일치 |
| L1 단위·위젯 | PASS | 96개 통과 |
| L2 빌드 | PASS | release APK 성공(경고 배너 출력). 업로드 키 없는 `flutter build appbundle --release`는 "Release app bundle requires an upload key."로 실패(의도). 메타는 아래 |
| L3 자동 E2E | PASS | `tool/qa/run_android_e2e.sh` 4종 PASS, 스크린샷 30장. perf(profile): 첫 프레임 **65ms**, 스크롤 평균 **12.17ms/frame** |
| L4 탐색 QA | PASS (신규 P2 1·P3 2) | §4 체크리스트 전 항목 수행. 신규 결함 N-01~N-03 |
| L5 환경 변화 | PASS | 글꼴 1.3/2.0, 다크 모드, 가로, 백그라운드 kill 복원 — 크래시 0, 레이아웃 붕괴 없음 |

L2 APK 메타(aapt2·apksigner):
`package: name='com.closetimo.app' versionCode='1' versionName='1.0.0'`, `minSdkVersion:'24'`, `targetSdkVersion:'36'`,
`application-label:'Closetimo'`, `application-label-ko:'옷장이모'`, 권한은 `com.closetimo.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`뿐(`INTERNET` 없음 — 헌법 III),
서명 DN `C=US, O=Android, CN=Android Debug`(키 없는 로컬 빌드, 런북 §3 기준 QA용 무방).

측정치: 콜드 스타트(`force-stop` 후) **512~532ms**(첫 설치 직후 1672ms 제외), PSS 약 **142~143MB**(직전 130MB).
logcat crash 버퍼·`FATAL EXCEPTION`/`E/flutter` 전 구간 0건.

### L4 합격 항목

- 001 US1: 명칭 빈값·공백 3자만 입력 시 "저장"·"등록하기" 비활성, 정상 명칭 입력 시 활성. 카메라 열고 back 취소·앨범 열고 back 취소 → 등록 화면 복귀·크래시 없음. 앨범 선택 → 첨부 표시(`L4_01`). 세탁 주기 +5 → 10, 옷장 타일 0/10으로 동일. dirty back → "작성을 그만두시겠어요?" → 계속 작성/나가기. 토스트 "새 옷이 옷장에 등록됐어요"(`L4_02`)
- 001 US2: 칩 필터(상의 → Knit·Photo Tee) + **선택 칩 `selected` 노출**. 소문자 검색 "zara"(브랜드) → WoolCoat, "knit"(이름) → Knit, "xyz" → "검색 결과가 없습니다.". 정렬 3종: 착용 빈도순 Denim(2) → WoolCoat(1) → 나머지, 최근 착용순 WoolCoat(마지막) → Denim → 나머지, 상태순은 dirty Knit가 맨 뒤(동일 상태는 최신 등록 순). "깨끗함"(착용 0)·"세탁 필요"(1/1) 라벨. 검색→타일→back, 검색 포커스→"옷 등록"→back 모두 `mInputShown=false`
- 001 US3: 메모 85자 입력 → 80자에서 차단, "0자 남음"(`L4_03`). 기록 후 카운터 +1·토스트가 상단바 아래(`L4_04`). 주기 1인 Knit 1회 → 옷장 "세탁 필요 1/1". 기록 삭제 → 0/1·clean 복귀·토스트(`L4_05`). 메모 편집 → 카운터 2/5 불변(`L4_06`). 바구니 토글 → "바구니에서 제외"·상단 토스트(`L4_07`)
- 001 US4: 선택 0건이면 "선택 항목 세탁 완료 처리" 비활성, 체크 시 활성. 모두 선택 ↔ 선택 해제(4개 checked 전환). 3점 완료 → "3점의 세탁이 완료됐어요"·"세탁할 옷이 없어요."(`L4_11`), 옷장에서 0/3·0/5·0/10, 마지막 세탁 9/28
- 001 US5: 통계 6/6/0이 옷장과 일치(삭제 후 4). 신발·가방 → "기타" 2. 최근 입은 옷 2점, 바구니 미리보기 3점(4점 중)+전문가 팁(`L4_08`). 카테고리 카드(옷장 방문·스크롤 후) → 하의 필터 + 맨 위(`L4_09`). 설정 토글 변경 → `force-stop` → 재실행 시 설정 탭 복원·토글 유지
- 002: 수정 prefill(Knit/Uniqlo), 명칭 비우면 "저장"·"수정 완료" 비활성. 주기 1→2 변경 시 dirty(1/1) → 1/2 재평가 + "옷 정보를 수정했어요"(`L4_12`, N-02 참고). 삭제 다이얼로그 → 토스트 → 옷장·홈("기타" 0)·바구니에서 제거. 옷장 칩 필터 상태에서 들어간 상세 삭제 시 필터 유지(신발 칩 selected, 빈 결과 문구 `L4_13`)

스크린샷: `build/qa_full/`(L4 13장·L5 17장), E2E `build/android_verify_shots/`(30장). 런처 홈 화면 등 사용자 개인 화면은 캡처하지 않았다.

## 3. 결함

### 신규

| ID | 등급 | 요약 | 재현 절차 | 근거 | 상태 |
|---|---|---|---|---|---|
| N-01 | P2 | 접근성: 사진이 첨부된 상태의 사진 영역(탭하면 사진 교체/제거 시트)에 **라벨이 없음**. 사진이 없을 때만 "의류 사진 등록" 텍스트가 라벨 역할을 한다 | 등록 화면에서 앨범 사진 첨부 → `descs`에서 사진 영역이 `'' [540,638] clickable`. 사진 있는 옷의 수정 화면도 동일(`'' [540,927]`) | `lib/features/add_item/widgets/photo_picker_card.dart:124`(플레이스홀더 텍스트만 라벨), `L4_01` | 해결 (`bf71109`) — §7 재확인 |
| N-02 | P3 | F-12 잔여: 수정 저장 토스트 "옷 정보를 수정했어요"가 상세 화면 **하단**에 떠 "착용 기록하기" 버튼을 덮음. 수정 화면이 pop된 뒤 상세에 머무는 토스트인데 `ToastPlacement.top` 대상에서 빠짐. 토스트가 `IgnorePointer`라 탭은 통과한다 | 상세 → 메뉴 → 수정하기 → 값 변경 → 수정 완료 | `lib/features/add_item/add_item_screen.dart:204` `showClosetimoToast(context, message)`(기본 bottom), `L4_12` | 해결 (`bf71109`) — §7 재확인 |
| N-03 | P3 | 접근성: 세탁 바구니 타일의 상세 진입 노드가 `"가방 · 기계세탁, 착용 0/5, Tote 상세 보기"`로 **값이 라벨보다 먼저** 읽힘(TalkBack이 옷 이름을 마지막에 읽음) | 세탁 탭 → `descs` | `lib/features/laundry/widgets/laundry_tile.dart`(Semantics value/label), `android layout` | 해결 (`bf71109`) — §7 재확인 |

### 관찰 (결함 아님)

| ID | 내용 |
|---|---|
| O-1 | (재확인) 옷장 칩 필터 상태에서 **세탁 탭 경유**로 상세에 들어가 삭제하면 옷장 복귀 시 필터가 "전체"로 초기화된다. 가방 칩 selected → 세탁 → Tote 상세 → 삭제 → "전체" selected(`L4_10`). 쿼리 없는 `goNamed`가 `didUpdateWidget`에서 null로 반영된 결과로, PR #29 본문("홈·세탁에서 들어온 경우는 기존대로 goNamed")과 일치하고 spec 위반 아님 |
| O-2 | (재확인) lastTab은 하단 탭을 누를 때만 저장된다(`lib/app/router.dart` `_MainShell` onTap). 홈 탭 → 상의 카드로 옷장 진입 → back(앱 종료) → 재실행 시 **홈**으로 열린다 |
| O-3 | 홈 "관리 필요"는 dirty 옷만 센다. 세탁 바구니에 담긴 clean 옷 4점이 있어도 0. spec AC5-1에 정의가 없어 판단 보류 |
| O-4 | 다크 모드에서도 앱은 라이트 테마 그대로(직전 회차와 동일). 붕괴·대비 문제 없음 |
| O-5 | (§7에서 종결 — 사용자 결정으로 구 ID 제거) 구 ID `com.closetimo.closetimo_app`과 신 ID `com.closetimo.app`이 공존하면 런처에 **같은 이름 "옷장이모"·같은 아이콘이 2개** 보인다(두 패키지 모두 앱 정보 화면 라벨 "옷장이모" 확인). 데이터는 이전되지 않는다. 구 설치본 정리 여부는 사용자 결정 대기 |
| O-6 | 등록 dirty 다이얼로그에서 "계속 작성"을 누르면 명칭 필드에 포커스가 복원되며 키보드가 다시 뜬다. 자연스러운 동작이나 back 1회는 키보드만 닫는다(→ 런북 §6-16) |

## 4. 직전 회차 항목 재확인

| ID | 직전 상태 | 이번 결과 |
|---|---|---|
| F-01 (#11) | 해결 표기 | **해결 확인.** 업로드 키 없으면 AAB 빌드 실패, release APK는 경고 배너 + debug 서명(로컬 QA 전용). 실제 업로드 키 서명은 사용자 키가 없어 미검증 |
| F-02 (#12) | 해결 | **해결 확인.** aapt 라벨 Closetimo / ko 옷장이모, 기기 앱 정보 화면 "옷장이모" |
| #25 | 해결 | **해결 확인.** `com.closetimo.app`, versionCode 1 / versionName 1.0.0 |
| F-03 (#13) | 해결 | **해결 확인.** 옷장 방문·스크롤 후 홈 하의 카드 → 하의 selected + 맨 위. 옷장 필터 상태 상세 삭제 시 필터 유지 |
| F-04 (#14) | 해결 | **해결 확인.** 타일·"옷 등록" 경로 모두 back 후 `mInputShown=false` |
| F-07 (#17) | 해결(D-1~D-3 후속) | **해결 확인, 잔여 N-01·N-03.** 뒤로 가기·옷 등록·착용 횟수 줄이기/늘리기(주기 1에서 줄이기 비활성)·"<옷 이름> 선택" checkable/checked·설정 스위치 checkable/checked. D-1 옷장 칩·등록 화면 카테고리 칩 `selected` 노출. D-2 세탁 타일 "<옷 이름> 상세 보기" — 라벨 탭·이름 영역 탭·썸네일 탭 모두 상세 진입, 체크 탭은 선택만. D-3 설정 행 라벨 탭(`tap "오래 입지 않은 옷"`)으로 토글. 토스트 liveRegion은 덤프로 확인 불가(위젯 테스트 근거) |
| F-12 (#22) | 해결 | **해결 확인, 잔여 N-02.** 착용 기록·바구니 담기/제외·메모 수정·기록 삭제 토스트가 상단바 아래. IgnorePointer 재탭은 PR #31 인수에서 확인 |
| F-05 (#15) | 미해결 | 현상 동일 — 착용 기록 후 상세 화면 유지 |
| F-06 (#16) | 미해결 | 현상 동일 — "설정한 횟수만큼 착용하면 세탁 알림을 보냅니다." 문구, 알림 토글 3종, 눌리지 않는 "데이터 백업"·"개인정보 처리방침" |
| F-08 (#18) | 미해결 | 현상 동일 — 00:25~00:57에도 "좋은 아침입니다" |
| F-09 (#19) | 미해결 | 현상 동일 — "REQUIRED", "DRY CLEAN/MACHINE/HAND WASH", 글꼴 2.0에서 "MACHI/NE" 단어 중간 줄바꿈(`L5_font2.0_add_wash`) |
| F-10 (#20) | 결정 필요 | 현상 동일 — 가로 회전됨, 하단 탭이 화면 높이의 약 1/3(`L5_land_wardrobe`) |
| F-11 (#21) | 백로그 | 현상 동일 — 첫 타일이 fold 부근(y≈1788), 검색어 지우기 ✕ 없음 |
| F-13 (#23) | 백로그 | 현상 동일 — 사진 없는 옷은 단색 박스 |
| F-14 (#24) | 백로그 | 현상 동일 — 수정 화면에서 변경 없이도 "저장"·"수정 완료" 활성 |
| #26 | 경고 | 현상 동일 — 빌드 시 KGP 버전 지원 중단 경고 출력 |

## 5. 하네스 변경·함정

- 새 함정을 런북 §6에 추가했다(12~17): sips 크롭 오프셋, 상세 화면 스크롤 한계(착용 기록 약 7건 필요), 사진 첨부용 임시 이미지 push·삭제 절차와 다중 선택 선택기, 시트 위 좌표 탭이 scrim에 떨어지는 문제, "계속 작성" 후 키보드 재표시, 런처 이름은 앱 정보 화면 텍스트로 확인.
- §6-3의 세탁 타일 content-desc 설명을 실제 순서(값이 라벨 **앞**)로 바로잡았다.
- 런북 §3은 구 ID 설치본을 `adb uninstall`하라고 안내하지만, 본 회차 당시는 사용자 결정 대기 지시에 따라 제거하지 않았다. 이후 사용자 결정(제거)에 맞춰 §3 문구를 정리했다(§7).

## 6. 사고·환경 메모

- 기기 설정 원래 값(글꼴 1.0, 다크 모드 no, 자동 회전 1, user_rotation 0)을 기록 후 변경했고 모두 원래 값으로 복원했다.
- 앨범 선택 검증에 개인 사진이 쓰이지 않도록 E2E 스크린샷 1장(앱 화면)을 `/sdcard/Pictures/closetimo_qa_tmp.png`로 push·media scan해 골랐고, 첨부 직후 MediaStore 항목과 파일을 삭제했다(조회 결과 없음 확인). 선택기 화면은 캡처하지 않았다.
- 런처 라벨 확인에 시스템 설정의 앱 정보 화면을 열었고, 확인 후 설정 앱을 `force-stop`했다.
- O-2 확인 중 옷장 탭 back으로 앱이 종료됐을 때 이후 입력은 `launch`(am start)로만 재개했다(guard가 런처 입력 차단).
- 종료 시 신 ID `com.closetimo.app`은 제거했다. 구 ID `com.closetimo.closetimo_app`은 그대로 두었다.
- 로컬 Flutter 3.47.4가 `analysis_options.yaml`·`pubspec.lock`을 자동 수정해 매 단계 되돌렸다.

## 7. 재확인 — N-01~N-03 수정본 (2026-09-28)

### 7.1 환경

| 항목 | 값 |
|---|---|
| 대상 커밋 | `3e9c40a` — 통합 브랜치에 PR #31 `bf71109`(N-01~N-03 수정) 병합 |
| 기기 | **에뮬레이터** `emulator-5554` — `sdk_gphone64_arm64`, API 36, 1080×2400, 로캘 en-US |
| 빌드 | `app-release.apk` 80.7MB(debug 키 서명) / E2E: debug |

**에뮬레이터로 바꾼 이유**: 실기기 R59T406SBPV로 재확인을 시작했는데, 팀 잠금(`device.lock`)을 잡은 상태에서도
외부 세션이 같은 기기를 동시에 쓰고 있었다. 근거(logcat, 읽기 전용 확인):

- `18:21:55` `FATAL EXCEPTION: main` — `IllegalStateException: UiAutomationService ... already registered!`.
  UI 덤프가 동시에 두 개 돌아 uiautomator가 충돌했다(옷장이모 크래시 아님). 이 QA의 첫 `android layout`이 빈 출력이었던 원인으로 보인다.
- `18:22:24` `ActivityTaskManager: START ... cmp=com.cld.flutter.cld_flutter_app/.MainActivity ... from uid 2000` —
  이 QA가 보내지 않은 `adb shell` 실행으로 사용자의 다른 앱(`com.cld.flutter.cld_flutter_app`)이 전면에 왔다.

**외부 앱 입력 가능성**: 중단 직전 이 QA는 guard 통과 직후 `tap "의류 사진 등록"`(540,927) 1회를 보냈다.
전면 전환(18:22:24)과 시점이 거의 같아, 이 탭 1회가 외부 앱에 들어갔을 가능성을 **배제할 수 없다**.
이후 입력은 없었다(다음 `tap "앨범에서 선택"`은 요소를 찾지 못해 전송되지 않음). 사용자 결정으로 실기기 사용을 중단하고 잠금을 해제했다.
실기기에 남은 `com.closetimo.app`은 **다른 세션 사용 중이라 제거 보류**(lead가 나중에 정리). 실기기에 넣었던 임시 이미지는 중단 직후 삭제했다(조회 결과 없음).

에뮬레이터 사용 전에 `fg_pkg`(런처)와 logcat의 외부 `START`(없음)를 확인했고, 종료 시에도 외부 `START`·UiAutomation 충돌이 없었다.

### 7.2 결과 — PASS

| ID | 결과 | 근거 |
|---|---|---|
| N-01 | **해결 확인** | 등록 화면 사진 영역 content-desc: 첨부 전 `"의류 사진 등록"` → 앨범 첨부 후 `"의류 사진 변경"`(clickable). 사진 있는 옷의 수정 화면도 `"의류 사진 변경"`. 버튼 role은 `android layout`에 나오지 않아 코드(`Semantics(button: true)`, `photo_picker_card.dart`)로 확인. 임시 이미지는 첨부 후 MediaStore·파일에서 삭제(조회 결과 없음) |
| N-02 | **해결 확인** | 상세 → 수정하기 → 주기 +1 → 수정 완료: "옷 정보를 수정했어요"가 상단바 바로 아래(`build/qa_recheck/N02_edit_toast.png`), "착용 기록하기"와 겹치지 않음. 신규 등록 토스트 "새 옷이 옷장에 등록됐어요"는 하단 유지(`N02_register_toast_bottom.png`) |
| N-03 | **해결 확인** | 세탁 타일 content-desc `"Photo Tee 상세 보기, 상의 · 기계세탁, 착용 1/6"`(이름 → 분류·세탁법 → 착용 순). `tap "Photo Tee 상세 보기" contains`로 상세 진입 |
| 회귀 | PASS | `tool/qa/run_android_e2e.sh full_flow` → `full_flow_verification_test` PASS(스크린샷 22장). crash 0건 |

### 7.3 구 ID 설치본

- 사용자 결정으로 구 ID `com.closetimo.closetimo_app`을 제거하기로 했고, 실기기 설치본은 lead가 제거했다(O-5 종결).
  런북 §3 문구를 이 결정에 맞게 정리했다.
- 에뮬레이터 `emulator-5554`에도 구 ID 설치본이 있었으나 이번 지시 범위 밖이라 그대로 두었다.
- `com.closetimo.app`은 E2E(`flutter drive`) 종료 시 에뮬레이터에서 제거됐다.

### 7.4 하네스

- 런북 §6-14에 에뮬레이터 선택기(단일 선택) 차이를 추가했다.
- 런북 §6-18을 추가했다: 에뮬레이터는 소프트 키보드가 없어도 `mInputShown=true`라 `hide_kb`가 화면을 pop한다.
  이번 재확인에서는 세션에서 `hide_kb`만 `mIsInputViewShown` 기준으로 덮어써 진행했다.
- 런북 §6-19를 추가했다: 잠금 밖 외부 세션의 동시 사용을 탐지하는 절차.
