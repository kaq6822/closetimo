// 005 — 실제 iOS 런타임에서 사진 분석 채널과 새 화면 흐름을 검증한다(T018 일부).
//
// 1) Swift 채널(`closetimo/vision`)을 실제로 호출해 기능 확인·배경 제거·분류 라벨을 받고,
//    배경 제거본으로 대표 색상을 뽑는다(합성 이미지: 흰 배경 위 네이비 티셔츠 모양).
// 2) 실제 앱에서 칩만으로 옷을 등록하고 홈 "오늘 입은 옷"으로 기록, 옷장 상세 필터, 설정 사진 분석을 촬영한다.
//
// 실행(앱 데이터가 비어 있어야 한다):
//   xcrun simctl uninstall booted com.closetimo.app
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/attributes_vision_test.dart -d <simulator>
// 실기기에서는 배경 제거·색상까지 엄격히 확인한다(시뮬레이터는 Vision 신경망 미지원):
//   ... -d <iphone> --dart-define=E2E_VISION_STRICT=true

import 'dart:io';
import 'dart:ui' as ui;

import 'package:closetimo/core/vision/color_extractor.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:closetimo/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_helpers.dart';

/// 흰 배경 위 네이비 티셔츠 모양을 그린 PNG를 임시 파일로 만든다.
Future<File> _syntheticShirt() async {
  const size = 600.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFFF7F7F5),
  );
  final navy = Paint()..color = const Color(0xFF1F2A44);
  final shirt = Path()
    ..moveTo(200, 120)
    ..lineTo(400, 120)
    ..lineTo(500, 200)
    ..lineTo(450, 260)
    ..lineTo(410, 230)
    ..lineTo(410, 500)
    ..lineTo(190, 500)
    ..lineTo(190, 230)
    ..lineTo(150, 260)
    ..lineTo(100, 200)
    ..close();
  canvas.drawPath(shirt, navy);
  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}/e2e_shirt.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await takeShot(binding, tester, name);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).last;
    await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('iOS 사진 분석 채널: 기능 확인·배경 제거·분류·색상', (tester) async {
    if (!Platform.isIOS) return; // Android는 채널을 부르지 않는다(spec 005).
    final vision = MethodChannelNativeVision();
    final caps = await vision.capabilities();
    debugPrint(
      'E2E vision caps: bg=${caps.backgroundRemoval} '
      'classify=${caps.classification} ai=${caps.onDeviceAi}',
    );
    expect(caps.classification, isTrue);
    expect(caps.backgroundRemoval, isTrue, reason: 'iOS 17+ 시뮬레이터');

    final photo = await _syntheticShirt();
    final result = await vision.analyze(photo, removeBackground: true);
    debugPrint(
      'E2E vision labels: '
      '${result.labels.map((l) => '${l.identifier}=${l.confidence.toStringAsFixed(2)}').join(' ')}',
    );
    debugPrint('E2E vision cutout: ${result.cutout?.path}');
    // iOS 시뮬레이터는 Vision 신경망 요청을 실행하지 못한다("Failed to create espresso
    // context"). 시뮬레이터에서는 오류가 앱을 멈추지 않고 빈 결과로 돌아오는지만 보고,
    // 실기기에서는 피사체 분리와 배경 제거본 색상까지 확인한다.
    // 실기기 실행: --dart-define=E2E_VISION_STRICT=true
    const strict = bool.fromEnvironment('E2E_VISION_STRICT');
    if (!strict && result.cutout == null) {
      expect(result.labels, isEmpty, reason: 'Vision 모델 자체를 쓸 수 없는 환경');
    } else {
      expect(result.cutout, isNotNull, reason: '피사체(티셔츠 모양)를 분리해야 한다');
      expect(result.cutout!.existsSync(), isTrue);
      final cutoutColors = await const ColorExtractor().extract(
        await result.cutout!.readAsBytes(),
        AttributeSuggester.palette,
      );
      debugPrint('E2E cutout colors: $cutoutColors');
      expect(cutoutColors.first, 'navy');
    }

    // 엔진 코덱 색상 추출은 시뮬레이터에서도 동작한다(가운데 60% = 티셔츠).
    final colors = await const ColorExtractor().extract(
      await photo.readAsBytes(),
      AttributeSuggester.palette,
    );
    debugPrint('E2E photo colors: $colors');
    expect(colors.first, 'navy');

    // 이 빌드 툴체인(Xcode 26)에서는 기기 내 AI 이미지 입력을 컴파일하지 않는다.
    await expectLater(
      vision.describe(photo),
      throwsA(isA<UnsupportedError>()),
    );
  });

  testWidgets('칩만으로 등록 → 오늘 입은 옷 기록 → 상세 필터 → 사진 분석 설정', (tester) async {
    await app.main();
    await pumpUntilFound(tester, find.text('오늘 입은 옷'));
    await shot(tester, '005_01_home_empty');

    await tester.tap(find.bySemanticsLabel('옷 등록').first);
    await pumpUntilFound(tester, find.text('신규 옷 등록'));
    await shot(tester, '005_02_add_blank');

    await tapText(tester, '상의');
    await tapText(tester, '니트');
    await tapText(tester, '검정');
    await tapText(tester, '추천: 가을·겨울');
    await shot(tester, '005_03_add_attributes');

    await tapText(tester, '등록하기');
    await pumpUntilFound(tester, find.text('검정 니트'));
    await tester.pump(const Duration(seconds: 3));
    await shot(tester, '005_04_home_today');

    await tester.tap(find.text('검정 니트').first);
    await tester.pumpAndSettle();
    await tapText(tester, '오늘 1벌 기록');
    await shot(tester, '005_05_home_recorded');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(find.text('옷장').last);
    await pumpUntilFound(tester, find.text('내 옷장'));
    await shot(tester, '005_06_wardrobe');
    await tester.tap(find.byTooltip('상세 필터'));
    await pumpUntilFound(tester, find.text('검정 1'));
    await shot(tester, '005_07_detail_filter');
    await tapText(tester, '검정 1');
    await tapText(tester, '1벌 보기');
    expect(find.text('검정 니트'), findsWidgets);

    await tester.tap(find.text('설정').last);
    await pumpUntilFound(tester, find.text('사진 분석'));
    await Scrollable.ensureVisible(
      tester.element(find.text('사진 분석')),
      alignment: 0.2,
    );
    await shot(tester, '005_08_settings_photo');
    expect(find.text('사진 배경 자동 제거'), findsOneWidget);
  });
}
