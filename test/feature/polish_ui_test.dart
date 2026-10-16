// #16·#19·#23 — v1 UI 문구 정리 회귀.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/widgets/item_placeholder.dart';
import 'package:closetimo/features/settings/widgets/preference_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildClosetimoTheme(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('#16: 텍스트 값 행은 탭 불가라 chevron이 없다', (tester) async {
    await tester.pumpWidget(
      _host(const PreferenceRow(label: '데이터 백업', textValue: '준비 중')),
    );
    expect(find.text('준비 중'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('#23: 플레이스홀더는 옷걸이 아이콘을 그린다', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 100,
          height: 100,
          child: ItemPlaceholder(color: Colors.grey),
        ),
      ),
    );
    expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
  });
}
