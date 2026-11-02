// 005 US1·US2 — 타이핑 없는 속성 입력, 사진 분석 제안, 여러 장 등록 → 정리하기 흐름.

import 'dart:async';
import 'dart:io';

import 'package:closetimo/app/router.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/features/add_item/sort_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/attribute_fakes.dart';

const _iosCaps = VisionCapabilities(
  backgroundRemoval: true,
  classification: true,
);

late Directory _tmp;

File _png(String name) =>
    File('${_tmp.path}/$name')..writeAsBytesSync(onePixelPng);

Future<void> _openAdd(WidgetTester tester) async {
  await tester.pumpAndSettle();
  unawaited(
    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).pushNamed(Routes.addItem),
  );
  await tester.pumpAndSettle();
  expect(find.text('신규 옷 등록'), findsOneWidget);
}

/// 실제 파일 I/O(사진 읽기)가 끝나도록 실제 시간을 흘린 뒤 화면을 갱신한다.
Future<void> _settleIo(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _tmp = Directory.systemTemp.createTempSync('closetimo_capture'));
  tearDown(() => _tmp.deleteSync(recursive: true));

  testWidgets('종류·세부 종류·색상·추천 계절을 탭으로 고르고 이름 없이 등록하면 자동 이름으로 저장된다', (
    tester,
  ) async {
    phoneViewport(tester);
    final items = FakeItemRepo();
    await tester.pumpWidget(testApp(items: items));
    await _openAdd(tester);

    await _tapText(tester, '상의');
    // 상의를 고르면 상의의 세부 종류만 보인다.
    expect(find.text('니트'), findsOneWidget);
    expect(find.text('청바지'), findsNothing);
    await _tapText(tester, '니트');
    await _tapText(tester, '검정');
    expect(find.text("비워 두면 '검정 니트'(으)로 저장돼요"), findsOneWidget);
    // 세부 종류의 추천 계절은 자동 저장하지 않고 버튼으로만 제안한다.
    await _tapText(tester, '추천: 가을·겨울');

    await _tapText(tester, '등록하기');
    final draft = items.created.single;
    expect(draft.name, '검정 니트');
    expect(draft.category, Category.top);
    expect(draft.subType, 'knit');
    expect(draft.colors, ['black']);
    expect(draft.seasons, [Season.autumn, Season.winter]);
    await drainToasts(tester);
  });

  testWidgets('이름 키워드는 손대지 않은 축만 채우고, 사용자가 고른 종류는 덮어쓰지 않는다', (tester) async {
    phoneViewport(tester);
    final items = FakeItemRepo();
    await tester.pumpWidget(testApp(items: items));
    await _openAdd(tester);

    final name = find.byType(TextField).first;
    await tester.enterText(name, '베이지 울 코트');
    await tester.pumpAndSettle();
    expect(find.text('코트'), findsOneWidget, reason: '아우터 세부 종류가 보인다');

    // 사용자가 종류를 상의로 바꾸면, 이후 이름 입력이 종류를 되돌리지 않는다.
    await _tapText(tester, '상의');
    await tester.enterText(name, '베이지 울 코트 롱');
    await tester.pumpAndSettle();
    expect(find.text('니트'), findsOneWidget, reason: '여전히 상의');

    await _tapText(tester, '등록하기');
    final draft = items.created.single;
    expect(draft.name, '베이지 울 코트 롱');
    expect(draft.category, Category.top);
    expect(draft.subType, isNull, reason: '코트는 상의 세부 종류가 아니다');
    expect(draft.colors, ['beige']);
    expect(draft.material, 'wool');
    await drainToasts(tester);
  });

  testWidgets('사용자가 고른 세부 종류는 이후 이름 제안이 지우지 않는다(리뷰 HIGH 회귀)', (tester) async {
    phoneViewport(tester);
    final items = FakeItemRepo();
    await tester.pumpWidget(testApp(items: items));
    await _openAdd(tester);

    // 종류는 이름 제안(재킷 → 아우터)으로 정해지고, 세부 종류만 사용자가 고친다.
    await tester.enterText(find.byType(TextField).first, '재킷');
    await tester.pumpAndSettle();
    await _tapText(tester, '카디건');
    // '니트'는 상의 키워드지만, 사용자가 고른 카디건과 그 종류(아우터)를 바꾸지 않는다.
    await tester.enterText(find.byType(TextField).first, '니트');
    await tester.pumpAndSettle();
    expect(find.text('카디건'), findsOneWidget, reason: '여전히 아우터 세부 종류');
    await tester.enterText(find.byType(TextField).first, '니트 가디건 롱');
    await tester.pumpAndSettle();

    await _tapText(tester, '등록하기');
    final draft = items.created.single;
    expect(draft.category, Category.outer);
    expect(draft.subType, 'cardigan');
    await drainToasts(tester);
  });

  testWidgets('이름을 고치면 이름에서만 왔던 값은 되돌린다', (tester) async {
    phoneViewport(tester);
    final items = FakeItemRepo();
    await tester.pumpWidget(testApp(items: items));
    await _openAdd(tester);

    final name = find.byType(TextField).first;
    await tester.enterText(name, '블랙 니트');
    await tester.pumpAndSettle();
    expect(find.text('니트'), findsOneWidget, reason: '상의 세부 종류가 보인다');
    await tester.enterText(name, '엄마가 준 옷');
    await tester.pumpAndSettle();
    expect(find.text('니트'), findsNothing, reason: '미분류로 돌아간다');

    await _tapText(tester, '등록하기');
    final draft = items.created.single;
    expect(draft.category, Category.uncategorized);
    expect(draft.subType, isNull);
    expect(draft.colors, isEmpty);
    await drainToasts(tester);
  });

  testWidgets('이름이 덮어쓴 사진 제안은 이름을 고치면 되살아난다', (tester) async {
    phoneViewport(tester);
    final photo = _png('top.png');
    mockImagePicker(single: photo.path);
    final items = FakeItemRepo();
    await tester.pumpWidget(
      testApp(items: items, colors: FakeColors(['black'])),
    );
    await _openAdd(tester);
    await tester.tap(find.text('의류 사진 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 선택'));
    await _settleIo(tester);
    expect(find.text('사진에서 골랐어요. 맞지 않으면 바꿔 주세요'), findsOneWidget);

    final name = find.byType(TextField).first;
    await tester.enterText(name, '블루 셔츠');
    await tester.pumpAndSettle();
    await tester.enterText(name, '셔츠');
    await tester.pumpAndSettle();
    expect(find.text('사진에서 골랐어요. 맞지 않으면 바꿔 주세요'), findsOneWidget);

    await _tapText(tester, '등록하기');
    final draft = items.created.single;
    expect(draft.colors, ['black'], reason: '이름의 블루가 빠지면 사진의 검정으로 돌아간다');
    expect(draft.subType, 'shirt');
    await drainToasts(tester);
  });

  testWidgets('사진을 고르면 배경 제거본·색상·종류 힌트가 제안으로 채워진다(iOS)', (tester) async {
    phoneViewport(tester);
    final photo = _png('shoe.png');
    final cutout = _png('shoe_cutout.png');
    mockImagePicker(single: photo.path);
    final items = FakeItemRepo();
    await tester.pumpWidget(
      testApp(
        items: items,
        vision: FakeVision(
          caps: _iosCaps,
          analysisFor: (_) => NativeAnalysis(
            cutout: cutout,
            labels: const [VisionLabel('sneaker', 0.9)],
          ),
        ),
        colors: FakeColors(['black', 'white']),
      ),
    );
    await _openAdd(tester);

    await tester.tap(find.text('의류 사진 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 선택'));
    await _settleIo(tester);

    expect(find.text('사진에서 골랐어요. 맞지 않으면 바꿔 주세요'), findsOneWidget);
    expect(find.text('운동화'), findsOneWidget, reason: '신발 세부 종류가 보인다');

    await _tapText(tester, '등록하기');
    final draft = items.created.single;
    expect(draft.name, '검정 운동화');
    expect(draft.category, Category.shoes);
    expect(draft.subType, 'sneakers');
    expect(draft.colors, ['black', 'white']);
    expect(draft.tempPhoto!.path, photo.path);
    expect(draft.tempCutout!.path, cutout.path);
    await drainToasts(tester);
  });

  testWidgets('여러 장을 고르면 옷을 만들고 정리하기 카드로 탭만으로 분류한다(SC-501)', (tester) async {
    phoneViewport(tester);
    final photos = [_png('a.png'), _png('b.png'), _png('c.png')];
    mockImagePicker(multi: [for (final p in photos) p.path]);
    final items = FakeItemRepo();
    await tester.pumpWidget(
      testApp(
        items: items,
        vision: FakeVision(
          caps: _iosCaps,
          analysisFor: (p) => NativeAnalysis(
            labels: [
              if (p.path.endsWith('a.png')) const VisionLabel('jeans', 0.94),
            ],
          ),
        ),
        colors: FakeColors(['navy']),
      ),
    );
    await _openAdd(tester);

    await tester.tap(find.text('여러 장 한 번에 등록'));
    await _settleIo(tester, rounds: 20);

    expect(items.created, hasLength(3));
    expect(find.byType(SortItemsScreen), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    // 첫 장: 청바지 라벨 + 네이비 → 자동 이름.
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('sort-preview-name'))).data,
      '네이비 청바지',
    );
    await _tapText(tester, '저장하고 다음');

    // 둘째 장: 미분류 → 상의·티셔츠를 탭으로 고르면 이름이 따라 바뀐다.
    expect(find.text('2 / 3'), findsOneWidget);
    await _tapText(tester, '상의');
    await _tapText(tester, '티셔츠');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('sort-preview-name'))).data,
      '네이비 티셔츠',
    );
    await _tapText(tester, '저장하고 다음');

    // 셋째 장은 나중에 → 끝나면 돌아가며 정리 수를 알린다.
    expect(find.text('3 / 3'), findsOneWidget);
    await _tapText(tester, '나중에');
    expect(find.byType(SortItemsScreen), findsNothing);
    expect(find.text('2벌을 정리했어요'), findsOneWidget);

    expect(items.updated, hasLength(2));
    final (_, second) = items.updated.last;
    expect(second.name, '네이비 티셔츠');
    expect(second.category, Category.top);
    expect(second.attributes!.subType, 'tshirt');
    expect(items.items.last.category, Category.uncategorized);
    await drainToasts(tester);
  });

  testWidgets('홈 정리 대기 카드는 보관하지 않은 미분류 옷만 세고 정리하기로 이어진다', (tester) async {
    phoneViewport(tester);
    final archived = testItem(3, '보관한 옷', category: Category.uncategorized)
      ..archivedAt = DateTime(2026, 10, 1);
    final items = FakeItemRepo([
      testItem(1, '이름 없는 옷', category: Category.uncategorized),
      testItem(2, '검정 옷', category: Category.uncategorized, colors: ['black']),
      archived,
      testItem(4, '셔츠'),
    ]);
    await tester.pumpWidget(testApp(items: items));
    await tester.pumpAndSettle();

    await _tapText(tester, '정리 대기 2벌');
    expect(find.byType(SortItemsScreen), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('이름 없는 옷'), findsOneWidget);
  });

  testWidgets('정리할 옷이 없으면 바로 닫지 않고 빈 상태를 안내한다', (tester) async {
    phoneViewport(tester);
    await tester.pumpWidget(testApp(items: FakeItemRepo([testItem(1, '셔츠')])));
    await tester.pumpAndSettle();
    unawaited(
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).pushNamed(Routes.sortItems, queryParameters: {'ids': '999'}),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SortItemsScreen), findsOneWidget);
    expect(find.text('정리할 옷이 없어요'), findsOneWidget);
    await tester.tap(find.text('돌아가기'));
    await tester.pumpAndSettle();
    expect(find.byType(SortItemsScreen), findsNothing);
  });

  test('정리하기 쿼리·자동 이름 판정', () {
    expect(parseSortItemIds(null), isNull);
    expect(parseSortItemIds(''), isNull);
    expect(parseSortItemIds('3,x,3,5'), [3, 5]);
    expect(hasAutoName(testItem(1, '이름 없는 옷')), isTrue);
    expect(
      hasAutoName(testItem(1, '검정 니트', subType: 'knit', colors: ['black'])),
      isTrue,
    );
    expect(hasAutoName(testItem(1, '엄마 니트', subType: 'knit')), isFalse);
  });
}
