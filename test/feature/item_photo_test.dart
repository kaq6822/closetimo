// 005 — 공용 사진 표시: 배경 제거본 우선, 제거본 파일이 없으면 원본으로 대체.

import 'dart:io';

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/widgets/item_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/attribute_fakes.dart';

void main() {
  late Directory root;
  setUp(() {
    root = Directory.systemTemp.createTempSync('closetimo_photo');
    File('${root.path}/7.jpg').writeAsBytesSync(onePixelPng);
    File('${root.path}/8_cutout.png').writeAsBytesSync(onePixelPng);
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<String?> shownPath(
    WidgetTester tester, {
    required String path,
    required bool cutout,
    String? original,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageStoreProvider.overrideWithValue(ImageStore(overrideRoot: root)),
        ],
        child: MaterialApp(
          theme: buildClosetimoTheme(),
          home: SizedBox.square(
            dimension: 200,
            child: ItemPhoto(
              imagePath: path,
              cutout: cutout,
              originalPath: original,
              fallback: Colors.grey,
            ),
          ),
        ),
      ),
    );
    // 원본 대체는 경로를 한 번 더 풀므로 프레임을 두 번 진행한다.
    await tester.pump();
    await tester.pump();
    final images = find.byType(Image).evaluate();
    if (images.isEmpty) return null;
    final provider = (images.single.widget as Image).image;
    final file = switch (provider) {
      ResizeImage(:final imageProvider) => imageProvider,
      _ => provider,
    };
    return (file as FileImage).file.path.split('/').last;
  }

  testWidgets('배경 제거본이 있으면 그것을 contain으로 그린다', (tester) async {
    expect(
      await shownPath(tester, path: 'items/8_cutout.png', cutout: true),
      '8_cutout.png',
    );
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
  });

  testWidgets('배경 제거본 파일이 사라졌으면 원본으로 대체한다', (tester) async {
    expect(
      await shownPath(
        tester,
        path: 'items/7_cutout.png',
        cutout: true,
        original: 'items/7.jpg',
      ),
      '7.jpg',
    );
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
  });

  testWidgets('원본도 없으면 대표 색만 그린다', (tester) async {
    expect(await shownPath(tester, path: 'items/9.jpg', cutout: false), isNull);
  });
}
