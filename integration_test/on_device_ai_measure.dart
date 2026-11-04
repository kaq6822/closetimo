// 005 T019 — 실기기 기기 내 사진 분석 측정 도구(정확도·지연). CI 대상이 아니며 수동으로 실행한다.
//
// `flutter drive`가 기기 VM에 붙지 못하는 환경(로컬 네트워크 권한 없음)에서도 쓰도록, 결과를 앱 Documents에 쓴다.
// 1) flutter build ios --profile -t integration_test/on_device_ai_measure.dart \
//      --dart-define=MEASURE_COLOR=true --dart-define=MEASURE_PREWARM=true
// 2) xcrun devicectl device install app --device <id> build/ios/iphoneos/Runner.app
// 3) 사진(*.jpg)과 빈 `_ready` 파일을 Documents/measure_in으로 복사:
//    xcrun devicectl device copy to --device <id> --domain-type appDataContainer \
//      --domain-identifier com.closetimo.app --source <dir> --destination Documents/measure_in
// 4) 앱을 실행하고 Documents/measure_out/results.json(`"done": true`)을 copy from으로 가져온다.
// 사진마다 Vision 분석(분류·배경 제거)·색상·기기 내 AI(배경 제거본/원본)와 앱이 최종 제안할 종류/세부 종류를 기록한다.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:closetimo/core/vision/color_extractor.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI measure', (tester) async {
    final docs = (await getApplicationDocumentsDirectory()).path;
    final inDir = Directory('$docs/measure_in');
    final outDir = Directory('$docs/measure_out')..createSync(recursive: true);
    final out = <String, Object?>{};
    void flush() => File('${outDir.path}/results.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));

    {
      // 사진이 복사될 때까지 기다린다(최대 5분).
      for (var i = 0; i < 150; i++) {
        if (inDir.existsSync() && File('${inDir.path}/_ready').existsSync()) break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      final vision = MethodChannelNativeVision();
      final caps = await vision.capabilities();
      out['caps'] = {
        'bg': caps.backgroundRemoval,
        'classify': caps.classification,
        'ai': caps.onDeviceAi.name,
      };
      flush();
      var beat = 0;
      final hb = Timer.periodic(const Duration(seconds: 2), (_) {
        out['heartbeat'] = ++beat;
        flush();
      });
      final sw = Stopwatch()..start();
      const doPrewarm = bool.fromEnvironment('MEASURE_PREWARM');
      if (doPrewarm) {
        try {
          await vision.prewarm();
          out['prewarmMs'] = sw.elapsedMilliseconds;
        } catch (e) {
          out['prewarmError'] = '$e';
        }
      }
      flush();
      final files = inDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      final rows = <Object?>[];
      out['rows'] = rows;
      for (final f in files) {
        final row = <String, Object?>{'name': f.uri.pathSegments.last};
        rows.add(row);
        row['stage'] = 'analyze';
        flush();
        try {
          sw.reset();
          final c = await vision
              .analyze(f, removeBackground: false)
              .timeout(const Duration(seconds: 90));
          row['classifyMs'] = sw.elapsedMilliseconds;
          row['classifyLabels'] = c.labels.length;
          row['stage'] = 'cutout';
          flush();
          sw.reset();
          final a = await vision
              .analyze(f, removeBackground: true)
              .timeout(const Duration(seconds: 90));
          row['visionMs'] = sw.elapsedMilliseconds;
          row['cutout'] = a.cutout != null;
          row['labels'] = [
            for (final l in a.labels.take(5))
              '${l.identifier}:${l.confidence.toStringAsFixed(2)}',
          ];
          final source = a.cutout ?? f;
          row['stage'] = 'color';
          flush();
          sw.reset();
          if (const bool.fromEnvironment('MEASURE_COLOR')) {
            row['colors'] = await const ColorExtractor()
                .extract(await source.readAsBytes(), AttributeSuggester.palette);
            row['colorMs'] = sw.elapsedMilliseconds;
          }
          for (final entry in {'aiCutout': source, 'aiOriginal': f}.entries) {
            if (caps.onDeviceAi != OnDeviceAiStatus.available) break;
            row['stage'] = entry.key;
            flush();
            sw.reset();
            try {
              final d = await vision
                  .describe(entry.value, schema: AttributeSuggester.describeSchema)
                  .timeout(const Duration(seconds: 90));
              row[entry.key] = {
                'ms': sw.elapsedMilliseconds,
                'category': d.category,
                'subType': d.subType,
                'colors': d.colors,
                'seasons': d.seasons,
                'material': d.material,
                'pattern': d.pattern,
                'app': () {
                  final a = AttributeSuggester.fromDescription(d);
                  return '${a.category?.name}/${a.subType}';
                }(),
              };
            } catch (e) {
              row[entry.key] = {'ms': sw.elapsedMilliseconds, 'error': '$e'};
            }
            if (a.cutout == null) break;
          }
        } catch (e) {
          row['error'] = '$e';
        }
        row['stage'] = 'done';
        flush();
      }
      hb.cancel();
      out['done'] = true;
      flush();
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
