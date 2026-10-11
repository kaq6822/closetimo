// TopBar 브랜드 모드에서 B1 심볼이 워드마크와 함께 노출되는지 검증한다.

import 'dart:io';

import 'package:closetimo/core/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  const symbol = ValueKey('topBarBrandSymbol');

  testWidgets('브랜드 모드에서는 심볼과 워드마크를 함께 보여준다', (tester) async {
    await tester.pumpWidget(_host(const TopBar()));

    expect(find.byKey(symbol), findsOneWidget);
    expect(find.text('옷장이모'), findsOneWidget);
    final image = tester.widget<Image>(find.byKey(symbol));
    expect((image.image as AssetImage).assetName, closetimoSymbolAsset);
  });

  testWidgets('서브타이틀 모드에서는 심볼을 숨긴다', (tester) async {
    await tester.pumpWidget(
      _host(TopBar(subtitle: '옷 상세', onBack: () {})),
    );

    expect(find.byKey(symbol), findsNothing);
    expect(find.text('옷 상세'), findsOneWidget);
  });

  test('심볼 에셋이 해상도별로 존재한다', () {
    // 에셋 파일 누락 시 런타임에서야 드러나므로 파일 존재를 직접 확인한다.
    for (final path in [
      closetimoSymbolAsset,
      'assets/images/2.0x/closetimo_symbol.png',
      'assets/images/3.0x/closetimo_symbol.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
