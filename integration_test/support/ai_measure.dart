// 005 T019 — 실기기 기기 내 사진 분석 측정 로직(정확도·지연). 진입점은 integration_test/on_device_ai_measure.dart.
import 'dart:convert';
import 'dart:io';

import 'package:closetimo/core/vision/color_extractor.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// [files]를 차례로 분석해 [out]에 기록하고, 단계마다 [onUpdate]를 부른다.
///
/// - 사진마다 Vision 분석(분류·배경 제거)·색상 추출·기기 내 AI(배경 제거본/원본)를 재고,
///   앱이 최종 제안할 종류/세부 종류(`fromDescription`)를 남긴다.
/// - 기기 내 AI가 `notReady`면 [aiWait] 동안 내려받기를 요청하며 준비되기를 기다린다(Android Gemini Nano).
/// - 행이 끝날 때마다 `CLOSETIMO_MEASURE <json>` 로그를 남긴다(원격 기기 로그 수집용).
Future<void> runAiMeasure({
  required List<File> files,
  required Map<String, Object?> out,
  required Future<void> Function() onUpdate,
  bool color = true,
  bool prewarm = true,
  Duration aiWait = Duration.zero,
}) async {
  final vision = MethodChannelNativeVision();
  var caps = await vision.capabilities();
  out['caps'] = _caps(caps);
  out['aiDetail'] = await _aiDetail();
  await onUpdate();

  final sw = Stopwatch()..start();
  if (caps.onDeviceAi == OnDeviceAiStatus.notReady && aiWait > Duration.zero) {
    out['stage'] = 'waiting for on-device AI model';
    await onUpdate();
    while (caps.onDeviceAi == OnDeviceAiStatus.notReady && sw.elapsed < aiWait) {
      await _quiet(vision.prewarm);
      await Future<void>.delayed(const Duration(seconds: 10));
      caps = await vision.capabilities();
      out['caps'] = _caps(caps);
      out['aiDetail'] = await _aiDetail();
      out['aiWaitSec'] = sw.elapsed.inSeconds;
      await onUpdate();
    }
  }
  // Android ML Kit 모듈은 Play 서비스가 처음에 내려받는다. 첫 사진이 결과를 낼 때까지 기다린다(최대 5분).
  if (files.isNotEmpty && (caps.backgroundRemoval || caps.classification)) {
    sw.reset();
    out['stage'] = 'waiting for vision modules';
    await onUpdate();
    while (sw.elapsed < const Duration(minutes: 5)) {
      final probe = await vision
          .analyze(files.first, removeBackground: caps.backgroundRemoval)
          .timeout(const Duration(seconds: 90));
      if (probe.cutout != null || probe.labels.isNotEmpty) break;
      await _quiet(vision.prewarm);
      await Future<void>.delayed(const Duration(seconds: 5));
      out['visionWaitSec'] = sw.elapsed.inSeconds;
      await onUpdate();
    }
  }
  if (prewarm) {
    sw.reset();
    out['prewarmError'] = await _quiet(vision.prewarm);
    out['prewarmMs'] = sw.elapsedMilliseconds;
  }
  out['stage'] = 'measuring';
  await onUpdate();

  final rows = <Map<String, Object?>>[];
  out['rows'] = rows;
  for (final f in files) {
    final row = <String, Object?>{'name': f.uri.pathSegments.last};
    rows.add(row);
    await onUpdate();
    try {
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
      if (color) {
        sw.reset();
        row['colors'] = await const ColorExtractor().extract(
          await source.readAsBytes(),
          AttributeSuggester.palette,
        );
        row['colorMs'] = sw.elapsedMilliseconds;
      }
      if (caps.onDeviceAi == OnDeviceAiStatus.available) {
        for (final entry in {'aiCutout': source, 'aiOriginal': f}.entries) {
          sw.reset();
          try {
            final d = await vision
                .describe(entry.value, schema: AttributeSuggester.describeSchema)
                .timeout(const Duration(seconds: 90));
            final app = AttributeSuggester.fromDescription(d);
            row[entry.key] = {
              'ms': sw.elapsedMilliseconds,
              'category': d.category,
              'subType': d.subType,
              'colors': d.colors,
              'seasons': d.seasons,
              'material': d.material,
              'pattern': d.pattern,
              'app': '${app.category?.name}/${app.subType}',
            };
          } catch (e) {
            row[entry.key] = {'ms': sw.elapsedMilliseconds, 'error': '$e'};
          }
          await onUpdate();
          if (a.cutout == null) break;
        }
      }
    } catch (e) {
      row['error'] = '$e';
    }
    debugPrint('CLOSETIMO_MEASURE ${jsonEncode(row)}');
    await onUpdate();
  }
  out['stage'] = 'done';
  out['done'] = true;
  debugPrint('CLOSETIMO_MEASURE ${jsonEncode({'caps': out['caps'], 'prewarmMs': out['prewarmMs'], 'done': true})}');
  await onUpdate();
}

/// 사람이 화면에서 읽을 요약(사진당 한 줄).
String summarizeAiMeasure(Map<String, Object?> out) {
  final b = StringBuffer()
    ..writeln('caps ${out['caps']}  stage ${out['stage']}')
    ..writeln('aiDetail ${out['aiDetail']}')
    ..writeln('aiWait ${out['aiWaitSec'] ?? 0}s  visionWait ${out['visionWaitSec'] ?? 0}s  prewarm ${out['prewarmMs']}ms');
  for (final r in (out['rows'] as List?) ?? const []) {
    final m = r as Map<String, Object?>;
    String ai(String k) {
      final v = m[k];
      if (v is! Map) return '-';
      return v['error'] != null
          ? 'ERR ${v['error']}'
          : '${v['app']} ${v['colors']} ${v['material']} ${v['ms']}ms';
    }

    b.writeln(
      '${m['name']}: vis ${m['visionMs']}ms cut ${m['cutout']} col ${m['colors']}'
      '\n  AI(cut) ${ai('aiCutout')}\n  AI(org) ${ai('aiOriginal')}'
      '${m['error'] != null ? '\n  ERR ${m['error']}' : ''}',
    );
  }
  return b.toString();
}

Map<String, Object?> _caps(VisionCapabilities c) => {
  'bg': c.backgroundRemoval,
  'classify': c.classification,
  'ai': c.onDeviceAi.name,
};

/// 기기 내 AI 원본 상태(Android `onDeviceAiDetail`, 진단용). 없으면 null.
Future<Object?> _aiDetail() async {
  try {
    final raw = await const MethodChannel('closetimo/vision')
        .invokeMapMethod<String, Object?>('capabilities');
    return raw?['onDeviceAiDetail'];
  } catch (e) {
    return 'error=$e';
  }
}

Future<String?> _quiet(Future<void> Function() run) async {
  try {
    await run();
    return null;
  } catch (e) {
    return '$e';
  }
}
