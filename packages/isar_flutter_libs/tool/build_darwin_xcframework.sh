#!/usr/bin/env bash
set -euo pipefail

# Isar 3 정적 archive를 공개 C API만 노출하는 동적 XCFramework로 감싼다.
# 내부 MDBX/Rust 심볼을 숨겨 Isar Plus와 한 프로세스에서 충돌하지 않게 한다.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_dir="$(cd "$script_dir/.." && pwd)"
source_xcframework="$plugin_dir/ios/isar_flutter_libs/isar.xcframework"
output_xcframework="$plugin_dir/ios/isar_flutter_libs/isar_legacy.xcframework"

if [[ -e "$output_xcframework" ]]; then
  echo "Output already exists: $output_xcframework" >&2
  echo "Remove only that generated directory before rebuilding." >&2
  exit 1
fi

build_dir="$(mktemp -d "${TMPDIR:-/tmp}/isar_legacy_dynamic.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$build_dir/device" "$build_dir/simulator"

device_archive="$source_xcframework/ios-arm64/libisar.a"
simulator_archive="$source_xcframework/ios-arm64_x86_64-simulator/libisar.a"
exports_file="$build_dir/exports.txt"

nm -gU "$device_archive" 2>/dev/null \
  | awk '{print $NF}' \
  | grep '^_isar_' \
  | sort -u > "$exports_file"

xcrun --sdk iphoneos clang \
  -dynamiclib -arch arm64 -miphoneos-version-min=13.0 \
  -Wl,-force_load,"$device_archive" \
  -Wl,-exported_symbols_list,"$exports_file" \
  -Wl,-install_name,@rpath/libisar_legacy.dylib \
  -o "$build_dir/device/libisar_legacy.dylib" \
  -framework Security

for architecture in arm64 x86_64; do
  xcrun --sdk iphonesimulator clang \
    -dynamiclib -arch "$architecture" -mios-simulator-version-min=13.0 \
    -Wl,-force_load,"$simulator_archive" \
    -Wl,-exported_symbols_list,"$exports_file" \
    -Wl,-install_name,@rpath/libisar_legacy.dylib \
    -o "$build_dir/libisar_legacy_sim_${architecture}.dylib" \
    -framework Security
done

lipo -create \
  "$build_dir/libisar_legacy_sim_arm64.dylib" \
  "$build_dir/libisar_legacy_sim_x86_64.dylib" \
  -output "$build_dir/simulator/libisar_legacy.dylib"

xcodebuild -create-xcframework \
  -library "$build_dir/device/libisar_legacy.dylib" \
  -library "$build_dir/simulator/libisar_legacy.dylib" \
  -output "$output_xcframework"
