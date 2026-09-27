#!/usr/bin/env bash
# 옷장이모 Android E2E 러너 — integration_test 4종을 실기기(없으면 에뮬레이터)에서 순차 실행한다.
#
#   tool/qa/run_android_e2e.sh                # 전체
#   tool/qa/run_android_e2e.sh full_flow      # 이름에 full_flow가 들어간 테스트만
#   ANDROID_SERIAL=<serial> tool/qa/run_android_e2e.sh
#
# - 각 테스트 전에 앱을 삭제한다(테스트가 빈 Isar를 전제로 함).
# - perf_wardrobe_test는 --profile로 실행한다. debug(JIT) 수치는 SC-004 판정에 쓰지 않는다.
# - 스크린샷: build/android_verify_shots/, 로그: build/android_qa/e2e_<test>.log
set -uo pipefail
cd "$(dirname "$0")/../.."

# 기기 선택 로직은 수동 QA 헬퍼와 공유한다.
# shellcheck source=tool/qa/android_qa.sh
source tool/qa/android_qa.sh >/dev/null || exit 1

PKG=com.closetimo.closetimo_app
LOG_DIR=build/android_qa
export SHOTS_DIR=build/android_verify_shots
mkdir -p "$LOG_DIR"
rm -rf "$SHOTS_DIR"

TESTS=(full_flow_verification_test offline_smoke_test restart_persistence_test perf_wardrobe_test)
FILTER="${1:-}"
fail=0
ran=0
for t in "${TESTS[@]}"; do
  [[ -n "$FILTER" && "$t" != *"$FILTER"* ]] && continue
  ran=$((ran+1))
  mode=()
  [[ "$t" == perf_* ]] && mode=(--profile)
  adb uninstall "$PKG" >/dev/null 2>&1
  printf '%-32s ' "$t"
  if flutter drive ${mode[@]+"${mode[@]}"} --driver=test_driver/integration_test.dart \
      --target="integration_test/$t.dart" -d "$ANDROID_SERIAL" >"$LOG_DIR/e2e_$t.log" 2>&1; then
    echo "PASS $(grep -hoE 'Wardrobe first frame after tap: [0-9]+ms|Average frame time during scroll: [0-9.]+ms' "$LOG_DIR/e2e_$t.log" | tr '\n' ' ')"
  else
    echo "FAIL (see $LOG_DIR/e2e_$t.log)"
    grep -E "Expected:|Actual:|_test.dart:[0-9]+" "$LOG_DIR/e2e_$t.log" | head -4 | sed 's/^/    /'
    fail=1
  fi
done
[ "$ran" -eq 0 ] && { echo "no test matched '$FILTER'" >&2; exit 2; }
echo "screenshots: $SHOTS_DIR ($(ls "$SHOTS_DIR" 2>/dev/null | wc -l | tr -d ' ') files)"
exit $fail
