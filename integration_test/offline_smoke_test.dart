// 오프라인 동작 검증 (T081, SC-007): 실기기/시뮬레이터 필요.
//
// `HttpOverrides.global`로 모든 외부 HTTP 호출 생성을 차단한 "비행기 모드"
// 가정 아래에서 US1~US5 핵심 5작업(등록·탐색·착용 기록·세탁 완료·설정)이
// 예외 없이 완주되는지 확인한다. 헌법 III(로컬 우선)에 따라 앱은 애초에
// 네트워크를 호출하지 않아야 하므로, 이 차단 아래에서도 정상 동작해야 한다.
//
// 실행 전 앱 데이터를 비워야 한다:
//   xcrun simctl uninstall booted com.closetimo.closetimoApp
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/offline_smoke_test.dart -d <simulator>

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:closetimo/main.dart' as app;

/// 어떤 코드든 HttpClient를 생성하려 하면 즉시 실패시켜 네트워크 의존을 드러낸다.
class _BlockAllNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError(
      'Offline smoke test: HttpClient 생성이 시도됨 — 로컬 우선 원칙(헌법 III) 위반',
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> waitToastGone(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
  }

  testWidgets('오프라인(HttpOverrides 차단) 상태에서 핵심 5작업 완주', (tester) async {
    HttpOverrides.global = _BlockAllNetworkOverrides();
    addTearDown(() => HttpOverrides.global = null);

    await app.main();
    await tester.pumpAndSettle();

    // ── US1: 옷 등록 ────────────────────────────────────
    await tapVisible(tester, find.byIcon(Icons.add_rounded));
    await tester.enterText(find.byType(TextField).at(0), '오프라인 테스트 재킷');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('등록하기'));
    expect(find.text('새 옷이 옷장에 등록됐어요'), findsOneWidget);
    await shot(tester, 'offline_01_registered');
    await waitToastGone(tester);

    // ── US2: 옷장 탐색(검색·필터) ─────────────────────────
    await tester.tap(find.text('옷장'));
    await tester.pumpAndSettle();
    expect(find.text('오프라인 테스트 재킷'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '오프라인');
    await tester.pumpAndSettle();
    expect(find.text('오프라인 테스트 재킷'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await shot(tester, 'offline_02_wardrobe_search');

    // ── US3: 착용 기록 ──────────────────────────────────
    await tapVisible(tester, find.text('오프라인 테스트 재킷'));
    await tapVisible(tester, find.text('착용 기록하기'));
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 착용이 기록되었어요'), findsOneWidget);
    await waitToastGone(tester);
    await shot(tester, 'offline_03_wear_recorded');

    // ── US4: 세탁 바구니 → 세탁 완료 ──────────────────────
    await tapVisible(tester, find.text('세탁 바구니'));
    expect(find.text('세탁 바구니에 담겼어요'), findsOneWidget);
    await waitToastGone(tester);

    // 상세는 push된 화면이라 하단 탭이 없다. 옷장으로 되돌아가야 탭이 보인다.
    await tapVisible(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));

    await tester.tap(find.text('세탁'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('모두 선택'));
    await tapVisible(tester, find.text('선택 항목 세탁 완료 처리'));
    expect(find.text('1점의 세탁이 완료됐어요'), findsOneWidget);
    await waitToastGone(tester);
    await shot(tester, 'offline_04_laundry_completed');

    // ── US5: 설정(알림 토글) ────────────────────────────
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    final firstSwitch = find.byType(Switch).first;
    final before = tester.widget<Switch>(firstSwitch).value;
    await tapVisible(tester, firstSwitch);
    expect(tester.widget<Switch>(firstSwitch).value, !before);
    await shot(tester, 'offline_05_settings_toggled');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
