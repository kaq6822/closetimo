// Phase 1 placeholder. 실제 위젯 테스트는 Phase 8(T077)에서 작성된다.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder smoke', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('phase 1'),
      ),
    );
    expect(find.text('phase 1'), findsOneWidget);
  });
}
