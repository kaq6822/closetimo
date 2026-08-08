// integration_test 스크린샷 수집 드라이버.
// `flutter drive --driver=test_driver/integration_test.dart` 로 실행하면
// 테스트 중 촬영한 스크린샷을 build/ios_verify_shots/ 아래에 저장한다.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('build/ios_verify_shots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
