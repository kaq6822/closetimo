#!/usr/bin/env bash
# 옷장이모 Android 수동/탐색 QA 헬퍼. 실행하지 말고 source 해서 쓴다.
#
#   source tool/qa/android_qa.sh          # 기기 자동 선택(실기기 우선 → 에뮬레이터)
#   qa_install_release                     # release APK 클린 설치 + 콜드 스타트
#   descs; tap "옷장"; shot 01_wardrobe
#
# 설계 원칙 (docs/qa/android-qa-runbook.md §하네스 함정 참조):
#  - 모든 입력은 guard()를 통과해야 한다. 전면 앱이 대상 앱이 아니면 입력을 막는다.
#    (back 키로 앱이 종료되면 그 아래 사용자의 다른 앱에 탭·타이핑이 들어간 사고가 있었다)
#  - 키보드 닫기는 hide_kb()만 쓴다. 키보드가 없을 때 back은 화면 pop/앱 종료가 된다.
#  - 요소는 좌표가 아니라 content-desc로 찾는다(find_el). 스크롤·키보드로 좌표가 계속 바뀐다.

# zsh에서 source해도 "$c" 같은 좌표 인자가 bash처럼 단어 분리되게 한다.
[ -n "${ZSH_VERSION:-}" ] && setopt sh_word_split

PKG=com.closetimo.closetimo_app
QA_OUT="${QA_OUT:-build/android_qa}"
mkdir -p "$QA_OUT"

# ── 기기 선택 ─────────────────────────────────────────────
# 1) ANDROID_SERIAL이 지정돼 있으면 그대로 사용
# 2) USB 실기기(emulator-* 아닌 device) 우선
# 3) 실행 중인 에뮬레이터
# 4) 없으면 첫 번째 AVD를 android emulator start로 부팅
qa_pick_device() {
  if [ -n "${ANDROID_SERIAL:-}" ]; then echo "$ANDROID_SERIAL"; return; fi
  local real emu avd
  real=$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /^emulator-/ {print $1; exit}')
  if [ -n "$real" ]; then echo "$real"; return; fi
  emu=$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}')
  if [ -n "$emu" ]; then echo "$emu"; return; fi
  avd=${QA_AVD:-$(android emulator list 2>/dev/null | head -1)}
  [ -z "$avd" ] && { echo "no device and no AVD" >&2; return 1; }
  echo "starting emulator: $avd" >&2
  android emulator start "$avd" >&2 || return 1
  adb wait-for-device
  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do sleep 2; done
  adb devices | awk 'NR>1 && $2=="device" && $1 ~ /^emulator-/ {print $1; exit}'
}
ANDROID_SERIAL=$(qa_pick_device) || return 1 2>/dev/null || exit 1
[ -n "$ANDROID_SERIAL" ] || { echo "no device" >&2; return 1 2>/dev/null || exit 1; }
export ANDROID_SERIAL
echo "QA device: $ANDROID_SERIAL ($(adb shell getprop ro.product.model | tr -d '\r'), API $(adb shell getprop ro.build.version.sdk | tr -d '\r'))" >&2

# ── 안전 가드 ─────────────────────────────────────────────
# API 29+는 topResumedActivity, 그 미만은 mResumedActivity 줄에서 전면 패키지를 뽑는다.
fg_pkg() { adb shell dumpsys activity activities | sed -n -e 's/.*topResumedActivity=ActivityRecord{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' -e 's/.*mResumedActivity: ActivityRecord{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | head -1; }
# 사진 선택기는 허용(API 34 기기: com.google.android.photopicker, 구버전: media module).
# 카메라 등 추가 허용은 QA_ALLOW_PKG=<pkg> 로 1회성 지정.
guard() {
  local fg; fg=$(fg_pkg)
  case "$fg" in
    "$PKG"|com.google.android.photopicker|com.google.android.providers.media.module|com.android.providers.media.module|${QA_ALLOW_PKG:-__none__}) return 0 ;;
    *) echo "GUARD: foreground is '$fg' (not $PKG) — input blocked" >&2; return 1 ;;
  esac
}

# ── 관찰 ──────────────────────────────────────────────────
ui() { android layout --device="$ANDROID_SERIAL" 2>/dev/null; }
# 텍스트/설명이 있거나 클릭 가능한 요소를 한 줄씩: 'desc' [x,y] interactions state
descs() { ui | python3 -c 'import json,sys;[print(repr(e.get("content-desc") or e.get("text") or ""), e["center"], ",".join(e.get("interactions",[])), ",".join(e.get("state",[]))) for e in json.load(sys.stdin) if e.get("content-desc") or e.get("text") or "clickable" in e.get("interactions",[])]'; }
# find_el <pattern> [exact|contains] [index] → "x y"
find_el() {
  ui | python3 -c '
import json,sys
pat,mode,idx=sys.argv[1],sys.argv[2],int(sys.argv[3])
hits=[]
for e in json.load(sys.stdin):
    for k in ("content-desc","text"):
        v=e.get(k)
        if v is None: continue
        if (mode=="exact" and v==pat) or (mode=="contains" and pat in v):
            hits.append(e); break
if len(hits)<=idx: sys.exit(1)
x,y=json.loads(hits[idx]["center"]); print(x,y)
' "$1" "${2:-exact}" "${3:-0}"
}
has() { find_el "$1" "${2:-contains}" >/dev/null; }
shot() { android screen capture --device="$ANDROID_SERIAL" -o "$QA_OUT/$1.png" >/dev/null 2>&1 && echo "$QA_OUT/$1.png"; }
kb_shown() { adb shell dumpsys input_method | grep -q "mInputShown=true"; }
crashcheck() { adb logcat -d -b crash | tail -20; adb logcat -d | grep -E "FATAL EXCEPTION|E/flutter|Unhandled Exception" | tail -20; }

