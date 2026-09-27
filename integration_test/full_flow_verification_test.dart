// iOS 시뮬레이터 전체 플로우 검증 (실기기 통합 테스트).
//
// 실제 main()·실제 Isar 저장소로 앱을 구동하고, 등록 → 옷장 → 상세(착용·세탁)
// → 세탁 완료 → 설정 → 수정 → 삭제까지 사용자 여정 전체를 순회한다.
// 각 단계에서 스크린샷을 촬영해 UI/UX를 육안 검증할 수 있게 한다.
//
// 주의: 스크롤 영역 아래(fold 밖) 위젯은 finder에 잡혀도 tap이 no-op이 되므로
// 모든 탭 전에 ensureVisible로 노출을 보장한다.
//
// 실행 (앱 데이터가 비어 있어야 하므로 사전에 시뮬레이터에서 앱 삭제 권장):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/full_flow_verification_test.dart -d <simulator>

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

  /// 스크롤로 노출을 보장한 뒤 탭한다.
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
    '전체 사용자 여정: 등록→옷장→상세→세탁→설정→수정→삭제',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // ── 1. 홈 (빈 상태) ────────────────────────────────
      expect(find.text('기분 좋은 옷장 관리'), findsOneWidget);
      expect(find.text('전체 아이템'), findsOneWidget);
      await shot(tester, '01_home_empty');

      // ── 2. 신규 옷 등록 ────────────────────────────────
      await tapVisible(tester, find.byIcon(Icons.add_rounded));
      expect(find.text('신규 옷 등록'), findsOneWidget);
      await shot(tester, '02_add_blank');

      await tester.enterText(find.byType(TextField).at(0), '오버사이즈 캐시미어 코트');
      await tester.enterText(find.byType(TextField).at(1), 'ZARA');
      await tester.pumpAndSettle();

      // 세탁 주기 스테퍼 + 1회 (기본 5 → 6)
      await tapVisible(tester, find.byIcon(Icons.add_rounded));
      expect(find.text('6'), findsOneWidget);

      // 카테고리: 기본 아우터 → 상의로 변경
      await tapVisible(tester, find.text('상의'));

      // 세탁 방법: HAND WASH 선택
      await tapVisible(tester, find.text('HAND WASH'));

      // 구매일: 날짜 피커 열고 오늘 날짜로 확인
      await tapVisible(tester, find.text('구매일 선택'));
      await shot(tester, '03_date_picker');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      await shot(tester, '04_add_filled');

      await tapVisible(tester, find.text('등록하기'));
      // 저장 토스트와 함께 홈으로 복귀
      expect(find.text('새 옷이 옷장에 등록됐어요'), findsOneWidget);
      await shot(tester, '05_home_after_save_toast');
      await waitToastGone(tester);

      // 홈 통계 반영 확인
      expect(find.text('기분 좋은 옷장 관리'), findsOneWidget);
      await shot(tester, '06_home_with_data');

      // ── 3. 옷장 탭: 그리드·검색 ─────────────────────────
      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.text('내 옷장'), findsOneWidget);
      expect(find.text('오버사이즈 캐시미어 코트'), findsOneWidget);
      await shot(tester, '07_wardrobe_grid');

      await tester.enterText(find.byType(TextField).first, '존재하지않는옷');
      await pumpUntilFound(tester, find.text('검색 결과가 없습니다.'));
      expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
      await shot(tester, '08_wardrobe_search_empty');

      await tester.enterText(find.byType(TextField).first, '캐시미어');
      await pumpUntilFound(tester, find.text('오버사이즈 캐시미어 코트'));
      expect(find.text('오버사이즈 캐시미어 코트'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      // ── 4. 옷 상세: 착용 기록 + 세탁 바구니 ──────────────
      await tapVisible(tester, find.text('오버사이즈 캐시미어 코트'));
      expect(find.text('착용 히스토리'), findsOneWidget);
      await shot(tester, '09_item_detail');

      await tapVisible(tester, find.text('착용 기록하기'));
      expect(find.text('오늘의 착용'), findsOneWidget);
      await shot(tester, '10_wear_sheet');
      await tester.enterText(find.byType(TextField).last, '오피스 미팅');
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      expect(find.text('오늘의 착용이 기록되었어요'), findsOneWidget);
      await waitToastGone(tester);
      // 타임라인에 기록 반영
      expect(find.text('오피스 미팅'), findsOneWidget);

      await tapVisible(tester, find.text('세탁 바구니'));
      expect(find.text('세탁 바구니에 담겼어요'), findsOneWidget);
      await waitToastGone(tester);
      expect(find.text('바구니에서 제외'), findsOneWidget);
      await shot(tester, '11_detail_after_wear_laundry');

      // 상세 → 뒤로 (옷장 복귀)
      await tapVisible(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));

      // ── 5. 세탁 탭: 선택 → 세탁 완료 ────────────────────
      await tester.tap(find.text('세탁'));
      await tester.pumpAndSettle();
      expect(find.text('세탁 바구니'), findsOneWidget);
      expect(find.text('오버사이즈 캐시미어 코트'), findsOneWidget);
      await shot(tester, '12_laundry_list');

      await tapVisible(tester, find.text('모두 선택'));
      await tapVisible(tester, find.text('선택 항목 세탁 완료 처리'));
      expect(find.text('1점의 세탁이 완료됐어요'), findsOneWidget);
      await shot(tester, '13_laundry_completed_toast');
      await waitToastGone(tester);
      expect(find.text('세탁할 옷이 없어요.'), findsOneWidget);
      await shot(tester, '14_laundry_empty');

      // ── 6. 설정 탭: 토글 ────────────────────────────────
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      expect(find.text('세탁 알림'), findsOneWidget);
      await shot(tester, '15_settings');
      final firstSwitch = find.byType(Switch).first;
      final before = tester.widget<Switch>(firstSwitch).value;
      await tapVisible(tester, firstSwitch);
      expect(tester.widget<Switch>(firstSwitch).value, !before);
      await shot(tester, '16_settings_toggled');

      // ── 7. 수정 플로우 ──────────────────────────────────
      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('오버사이즈 캐시미어 코트'));
      await tapVisible(tester, find.byIcon(Icons.more_horiz_rounded));
      await tapVisible(tester, find.text('수정하기'));
      expect(find.text('옷 정보 수정'), findsOneWidget);
      await shot(tester, '17_edit_prefilled');

      await tester.enterText(find.byType(TextField).at(0), '수선한 캐시미어 코트');
      await tester.pumpAndSettle();

      // dirty 상태에서 뒤로가기 → 작성 중단 다이얼로그
      await tapVisible(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(find.text('작성을 그만두시겠어요?'), findsOneWidget);
      await shot(tester, '18_discard_dialog');
      await tester.tap(find.text('계속 작성'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('수정 완료'));
      expect(find.text('옷 정보를 수정했어요'), findsOneWidget);
      await waitToastGone(tester);
      expect(find.text('수선한 캐시미어 코트'), findsOneWidget);
      await shot(tester, '19_detail_after_edit');

      // ── 8. 삭제 플로우 (FR-012: 옷장 탭 복귀) ────────────
      await tapVisible(tester, find.byIcon(Icons.more_horiz_rounded));
      await tapVisible(tester, find.text('삭제하기'));
      expect(find.text('이 옷을 삭제할까요?'), findsOneWidget);
      await shot(tester, '20_delete_dialog');
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('내 옷장'), findsOneWidget);
      expect(find.text('수선한 캐시미어 코트'), findsNothing);
      await waitToastGone(tester);
      await shot(tester, '21_wardrobe_after_delete');

      // ── 9. 홈 최종 상태 (통계 0 복귀) ────────────────────
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
      await shot(tester, '22_home_final');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
