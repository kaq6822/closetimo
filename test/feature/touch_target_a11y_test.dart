// #49 회귀 — 작은 컨트롤의 시각 크기는 유지하면서 터치 영역이 최소 48dp인지,
// 선택형 컨트롤이 selected/checked 시맨틱을 전달하는지, 좁은 화면(320dp)·큰
// 글꼴(2.0)에서도 주요 동작이 보이고 조작되는지 검증한다.
// 근거: docs/qa/reports/2026-10-14-ui-review.md UI-07·UI-15, spec FR-024a·SC-007a.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/app/theme/tokens.dart';
import 'package:closetimo/core/widgets/bottom_nav.dart';
import 'package:closetimo/core/widgets/chip_filter.dart';
import 'package:closetimo/core/widgets/min_touch_target.dart';
import 'package:closetimo/core/widgets/top_bar.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/features/add_item/widgets/care_method_picker.dart';
import 'package:closetimo/features/add_item/widgets/wash_cycle_stepper.dart';
import 'package:closetimo/features/laundry/widgets/laundry_tile.dart';
import 'package:closetimo/features/wardrobe/selection/item_selection.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _min = ClosetimoSize.minTouchTarget;

Widget _host(Widget child, {double textScale = 1}) => ProviderScope(
  child: MaterialApp(
    theme: buildClosetimoTheme(),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ko', 'KR')],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: child),
  ),
);

/// 좁은 휴대폰(320×640dp) 뷰포트.
void _narrowViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Item _item({int id = 1, String name = '울 코트'}) => Item(
  name: name,
  category: Category.outer,
  careMethod: CareMethod.machine,
  washCycle: 5,
  createdAt: DateTime(2026, 1, 1),
)..id = id;

/// [label] 시맨틱 노드의 화면 크기가 최소 터치 크기 이상인지 확인한다.
void _expectMinSemanticsSize(WidgetTester tester, String label) {
  final size = tester.getSemantics(find.bySemanticsLabel(label)).rect.size;
  expect(size.width, greaterThanOrEqualTo(_min), reason: '$label width');
  expect(size.height, greaterThanOrEqualTo(_min), reason: '$label height');
}

/// [finder]를 감싼 가장 가까운 [MinTouchTarget]의 크기.
Size _targetSize(WidgetTester tester, Finder finder) => tester.getSize(
  find.ancestor(of: finder, matching: find.byType(MinTouchTarget)).first,
);

