// image_picker가 카메라·사진 보관함을 열 때 iOS가 요구하는 사용 목적 문구가
// Info.plist에 있어야 한다. 없으면 접근 시 앱이 종료되고 심사에서 반려된다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  String valueOf(String key) {
    final match = RegExp(
      '<key>$key</key>\\s*<string>([^<]*)</string>',
    ).firstMatch(plist);
    expect(match, isNotNull, reason: '$key 가 Info.plist에 없다');
    return match!.group(1)!.trim();
  }

  test('카메라 사용 목적 문구가 있다', () {
    expect(valueOf('NSCameraUsageDescription'), isNotEmpty);
  });

  test('사진 보관함 사용 목적 문구가 있다', () {
    expect(valueOf('NSPhotoLibraryUsageDescription'), isNotEmpty);
  });
}