# ── 입력 (모두 guard 경유) ───────────────────────────────
tapxy() { guard || return 1; adb shell input tap "$1" "$2"; sleep "${TAP_WAIT:-1}"; }
tap() { local c; c=$(find_el "$@") || { echo "NOT FOUND: $1" >&2; return 1; }; tapxy $c; }
longpress() { local c; c=$(find_el "$@") || { echo "NOT FOUND: $1" >&2; return 1; }; guard || return 1; adb shell input swipe $c $c 900; sleep 1; }
# 토스트(2초)는 layout 덤프가 느려 놓치기 쉽다 → 탭 직후 즉시 캡처
tap_shot() { local c; c=$(find_el "$1" "${3:-exact}") || { echo "NOT FOUND: $1" >&2; return 1; }; guard || return 1; adb shell input tap $c; shot "$2"; }
back() { guard || return 1; adb shell input keyevent KEYCODE_BACK; sleep 1; }
hide_kb() { if kb_shown; then guard || return 1; adb shell input keyevent KEYCODE_BACK; sleep 0.8; fi; }
home() { guard || return 1; adb shell input keyevent KEYCODE_HOME; sleep 1; }
swipe() { guard || return 1; adb shell input swipe 540 "$1" 540 "$2" 600; sleep 1; }
# adb input text는 ASCII만 가능(한글 불가). 한글 경로는 integration_test(enterText)로 검증한다.
type_ascii() {
  case "$1" in *[!A-Za-z0-9\ ._-]*) echo "type_ascii: only [A-Za-z0-9 ._-] allowed" >&2; return 1 ;; esac
  kb_shown || { echo "NO FOCUSED FIELD" >&2; return 1; }; guard || return 1; adb shell input text "$(printf '%s' "$1" | sed 's/ /%s/g')"; sleep 0.8; }
# 포커스 필드 비우기 (Ctrl+A 조합은 Flutter에서 동작하지 않음)
clear_field() { guard || return 1; adb shell input keyevent KEYCODE_MOVE_END; adb shell input keyevent $(printf '67 %.0s' $(seq 1 ${1:-100})); sleep 0.5; }

# ── 앱 수명주기 ───────────────────────────────────────────
launch() { adb shell am start -W -n $PKG/.MainActivity | grep -E "TotalTime"; sleep 1.5; }
qa_install_release() {
  local apk=build/app/outputs/flutter-apk/app-release.apk
  # 이전 커밋 APK를 검증하지 않도록 항상 새로 빌드한다(QA_SKIP_BUILD=1이면 기존 APK 사용).
  if [ "${QA_SKIP_BUILD:-0}" != 1 ] || [ ! -f "$apk" ]; then flutter build apk --release || return 1; fi
  ls -l "$apk" | awk '{print "apk:", $6, $7, $8, $5" bytes"}'
  adb uninstall $PKG >/dev/null 2>&1
  adb logcat -c
  android install --device="$ANDROID_SERIAL" --apks="$apk" | tail -1
  launch
}

# ── 시나리오 매크로 ───────────────────────────────────────
# 주요 컨트롤은 접근성 라벨(#17)이 있어 tap "<라벨>"로 찾는다:
#   "옷 등록"(상단바 +), "뒤로 가기", "착용 횟수 줄이기"/"착용 횟수 늘리기",
#   "<옷 이름> 선택"(세탁 바구니 체크), 설정 스위치는 행 라벨("주간 세탁 알림" 등).
#
# 입력 필드만은 라벨로 찾을 수 없다. Flutter는 EditText의 라벨을 content-desc가 아닌
# hintText(TalkBack이 읽음)로 내보내는데, android layout·uiautomator 덤프에는 hint가 없다.
# 그래서 입력 필드는 위치 규칙으로 찾는다:
#   field_below <라벨>   화면의 필드 이름 텍스트 바로 아래 첫 입력 필드 → "x y"
field_below() {
  ui | python3 -c '
import json,sys
arg=sys.argv[1]
els=json.load(sys.stdin)
c=lambda e: json.loads(e["center"])
blank=[e for e in els if "clickable" in e.get("interactions",[]) and not (e.get("content-desc") or e.get("text"))]
ly=[c(e)[1] for e in els if e.get("content-desc")==arg or e.get("text")==arg]
hits=sorted([e for e in blank if ly and c(e)[1]>ly[0]], key=lambda e:c(e)[1])
if not hits: sys.exit(1)
print(*c(hits[0]))
' "$1"
}

# add_item <name> <brand|-> <category> <cycleDelta(+n/-n)>   (홈·옷장·세탁 탭에서 호출)
add_item() {
  tap "옷 등록" || return 1; sleep 0.5
  has "신규 옷 등록" || { echo "add screen not open" >&2; return 1; }
  tapxy $(field_below "의류 명칭") && type_ascii "$1" && hide_kb || return 1
  if [ "$2" != "-" ]; then tapxy $(field_below "브랜드") && type_ascii "$2" && hide_kb || return 1; fi
  swipe 1600 700
  local d=${4:-0} i
  for ((i=0;i<${d#-};i++)); do
    if [ "$d" -gt 0 ]; then tap "착용 횟수 늘리기" || return 1; else tap "착용 횟수 줄이기" || return 1; fi
  done
  tap "$3" exact 0 || return 1
  TAP_WAIT=0.2 tap "등록하기"
}
