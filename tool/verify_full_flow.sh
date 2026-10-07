#!/bin/sh
# 전용 iOS Simulator에서 초기화 → 준비 → 프로세스 종료 → 복원을 검증한다.
set -eu
device_id="${1:?Provide a dedicated iOS Simulator UDID}"
bundle_id=com.closetimo.closetimoApp
# 물리 기기 ID는 simctl에 존재하지 않으므로 초기화 전에 실패한다.
xcrun simctl bootstatus "$device_id" -b
if xcrun simctl get_app_container "$device_id" "$bundle_id" app >/dev/null 2>&1; then
  xcrun simctl uninstall "$device_id" "$bundle_id"
fi
flutter drive --keep-app-running --driver=test_driver/integration_test.dart \
  --target=integration_test/full_flow_verification_test.dart \
  --dart-define=E2E_PREPARE_RESTART=true -d "$device_id"
# Flutter drive의 기본 종료 경로는 앱을 삭제하므로 keep-app-running을 사용한다.
# 앱을 설치한 상태로 유지한 뒤 프로세스만 강제 종료한다.
xcrun simctl terminate "$device_id" "$bundle_id"
flutter drive --keep-app-running --driver=test_driver/integration_test.dart \
  --target=integration_test/full_flow_verification_test.dart \
  --dart-define=E2E_VERIFY_RESTART=true -d "$device_id"
