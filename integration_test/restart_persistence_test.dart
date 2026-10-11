// 위젯 트리 재구성 후 파일 저장소·마지막 탭 복원 회귀 테스트.
// 실제 OS 프로세스 종료 검증은 tool/verify_full_flow.sh로 별도 실행한다.
// 실행 전 전용 테스트 기기의 앱 데이터를 비운다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:closetimo/main.dart' as app;

import 'support/e2e_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await takeShot(binding, tester, name);
  }

  testWidgets('재시작 후 옷 데이터·마지막 탭(설정) 보존', (tester) async {
    // ── 1차 구동: 옷 등록 + 설정 탭으로 이동 ────────────────
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '재시작 검증용 코트');
    await tester.pumpAndSettle();
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();
    expect(find.text('새 옷이 옷장에 등록됐어요'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('세탁 알림'), findsOneWidget);
    await shot(tester, 'restart_01_before_settings');

    // ── 위젯 트리 제거 → 재구성 ─────────────────────
    // 기존 위젯 트리를 완전히 제거해 ProviderScope(및 Isar 인스턴스)를
    // 정리한 뒤, 동일 파일 저장소를 대상으로 앱을 다시 부팅한다.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await app.main();
    await tester.pumpAndSettle();

    // ── 2차 구동: 마지막 탭(설정) 복원 + 데이터 보존 확인 ─────
    expect(
      find.text('세탁 알림'),
      findsOneWidget,
      reason: 'FR-022: 재시작 후 마지막 탭(설정)이 복원되어야 한다',
    );
    await shot(tester, 'restart_02_after_relaunch_settings');

    await tester.tap(find.text('옷장'));
    await tester.pumpAndSettle();
    expect(
      find.text('재시작 검증용 코트'),
      findsOneWidget,
      reason: 'SC-005: 재시작 후에도 등록한 옷 데이터가 보존되어야 한다',
    );
    await shot(tester, 'restart_03_after_relaunch_wardrobe');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