void main() {
  group('터치 영역', () {
    testWidgets('상단바 뒤로·+ 버튼은 아이콘 크기를 유지하고 48×48 영역을 가진다', (tester) async {
      final handle = tester.ensureSemantics();
      var back = 0;
      var add = 0;
      await tester.pumpWidget(
        _host(
          TopBar(
            subtitle: '옷 상세',
            onBack: () => back++,
            rightSlot: TopBarPlusAction(onTap: () => add++),
          ),
        ),
      );

      _expectMinSemanticsSize(tester, '뒤로 가기');
      _expectMinSemanticsSize(tester, '옷 등록');
      expect(
        tester.getSize(find.byIcon(Icons.arrow_back_ios_new_rounded)),
        const Size.square(18),
      );

      // 아이콘 바깥이지만 48 영역 안(가장자리 근처)을 눌러도 동작한다.
      final backRect = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.arrow_back_ios_new_rounded),
          matching: find.byType(InkResponse),
        ),
      );
      await tester.tapAt(backRect.topLeft + const Offset(3, 3));
      final addRect = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.add_rounded),
          matching: find.byType(InkResponse),
        ),
      );
      await tester.tapAt(addRect.bottomRight - const Offset(3, 3));
      expect(back, 1);
      expect(add, 1);
      handle.dispose();
    });

    testWidgets('세탁 주기 ± 버튼은 시각 원 34를 유지하고 바깥 여백 탭도 동작한다', (tester) async {
      var value = 2;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (ctx, setState) => WashCycleStepper(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );

      final plusIcon = find.byIcon(Icons.add_rounded);
      final visual = find
          .ancestor(of: plusIcon, matching: find.byType(SizedBox))
          .first;
      expect(
        tester.getSize(visual),
        const Size.square(ClosetimoSpacing.space34),
      );
      final target = _targetSize(tester, plusIcon);
      expect(target.width, greaterThanOrEqualTo(_min));
      expect(target.height, greaterThanOrEqualTo(_min));

      // 시각 원 바깥(34 영역 밖, 48 영역 안)을 탭한다.
      final rect = tester.getRect(
        find.ancestor(of: plusIcon, matching: find.byType(MinTouchTarget)),
      );
      await tester.tapAt(rect.centerRight - const Offset(2, 0));
      await tester.pump();
      expect(value, 3);

      await tester.tapAt(
        tester
                .getRect(
                  find.ancestor(
                    of: find.byIcon(Icons.remove_rounded),
                    matching: find.byType(MinTouchTarget),
                  ),
                )
                .centerLeft +
            const Offset(2, 0),
      );
      await tester.pump();
      expect(value, 2);
    });

    testWidgets('세탁 체크는 시각 원 28을 유지하고 48×48 영역에서 토글된다', (tester) async {
      var selected = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (ctx, setState) => LaundryTile(
              item: _item(),
              selected: selected,
              onToggleSelection: () => setState(() => selected = !selected),
            ),
          ),
        ),
      );

      final visual = find.byKey(const ValueKey('laundryCheckVisual'));
      expect(
        tester.getSize(visual),
        const Size.square(ClosetimoSpacing.space28),
      );
      final target = _targetSize(tester, visual);
      expect(target.width, greaterThanOrEqualTo(_min));
      expect(target.height, greaterThanOrEqualTo(_min));

      final rect = tester.getRect(
        find.ancestor(of: visual, matching: find.byType(MinTouchTarget)),
      );
      await tester.tapAt(rect.topCenter + const Offset(0, 3));
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('칩은 시각 높이를 유지하고 48 높이의 터치 영역을 가진다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: ChipFilter(label: '아우터', active: false, onTap: () => taps++),
          ),
        ),
      );

      final chip = find.descendant(
        of: find.byType(ChipFilter),
        matching: find.byType(Material),
      );
      expect(tester.getSize(chip).height, lessThan(_min));
      final target = tester.getRect(find.byType(MinTouchTarget));
      expect(target.height, greaterThanOrEqualTo(_min));
      expect(target.width, greaterThanOrEqualTo(_min));

      // 칩 시각 영역 아래 여백을 눌러도 선택된다.
      await tester.tapAt(target.bottomCenter - const Offset(0, 2));
      expect(taps, 1);
    });

    testWidgets('하단 탭 4개는 모두 48×48 이상이다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(BottomNav(current: BottomNavTab.home, onTap: (_) {})),
      );
      for (final t in BottomNavTab.values) {
        _expectMinSemanticsSize(tester, t.label);
      }
      handle.dispose();
    });

    testWidgets('옷장 타일 ⋮ 빠른 동작 버튼은 48×48 이상이다', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(width: 180, height: 280, child: GarmentTile(item: _item())),
        ),
      );
      final size = tester.getSize(
        find.ancestor(
          of: find.byIcon(Icons.more_vert_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(_min));
      expect(size.height, greaterThanOrEqualTo(_min));
    });
  });

  group('선택 상태 시맨틱', () {
    testWidgets('하단 탭은 현재 탭만 selected로 노출하고 버튼으로 탭된다', (tester) async {
      final handle = tester.ensureSemantics();
      BottomNavTab? tapped;
      await tester.pumpWidget(
        _host(
          BottomNav(current: BottomNavTab.wardrobe, onTap: (t) => tapped = t),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('옷장')),
        isSemantics(
          label: '옷장',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      for (final label in ['홈', '세탁', '설정']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(
            isButton: true,
            hasSelectedState: true,
            isSelected: false,
          ),
        );
      }
      // 색 외 단서: 설정 탭은 톱니바퀴, 활성 탭만 알약 배경을 가진다.
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      BoxDecoration indicator(BottomNavTab t) =>
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(ValueKey('bottomNavIndicator-${t.name}')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(indicator(BottomNavTab.wardrobe).color!.a, greaterThan(0));
      expect(indicator(BottomNavTab.home).color!.a, 0);

      await tester.tap(find.bySemanticsLabel('세탁'));
      expect(tapped, BottomNavTab.laundry);
      handle.dispose();
    });

    testWidgets('세탁 방법은 단일 선택 그룹으로 선택 상태를 노출한다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CareMethodPicker(value: CareMethod.machine, onChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.text(CareMethod.machine.label)),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(
        tester.getSemantics(find.text(CareMethod.handWash.label)),
        isSemantics(
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('비선택 세탁 체크는 빈 원 윤곽선과 checked=false로 체크 컨트롤임을 알린다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          LaundryTile(item: _item(), selected: false, onToggleSelection: () {}),
        ),
      );

      final deco =
          tester
                  .widget<Container>(
                    find.byKey(const ValueKey('laundryCheckVisual')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(deco.border, isNotNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel('울 코트 선택')),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('옷장 선택 모드 타일은 checked 상태를 노출하고 탭으로 토글된다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 180,
            height: 280,
            child: GarmentTile(item: _item(name: '린넨 셔츠')),
          ),
        ),
      );
      SemanticsNode tileNode() => tester.getSemantics(
        find
            .descendant(
              of: find.byType(GarmentTile),
              matching: find.byType(Material),
            )
            .first,
      );
      // 선택 모드가 아니면 체크 상태를 갖지 않는다.
      expect(tileNode(), isSemantics(hasCheckedState: false));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GarmentTile)),
      );
      container.read(wardrobeSelectionProvider.notifier).start();
      await tester.pump();
      expect(tileNode(), isSemantics(hasCheckedState: true, isChecked: false));
      // 우상단 표시는 비선택에서도 빈 원 윤곽으로 그린다.
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);

      await tester.tap(find.text('린넨 셔츠'));
      await tester.pump();
      expect(tileNode(), isSemantics(hasCheckedState: true, isChecked: true));
      handle.dispose();
    });
  });

  group('좁은 화면(320dp)·큰 글꼴(2.0)', () {
    testWidgets('상단바·스테퍼·세탁 타일·하단 탭이 넘치지 않고 조작된다', (tester) async {
      _narrowViewport(tester);
      var back = 0;
      var value = 2;
      var selected = false;
      BottomNavTab? tab;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (ctx, setState) => Column(
              children: [
                TopBar(
                  subtitle: '신규 옷 등록',
                  onBack: () => back++,
                  rightSlot: TopBarPlusAction(onTap: () {}),
                ),
                WashCycleStepper(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
                LaundryTile(
                  item: _item(name: '아주 긴 이름의 캐시미어 터틀넥 니트'),
                  selected: selected,
                  onToggleSelection: () => setState(() => selected = !selected),
                ),
                const Spacer(),
                BottomNav(current: BottomNavTab.home, onTap: (t) => tab = t),
              ],
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pump();
      // 레이아웃 overflow 등 프레임워크 예외가 없어야 한다.
      expect(tester.takeException(), isNull);

      Future<void> tapVisible(Finder f) async {
        final rect = tester.getRect(f);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        await tester.tap(f);
        await tester.pump();
      }

      await tapVisible(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tapVisible(find.byIcon(Icons.add_rounded).last);
      await tapVisible(find.byKey(const ValueKey('laundryCheckVisual')));
      await tapVisible(find.text('설정'));
      expect(back, 1);
      expect(value, 3);
      expect(selected, isTrue);
      expect(tab, BottomNavTab.settings);
    });
  });
}
