// T077 골든 테스트 공통 하네스.
//
// 골든 비교 결과를 재현 가능하게 만들려면 세 가지를 고정해야 한다.
//   1. 폰트 — Manrope/Inter/Pretendard. 테스트 환경은 기본적으로 시스템
//      폰트로 렌더링하므로 앱 폰트를 명시적으로 로드한다.
//   2. 화면 크기·픽셀 밀도 — 기기마다 달라지면 비교가 무의미하다.
//   3. 테마·로케일 — 라이트 모드 + ko-KR만 사용한다.
//
// 의도한 디자인 변경 시에만 `flutter test --update-goldens`로 기준 이미지를
// 다시 만들고, 육안 확인 후 일반 `flutter test`에서 통과하는지 검증한다.

import 'dart:io';

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// 골든 비교 기준 화면 크기(논리 px).
const Size kGoldenSurfaceSize = Size(400, 260);

/// 골든 비교 기준 픽셀 밀도. 1.0으로 고정해 이미지 바이트가 기기마다
/// 달라지는 것을 막는다.
const double kGoldenDevicePixelRatio = 1.0;

/// 앱 폰트를 로드한다. 한 번만 호출하면 된다.
///
/// [FontLoader]는 테스트 바인딩의 폰트 컬렉션을 쓰므로, 로드한 뒤에는
/// `fontFamily: 'Manrope'` 등이 실제 폰트로 렌더링된다. 로드하지 않으면
/// 모든 텍스트가 동일한 기본 폰트로 그려져 한글 라벨의 변화를 구분할 수 없다.
Future<void> loadGoldenFonts() async {
  final materialIcons = _materialIconsPath();
  final families = <String, List<String>>{
    'Manrope': [
      'assets/fonts/Manrope/Manrope-Regular.ttf',
      'assets/fonts/Manrope/Manrope-Medium.ttf',
      'assets/fonts/Manrope/Manrope-Bold.ttf',
    ],
    'Inter': [
      'assets/fonts/Inter/Inter-Regular.ttf',
      'assets/fonts/Inter/Inter-Medium.ttf',
    ],
    'Pretendard': [
      'assets/fonts/Pretendard/Pretendard-Regular.otf',
      'assets/fonts/Pretendard/Pretendard-Medium.otf',
      'assets/fonts/Pretendard/Pretendard-Bold.otf',
    ],
    // Material 아이콘 폰트는 앱 자산이 아니라 Flutter SDK가 빌드 시점에
    // 주입한다. 테스트 환경에는 자동으로 올라오지 않아 아이콘이 모두
    // 사각형(□)으로 렌더링되므로 SDK 캐시에서 직접 찾아 등록한다.
    if (materialIcons != null) 'MaterialIcons': [materialIcons],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    var anyLoaded = false;
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) continue;
      anyLoaded = true;
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    }
    // 폰트 파일이 없는 환경에서도 테스트가 무음 실패하지 않도록, 하나라도
    // 실제 파일을 읽었을 때만 등록한다.
    if (anyLoaded) await loader.load();
  }
}

/// Flutter SDK의 Material 아이콘 폰트 경로. 찾지 못하면 null.
///
/// `FLUTTER_ROOT` 환경변수는 `flutter test` 하위 프로세스에 설정되지 않을 수
/// 있으므로, 테스트 실행 파일(dart) 위치에서 SDK 루트로 올라간다.
/// `<sdk>/bin/cache/dart-sdk/bin/dart` → `<sdk>`.
String? _materialIconsPath() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  final roots = <String>[
    if (fromEnv != null) fromEnv,
    // bin/cache/dart-sdk/bin/dart 에서 3단계 올라가면 SDK 루트.
    _resolveExecutable().parent.parent.parent.parent.path,
  ];
  for (final root in roots) {
    final path =
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(path).existsSync()) return path;
  }
  return null;
}

/// 심볼릭 링크를 실제로 풀어낸 실행 파일 경로.
File _resolveExecutable() {
  var file = File(Platform.resolvedExecutable).absolute;
  // 심볼릭 링크를 따라가며 최대 10단계까지만 푼다(무한 루프 방지).
  for (var i = 0; i < 10; i++) {
    final link = Link(file.path);
    if (!link.existsSync()) break;
    file = File(link.targetSync()).absolute;
  }
  return file;
}

/// 골든 테스트용 위젯을 고정된 환경에서 렌더링한다.
///
/// [child]는 화면 중앙에 배치되며, 위젯이 화면보다 크면 스크롤되지 않는다.
/// 위젯 크기가 가변인 경우에도 동일한 캔버스가 비교되도록 한다.
Future<void> pumpGoldenHost(
  WidgetTester tester,
  Widget child, {
  Size size = kGoldenSurfaceSize,
}) async {
  tester.view
    ..physicalSize = size * kGoldenDevicePixelRatio
    ..devicePixelRatio = kGoldenDevicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildClosetimoTheme(),
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      home: Scaffold(
        backgroundColor: const Color(0xFFFAFAF5),
        body: Center(child: child),
      ),
    ),
  );
  // 이미지 디코딩은 fake async 밖에서 완료해야 골든에 자산이 포함된다.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}
