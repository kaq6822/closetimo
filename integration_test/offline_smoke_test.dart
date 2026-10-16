// T081 — 오프라인 동작 검증 (SC-007).
//
// 네트워크를 차단한 상태에서 핵심 5작업(등록·탐색·착용 기록·세탁 처리·
// 홈 조회)이 모두 정상 동작함을 실기기에서 증명한다.
//
// ── 검증 범위와 한계 (이 테스트가 증명하지 못하는 것) ─────────────
// 이 테스트는 `HttpOverrides.global`로 **Dart VM의 dart:io HTTP 클라이언트**
// (`HttpClient`/`package:http`) 경로만 차단한다. 다음은 차단 대상이 아니다.
//   • 네이티브 계층의 소켓 (예: Isar Plus native core가 자체 소켓을 여는 경우)
//   • Flutter 플랫폼 채널을 통한 네이티브 네트워크 (相机·앨범 등)
//   • OS 비행기 모드(Airplane Mode)처럼 기기 전체를 오프라인으로 만드는 상태
//
// 따라서 이 테스트의 결과는 "OS 비행기 모드 전체 오프라인과 동일한 증거"로
// 취급하면 안 된다. 비행기 모드 검증은 별도 수동 절차로 필요하다.
// 앱이 네트워크를 쓰지 않는 설계(헌법 III)와는 별개로, Dart HTTP 경로가
// 실제로 하나도 발화하지 않는다는 것을 확인하는 방어적 가드로 유효하다.
//
// 실행 (앱 데이터가 비어 있어야 하므로 사전에 시뮬레이터에서 앱 삭제 권장):
//   xcrun simctl uninstall booted com.closetimo.app
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/offline_smoke_test.dart -d <simulator>

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:closetimo/main.dart' as app;

import 'support/e2e_helpers.dart';

/// Dart HTTP 클라이언트 생성 단계에서 차단해 모든 요청 진입점을 막는다.
class _BlockingHttpOverrides extends HttpOverrides {
  static int blockedCount = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    blockedCount++;
    throw const SocketException('Network access blocked by offline smoke test');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await takeShot(binding, tester, name);
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// 토스트(2초 타이머)가 정리될 때까지 대기한다.
  Future<void> waitToastGone(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
  }

  testWidgets(
    '네트워크 차단 상태에서 핵심 5작업(등록·탐색·착용·세탁·홈)이 동작한다',
    (tester) async {
      // ── 네트워크 차단 시작 ──
      // 전역 상태를 바꾸므로 종료 시 반드시 복구한다. 복구하지 않으면 같은
      // 프로세스에서 이어지는 테스트가 오염된다.
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = _BlockingHttpOverrides();
      addTearDown(() {
        HttpOverrides.global = previousOverrides;
      });

      // 차단 장치가 실제로 작동하는지 확인한 뒤 앱의 시도만 집계한다.
      expect(() => HttpClient(), throwsA(isA<SocketException>()));
      expect(_BlockingHttpOverrides.blockedCount, 1);
      _BlockingHttpOverrides.blockedCount = 0;

      await app.main();
      await tester.pumpAndSettle();

      // ── 1. 홈 조회 ──────────────────────────────────────
      expect(find.text('기분 좋은 옷장 관리'), findsOneWidget);
      expect(find.text('전체 아이템'), findsOneWidget);
      await shot(tester, '01_offline_home_empty');

      // ── 2. 옷 등록 ──────────────────────────────────────
      await tapVisible(tester, find.byIcon(Icons.add_rounded));
      expect(find.text('신규 옷 등록'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '오프라인 코트');
      // #42 — 브랜드는 접힌 "추가 정보 (선택)" 안에 있다.
      await tapVisible(tester, find.text('추가 정보 (선택)'));
      await tester.enterText(find.byType(TextField).at(1), 'ZARA');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('아우터'));
      await shot(tester, '02_offline_add_item');

      await tapVisible(tester, find.text('등록하기'));
      expect(find.text('새 옷이 옷장에 등록됐어요'), findsOneWidget);
      await waitToastGone(tester);
      await shot(tester, '03_offline_after_register');

      // ── 3. 옷장 탐색 (탐색 + 검색) ───────────────────────
      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.text('오프라인 코트'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '코트');
      await tester.pumpAndSettle();
      expect(find.text('오프라인 코트'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '없는옷');
      await tester.pumpAndSettle();
      expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
      await shot(tester, '04_offline_wardrobe_search');

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      // ── 4. 착용 기록 ────────────────────────────────────
      await tapVisible(tester, find.text('오프라인 코트'));
      expect(find.text('착용 히스토리'), findsOneWidget);

      await tapVisible(tester, find.text('착용 기록하기'));
      expect(find.text('오늘의 착용'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '오프라인 착용');
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      expect(find.text('오늘의 착용이 기록되었어요'), findsOneWidget);
      await waitToastGone(tester);
      expect(find.text('오프라인 착용'), findsOneWidget);
      await shot(tester, '05_offline_after_wear');

      // ── 5. 세탁 처리 ────────────────────────────────────
      await tapVisible(tester, find.text('세탁 바구니'));
      expect(find.text('세탁 바구니에 담겼어요'), findsOneWidget);
      await waitToastGone(tester);

      // 상세는 root navigator로 push되므로 하단 탭이 없는 풀스크린 라우트다.
      // 탭으로 이동하기 전에 옷장으로 돌아온다.
      await tapVisible(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(find.text('내 옷장'), findsOneWidget);

      await tester.tap(find.text('세탁'));
      await tester.pumpAndSettle();
      expect(find.text('오프라인 코트'), findsOneWidget);
      await shot(tester, '06_offline_laundry_basket');

      await tapVisible(tester, find.text('모두 선택'));
      await tapVisible(tester, find.text('선택 항목 세탁 완료 처리'));
      expect(find.text('1점의 세탁이 완료됐어요'), findsOneWidget);
      await waitToastGone(tester);
      expect(find.text('세탁할 옷이 없어요.'), findsOneWidget);
      await shot(tester, '07_offline_laundry_completed');

      // ── 6. 홈 재조회 (통계 반영 확인) ────────────────────
      // 세탁 탭은 bottom nav가 살아 있는 유일한 탭이므로 여기서 바로 이동한다.
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
      expect(find.text('기분 좋은 옷장 관리'), findsOneWidget);
      await shot(tester, '08_offline_home_after_flow');

      // 핵심 흐름에서 HTTP 클라이언트 생성 시도가 없었는지 검증한다.
      expect(_BlockingHttpOverrides.blockedCount, 0);
      debugPrint(
        'Offline smoke test: blockedHttpClients='
        '${_BlockingHttpOverrides.blockedCount}',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
