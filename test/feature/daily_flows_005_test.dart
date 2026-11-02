// 005 US3~US7 — 홈 오늘 입은 옷 빠른 기록, 세탁 그룹, 옷장 상세 필터·이번 계절, 사진 분석 설정.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/attribute_fakes.dart';

final _now = DateTime(2026, 11, 2, 9);

Future<void> _go(WidgetTester tester, String name) async {
  GoRouter.of(tester.element(find.byType(Navigator).first)).goNamed(name);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

int _gridCount(WidgetTester tester) =>
    find.byType(GarmentTile).evaluate().length;

void main() {
  group('홈 오늘 입은 옷(FR-507, SC-503)', () {
    testWidgets('최근 입은 순으로 보이고 두 벌을 골라 오늘로 기록·실행 취소한다', (tester) async {
      phoneViewport(tester);
      final events = RecordingEventRepo();
      final items = FakeItemRepo([
        testItem(1, '셔츠', lastWornAt: DateTime(2026, 10, 30), totalWears: 2),
        testItem(2, '청바지', lastWornAt: DateTime(2026, 11, 1), totalWears: 9),
        testItem(3, '새 니트', createdAt: DateTime(2026, 10, 31)),
        testItem(4, '바구니 속 옷', inLaundry: true),
      ]);
      await tester.pumpWidget(testApp(items: items, events: events, now: _now));
      await tester.pumpAndSettle();

      expect(find.text('오늘 입은 옷'), findsOneWidget);
      expect(find.text('바구니 속 옷'), findsNothing);
      final xs = [
        for (final name in ['청바지', '셔츠', '새 니트'])
          tester.getTopLeft(find.text(name)).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()), reason: '최근 입은 순 → 미착용');

      await tester.tap(find.text('청바지'));
      await tester.pump();
      await tester.tap(find.text('새 니트'));
      await tester.pump();
      await _tapText(tester, '오늘 2벌 기록');

      final batch = events.batches.single;
      expect(batch.ids.toSet(), {2, 3});
      expect(batch.wornOn, _now);
      expect(find.text('오늘의 착용을 2벌 기록했어요'), findsOneWidget);
      await tester.tap(find.text('실행 취소'));
      await tester.pumpAndSettle();
      expect(events.undone.single, [500, 501]);
      await drainToasts(tester);
    });

    testWidgets('옷이 없으면 첫 등록을 안내한다', (tester) async {
      phoneViewport(tester);
      await tester.pumpWidget(testApp(items: FakeItemRepo(), now: _now));
      await tester.pumpAndSettle();
      expect(find.text('첫 옷 등록하기'), findsOneWidget);
      expect(find.textContaining('정리 대기'), findsNothing);
    });
  });

  group('세탁 그룹(FR-512)', () {
    testWidgets('바구니를 그룹으로 나누고 그룹 단위로 골라 완료한다', (tester) async {
      phoneViewport(tester);
      final laundry = FakeLaundryRepo([
        testItem(1, '흰 셔츠', colors: ['white'], inLaundry: true),
        testItem(2, '검정 니트', colors: ['black'], inLaundry: true),
        testItem(
          3,
          '청바지',
          category: Category.bottom,
          subType: 'jeans',
          inLaundry: true,
        ),
        testItem(
          4,
          '실크 블라우스',
          colors: ['ivory'],
          careMethod: CareMethod.handWash,
          inLaundry: true,
        ),
      ]);
      await tester.pumpWidget(
        testApp(items: FakeItemRepo(), laundry: laundry, now: _now),
      );
      await tester.pumpAndSettle();
      // 홈 미리보기에 그룹 요약.
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('laundry-group-summary')))
            .data,
        '손세탁·드라이 1 · 데님 1 · 흰옷·밝은색 1 · 어두운색·색깔 옷 1',
      );

      await _go(tester, Routes.laundry);
      final headers = [
        for (final h in ['손세탁·드라이 1', '데님 1', '흰옷·밝은색 1', '어두운색·색깔 옷 1'])
          tester.getTopLeft(find.text(h)).dy,
      ];
      expect(headers, orderedEquals([...headers]..sort()));

      await tester.tap(find.bySemanticsLabel('데님 그룹 선택'));
      await tester.pumpAndSettle();
      await _tapText(tester, '선택 항목 세탁 완료 처리');
      expect(laundry.completed.single, [3]);
      await drainToasts(tester);
    });

    testWidgets('그룹이 하나뿐이면 나누지 않는다', (tester) async {
      phoneViewport(tester);
      final laundry = FakeLaundryRepo([
        testItem(1, 'a', inLaundry: true),
        testItem(2, 'b', inLaundry: true),
      ]);
      await tester.pumpWidget(
        testApp(items: FakeItemRepo(), laundry: laundry, now: _now),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.laundry);
      expect(find.text('그룹 선택'), findsNothing);
      expect(find.text('색상 미지정 2'), findsNothing);
    });
  });

  group('옷장 상세 필터·이번 계절(FR-509~511)', () {
    final wardrobe = [
      testItem(
        1,
        '검정 니트',
        subType: 'knit',
        colors: ['black'],
        seasons: [Season.winter],
      ),
      testItem(
        2,
        '네이비 티',
        subType: 'tshirt',
        colors: ['navy'],
        seasons: [Season.summer],
      ),
      testItem(3, '검정 셔츠', subType: 'shirt', colors: ['black', 'white']),
      testItem(
        4,
        '가을 재킷',
        category: Category.outer,
        subType: 'jacket',
        seasons: [Season.autumn],
      ),
    ];

    testWidgets('색상을 고르면 적용 전 결과 수를 보여 주고 URL에 싣는다', (tester) async {
      phoneViewport(tester);
      await tester.pumpWidget(
        testApp(items: FakeItemRepo([...wardrobe]), now: _now),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.wardrobe);
      expect(_gridCount(tester), 4);

      await tester.tap(find.byTooltip('상세 필터'));
      await tester.pumpAndSettle();
      await _tapText(tester, '검정 2');
      expect(find.text('2벌 보기'), findsOneWidget);
      await _tapText(tester, '2벌 보기');

      expect(_gridCount(tester), 2);
      expect(find.byTooltip('상세 필터 1개 적용됨'), findsOneWidget);
      expect(currentLocation(tester).queryParameters['color'], 'black');

      // 종류 칩을 바꿔도 상세 조건은 유지된다(라우트 쿼리 왕복).
      await _tapText(tester, '상의');
      expect(_gridCount(tester), 2);
    });

    testWidgets('이번 계절 칩은 이 계절이거나 계절을 정하지 않은 옷을 남긴다', (tester) async {
      phoneViewport(tester);
      await tester.pumpWidget(
        testApp(items: FakeItemRepo([...wardrobe]), now: _now),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.wardrobe);

      await _tapText(tester, '가을 옷');
      expect(_gridCount(tester), 2, reason: '가을 재킷 + 계절 미지정 셔츠');
      expect(find.text('검정 셔츠'), findsOneWidget);
      expect(find.text('가을 재킷'), findsOneWidget);
    });

    testWidgets('검색어는 색상·세부 종류 라벨도 찾는다', (tester) async {
      phoneViewport(tester);
      await tester.pumpWidget(
        testApp(items: FakeItemRepo([...wardrobe]), now: _now),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.wardrobe);
      await tester.enterText(find.byType(TextField).first, '흰색');
      await tester.pumpAndSettle();
      expect(_gridCount(tester), 1);
      await tester.enterText(find.byType(TextField).first, '재킷');
      await tester.pumpAndSettle();
      expect(_gridCount(tester), 1);
    });
  });

  group('사진 분석 설정(FR-513·515)', () {
    testWidgets('iOS: 지원하는 기능만 토글로 보이고 저장한다', (tester) async {
      phoneViewport(tester);
      final prefs = FakePrefsRepo(UserPreferences());
      await tester.pumpWidget(
        testApp(
          items: FakeItemRepo(),
          prefs: prefs,
          vision: FakeVision(
            caps: const VisionCapabilities(
              backgroundRemoval: true,
              classification: true,
              onDeviceAi: OnDeviceAiStatus.available,
            ),
          ),
          now: _now,
        ),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.settings);

      expect(find.text('사진 배경 자동 제거'), findsOneWidget);
      await _tapText(tester, '기기 내 AI로 자세히 분석');
      expect(prefs.prefs.onDeviceAi, isTrue);
      await _tapText(tester, '사진 배경 자동 제거');
      expect(prefs.prefs.removeBackground, isFalse);
    });

    testWidgets('Android(미지원): 색상 추천 안내만 보인다', (tester) async {
      phoneViewport(tester);
      await tester.pumpWidget(testApp(items: FakeItemRepo(), now: _now));
      await tester.pumpAndSettle();
      await _go(tester, Routes.settings);
      await tester.ensureVisible(find.text('사진 분석'));
      expect(find.text('사진 색상 추천'), findsOneWidget);
      // 값은 행 오른쪽 끝에 붙는다(라벨 바로 옆이 아니라).
      final row = tester.getRect(
        find
            .ancestor(of: find.text('사진 색상 추천'), matching: find.byType(InkWell))
            .first,
      );
      expect(
        row.right - tester.getRect(find.text('항상 켜짐')).right,
        lessThan(32),
      );
      expect(find.text('사진 배경 자동 제거'), findsNothing);
      expect(find.text('기기 내 AI로 자세히 분석'), findsNothing);
    });

    testWidgets('Android: Google 진단 정보 안내와 모델 준비 중 토글(켜면 내려받기 시작)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      phoneViewport(tester);
      final prefs = FakePrefsRepo(UserPreferences());
      final vision = FakeVision(
        caps: const VisionCapabilities(
          backgroundRemoval: true,
          classification: true,
          onDeviceAi: OnDeviceAiStatus.notReady,
        ),
      );
      await tester.pumpWidget(
        testApp(items: FakeItemRepo(), prefs: prefs, vision: vision, now: _now),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.settings);
      await tester.ensureVisible(find.text('사진 분석'));
      expect(find.textContaining('Google ML Kit가'), findsOneWidget);
      expect(find.text('사진 배경 자동 제거'), findsOneWidget);

      final before = vision.prewarmCalls;
      await _tapText(tester, '기기 내 AI로 자세히 분석 (모델 준비 중)');
      expect(prefs.prefs.onDeviceAi, isTrue);
      expect(vision.prewarmCalls, greaterThan(before), reason: '켜면 모델 준비를 시작');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Apple Intelligence가 꺼져 있으면 켜는 방법을 안내한다', (tester) async {
      phoneViewport(tester);
      await tester.pumpWidget(
        testApp(
          items: FakeItemRepo(),
          vision: FakeVision(
            caps: const VisionCapabilities(
              classification: true,
              onDeviceAi: OnDeviceAiStatus.notEnabled,
            ),
          ),
          now: _now,
        ),
      );
      await tester.pumpAndSettle();
      await _go(tester, Routes.settings);
      await tester.ensureVisible(find.text('사진 분석'));
      expect(find.text('Apple Intelligence를 켜면 쓸 수 있어요'), findsOneWidget);
    });
  });

  group('라우트 쿼리(FR-509)', () {
    test('세부 종류·색상·계절 축이 왕복한다', () {
      final filter = wardrobeFilterFromQuery({
        'sub': 'knit,nope',
        'color': 'black,navy,neon',
        'season': 'winter,monsoon',
      });
      expect(filter.subTypes, {'knit'});
      expect(filter.colors, {'black', 'navy'});
      expect(filter.seasons, {Season.winter});
      expect(wardrobeQueryParameters(filter), {
        'sub': 'knit',
        'color': 'black,navy',
        'season': 'winter',
      });
    });
  });
}
