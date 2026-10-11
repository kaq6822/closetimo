// integration_test 공용 헬퍼 (스크린샷·비동기 대기).
//
// Android는 Flutter 화면이 PlatformView surface에 그려지므로 첫 촬영 전에
// convertFlutterSurfaceToImage()를 1회 호출해야 한다(미호출 시 StateError).
// iOS는 변환 없이 바로 촬영된다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

bool _surfaceConverted = false;

Future<void> takeShot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (Platform.isAndroid && !_surfaceConverted) {
    await binding.convertFlutterSurfaceToImage();
    _surfaceConverted = true;
    await tester.pumpAndSettle();
  }
  await binding.takeScreenshot(name);
}

/// [finder]가 나타날 때까지 프레임을 진행한다.
///
/// 실제 Isar의 watch 스트림은 실기기에서 비동기 I/O로 방출되므로
/// pumpAndSettle만으로는 새 결과를 기다리지 못한다(저사양 기기에서 플레이키).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}
