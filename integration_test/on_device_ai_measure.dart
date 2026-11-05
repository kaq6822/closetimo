// 005 T019 — 실기기 기기 내 사진 분석 측정 도구(정확도·지연). CI 대상이 아니며 수동으로 실행한다.
// `flutter drive` 없이 돌도록 결과를 화면·로그(`CLOSETIMO_MEASURE`)·앱 Documents(measure_out/results.json)에 남긴다.
//
// iOS(사진을 기기로 복사):
// 1) flutter build ios --profile -t integration_test/on_device_ai_measure.dart
// 2) xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app
// 3) 사진(*.jpg)과 빈 `_ready` 파일을 Documents/measure_in으로 복사:
//    xcrun devicectl device copy to --device <id> --domain-type appDataContainer \
//      --domain-identifier com.closetimo.app --source <dir> --destination Documents/measure_in
// 4) 앱을 실행하고 Documents/measure_out/results.json(`"done": true`)을 copy from으로 가져온다.
//
// Android 원격 기기(Samsung Remote Test Lab 등, 사진을 APK에 넣음):
//   python3 tool/qa/build_ai_measure_apk.py <사진 폴더>  → build/app/outputs/flutter-apk/app-profile.apk
//   설치·실행하면 Gemini Nano 모델을 최대 15분 기다린 뒤 측정하고 결과를 화면에 띄운다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'support/ai_measure.dart';

void main() => measureMain(_documentsPhotos);

/// [loadPhotos]가 준 사진으로 측정한다. 진행 상황을 화면에 그린다.
void measureMain(
  Future<List<File>> Function() loadPhotos, {
  Duration aiWait = Duration.zero,
}) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('On-device AI measure', (tester) async {
    final outDir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/measure_out',
    )..createSync(recursive: true);
    final out = <String, Object?>{'stage': 'loading photos'};
    Future<void> update() async {
      File('${outDir.path}/results.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(out),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  summarizeAiMeasure(out),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await update();
    final photos = await loadPhotos();
    await runAiMeasure(files: photos, out: out, onUpdate: update, aiWait: aiWait);
    // 결과를 읽을 수 있게 화면을 유지한다(원격 기기에서 스크린샷).
    await Future<void>.delayed(const Duration(minutes: 20));
  }, timeout: const Timeout(Duration(minutes: 60)));
}

/// Documents/measure_in의 사진(`_ready` 파일이 생길 때까지 최대 5분 기다림).
Future<List<File>> _documentsPhotos() async {
  final inDir = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/measure_in',
  );
  for (var i = 0; i < 150; i++) {
    if (File('${inDir.path}/_ready').existsSync()) break;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  if (!inDir.existsSync()) return const [];
  return inDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
