// 재시작 지속성 검증 (T083, quickstart.md §8 7단계 / SC-005·SC-006): 실기기/시뮬레이터 필요.
//
// Isar는 파일 기반 저장소이므로, OS 프로세스를 실제로 죽이지 않고도 위젯
// 트리를 다시 빌드(`app.main()` 재호출)하는 것으로 "앱 강제 종료 → 재실행"을
// 유효하게 재현할 수 있다: 이전 `runApp`의 `ProviderScope`가 언마운트되며
// `isarProvider`의 `ref.onDispose`가 실제 Isar 인스턴스를 닫고, 새 `runApp`이
// 동일 파일에서 다시 연다. 등록한 옷·마지막 탭이 재구동 후에도 보존되는지
// 확인한다.
//
// 실행 전 앱 데이터를 비워야 한다:
//   xcrun simctl uninstall booted com.closetimo.closetimoApp
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/restart_persistence_test.dart -d <simulator>

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

    // ── "강제 종료 → 재실행" 시뮬레이션 ─────────────────────
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
