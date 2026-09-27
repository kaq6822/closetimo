// 출시 설정(앱 ID·release 서명)이 결정 사항과 어긋나지 않는지 파일 단위로 검증한다.
// (#25 앱 ID 확정, QA F-01 / #11 release 빌드가 debug 키로 서명되던 결함 회귀 방지)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

const _appId = 'com.closetimo.app';

void main() {
  final gradle = _read('android/app/build.gradle.kts');

  test('Android namespace·applicationId는 확정된 앱 ID다', () {
    expect(gradle, contains('namespace = "$_appId"'));
    expect(gradle, contains('applicationId = "$_appId"'));
    expect(gradle, isNot(contains('TODO')));

    const activity =
        'android/app/src/main/kotlin/com/closetimo/app/MainActivity.kt';
    expect(_read(activity), startsWith('package $_appId\n'));
  });

  test('iOS 번들 ID는 Android 앱 ID와 같다', () {
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
        .allMatches(_read('ios/Runner.xcodeproj/project.pbxproj'))
        .map((m) => m.group(1))
        .toSet();
    expect(ids, {_appId, '$_appId.RunnerTests'});
  });

  test('release 서명은 key.properties의 업로드 키를 쓴다', () {
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('create("release")'));
    expect(
      gradle,
      contains('if (hasUploadKey) signingConfigs.getByName("release")'),
    );
    // 업로드 키가 없으면 스토어용 AAB 빌드는 실패해야 한다.
    expect(gradle, contains('it.name.startsWith("bundle")'));
    expect(gradle, contains('Release app bundle requires an upload key.'));
  });

  test('서명 비밀 파일은 저장소에서 무시된다', () {
    final ignore = _read('android/.gitignore');
    expect(ignore, contains('key.properties'));
    expect(ignore, contains('**/*.jks'));
    expect(File('android/key.properties.example').existsSync(), isTrue);
  });
}
