// #20 — 세로 고정 설정이 Dart/Android/iOS에 모두 반영되어 있는지 검사한다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main.dart가 세로 고정을 요청한다', () {
    final src = File('lib/main.dart').readAsStringSync();
    expect(src, contains('setPreferredOrientations'));
    expect(src, contains('DeviceOrientation.portraitUp'));
  });

  test('Android manifest의 MainActivity가 portrait 고정이다', () {
    final src = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(src, contains('android:screenOrientation="portrait"'));
  });

  test('iOS iPhone 방향 목록에 가로가 없다', () {
    final src = File('ios/Runner/Info.plist').readAsStringSync();
    final start = src.indexOf('<key>UISupportedInterfaceOrientations</key>');
    final end = src.indexOf('</array>', start);
    final block = src.substring(start, end);
    expect(block, contains('UIInterfaceOrientationPortrait'));
    expect(block, isNot(contains('Landscape')));
  });
}
