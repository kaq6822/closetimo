// 플랫폼 런처 이름 설정이 로케일 규칙과 어긋나지 않는지 파일 단위로 검증한다.
// (QA F-02 / #12 회귀 방지: 런처에 "closetimo_app"이 노출되던 결함)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('Android 런처 이름은 문자열 리소스를 쓴다', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:label="@string/app_name"'));

    const res = 'android/app/src/main/res';
    expect(
      _read('$res/values/strings.xml'),
      contains('<string name="app_name">Closetimo</string>'),
    );
    expect(
      _read('$res/values-ko/strings.xml'),
      contains('<string name="app_name">옷장이모</string>'),
    );
  });

  test('iOS 기본 이름은 Closetimo, 한국어는 옷장이모', () {
    final plist = _read('ios/Runner/Info.plist');
    expect(
      plist,
      matches(
        RegExp(r'<key>CFBundleDisplayName</key>\s*<string>Closetimo</string>'),
      ),
    );

    final ko = _read('ios/Runner/ko.lproj/InfoPlist.strings');
    expect(ko, contains('"CFBundleDisplayName" = "옷장이모";'));

    // InfoPlist.strings가 빌드 리소스로 등록되지 않으면 로컬라이즈가 적용되지 않는다.
    final pbx = _read('ios/Runner.xcodeproj/project.pbxproj');
    expect(pbx, contains('path = ko.lproj/InfoPlist.strings;'));
    expect(pbx, contains('InfoPlist.strings in Resources */,'));
  });
}
