// #19 — 큰 글꼴(텍스트 배율 2.0)에서 짧은 라벨이 단어 중간에서 줄바꿈되지 않는지
// 검증한다(QA F-09: "MACHI/NE"). 칩·관리 방법 타일·상태 라벨·옷 타일 메타 라벨.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/widgets/chip_filter.dart';
import 'package:closetimo/core/widgets/status_label.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/features/add_item/widgets/care_method_picker.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 좁은 휴대폰(320dp)에서 텍스트 배율 2.0으로 [child]를 띄운다.
Future<void> _pumpLarge(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(960, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [imageStoreProvider.overrideWithValue(ImageStore())],
      child: MaterialApp(
        theme: buildClosetimoTheme(),
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: 2,
          maxScaleFactor: 2,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// [text]를 그리는 문단의 줄 수.
int _lineCount(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

void main() {
  testWidgets('관리 방법 타일 라벨은 한 줄을 유지한다', (tester) async {
    await _pumpLarge(
      tester,
      Padding(
        padding: const EdgeInsets.all(24),
        child: CareMethodPicker(
          value: CareMethod.unspecified,
          onChanged: (_) {},
        ),
      ),
    );
    for (final m in CareMethod.values) {
      expect(_lineCount(tester, m.label), 1, reason: m.label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터 칩과 상태 라벨은 한 줄을 유지한다', (tester) async {
    await _pumpLarge(
      tester,
      const Wrap(
        children: [
          ChipFilter(label: '입을 수 있음', active: false, onTap: _noop),
          ChipFilter(label: '액세서리', active: true, onTap: _noop),
          StatusLabel(variant: StatusLabelVariant.dirty),
        ],
      ),
    );
    expect(_lineCount(tester, '입을 수 있음'), 1);
    expect(_lineCount(tester, '액세서리'), 1);
    expect(_lineCount(tester, '세탁 필요'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('옷 타일 메타 라벨은 단어 중간에서 끊기지 않는다', (tester) async {
    final item = Item(
      name: '울 코트',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 10, 1),
    )..id = 1;
    await _pumpLarge(
      tester,
      Align(
        alignment: Alignment.topLeft,
        // 320dp 화면 2열 그리드의 타일 폭·높이.
        child: SizedBox(
          width: 139,
          height: 300,
          child: GarmentTile(item: item),
        ),
      ),
    );
    expect(_lineCount(tester, '착용 횟수'), 1);
    expect(_lineCount(tester, '마지막 세탁'), 1);
  });
}

void _noop() {}
