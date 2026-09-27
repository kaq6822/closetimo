// #17 회귀 — QA F-07에서 TalkBack이 이름 없이 읽던 주요 컨트롤에 접근성 라벨이
// 있는지, 체크·토글 상태가 노출되는지, 토스트가 live region인지 검증한다.
// QA 하네스(tool/qa/android_qa.sh)도 이 라벨로 요소를 찾는다.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/widgets/chip_filter.dart';
import 'package:closetimo/core/widgets/toast.dart';
import 'package:closetimo/core/widgets/top_bar.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/features/add_item/add_item_screen.dart';
import 'package:closetimo/features/add_item/widgets/wash_cycle_stepper.dart';
import 'package:closetimo/features/laundry/widgets/laundry_tile.dart';
import 'package:closetimo/features/settings/widgets/preference_row.dart';
import 'package:closetimo/features/wardrobe/widgets/wardrobe_filter_bar.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildClosetimoTheme(),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ko', 'KR')],
    home: Scaffold(body: child),
  ),
);

/// [label]과 정확히 일치하는 시맨틱 노드.
SemanticsNode _node(WidgetTester tester, Pattern label) =>
    tester.getSemantics(find.bySemanticsLabel(label));

void main() {
  testWidgets('상단바 뒤로·+ 아이콘 버튼에 라벨이 있고 버튼으로 노출된다', (tester) async {
    final handle = tester.ensureSemantics();
    var added = 0;
    await tester.pumpWidget(
      _host(
        TopBar(
          subtitle: '옷 상세',
          onBack: () {},
          rightSlot: TopBarPlusAction(onTap: () => added++),
        ),
      ),
    );

    for (final label in ['뒤로 가기', '옷 등록']) {
      expect(
        _node(tester, label),
        isSemantics(label: label, isButton: true, hasTapAction: true),
      );
    }
    // 라벨로 찾은 노드를 탭하면 실제 동작이 일어난다(QA 하네스의 tap "옷 등록").
    await tester.tap(find.bySemanticsLabel('옷 등록'));
    expect(added, 1);
    handle.dispose();
  });

  testWidgets('세탁 주기 ± 버튼에 라벨이 있고 최소값에서 − 는 비활성으로 노출된다', (tester) async {
    final handle = tester.ensureSemantics();
    var value = 1;
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

    // 최소값 1에서 − 는 비활성.
    expect(
      _node(tester, '착용 횟수 줄이기'),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );

    await tester.tap(find.bySemanticsLabel('착용 횟수 늘리기'));
    await tester.pump();
    expect(value, 2);
    expect(
      _node(tester, '착용 횟수 줄이기'),
      isSemantics(hasEnabledState: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('세탁 바구니 체크에 옷 이름 라벨과 체크 상태가 노출된다', (tester) async {
    final handle = tester.ensureSemantics();
    final item = Item(
      name: '울 코트',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 1;
    var selected = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (ctx, setState) => LaundryTile(
            item: item,
            selected: selected,
            onToggleSelection: () => setState(() => selected = !selected),
          ),
        ),
      ),
    );

    expect(
      _node(tester, '울 코트 선택'),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    await tester.tap(find.bySemanticsLabel('울 코트 선택'));
    await tester.pump();
    expect(selected, isTrue);
    expect(
      _node(tester, '울 코트 선택'),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    handle.dispose();
  });

  testWidgets('설정 알림 스위치는 행 라벨과 합쳐져 토글 상태와 함께 노출된다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(PreferenceRow(label: '세탁 알림', toggleValue: true, onToggle: (_) {})),
    );

    expect(
      _node(tester, '세탁 알림'),
      isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('등록 폼 입력 필드에 필드 이름 라벨이 있다', (tester) async {
    // 필드 노드 라벨은 "<필드 이름>\n<힌트>"로 합쳐진다(위의 시각 라벨 텍스트와 구분).
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const AddItemScreen()));
    await tester.pumpAndSettle();

    for (final label in ['의류 명칭', '브랜드']) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$label\n'))),
        isSemantics(isTextField: true),
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('토스트는 live region으로 노출돼 스크린리더가 낭독한다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showClosetimoToast(ctx, '세탁 바구니에 담겼어요'),
            child: const Text('show'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    // 투명(opacity 0) 첫 프레임은 시맨틱에서 빠지므로 등장 애니메이션 후 확인.
    await tester.pump(const Duration(milliseconds: 300));

    expect(_node(tester, '세탁 바구니에 담겼어요'), isSemantics(isLiveRegion: true));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('옷장 카테고리 칩은 버튼이며 선택 상태를 노출한다 (D-1)', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Row(
          children: [
            ChipFilter(label: '전체', active: true, onTap: () {}),
            ChipFilter(label: '아우터', active: false, onTap: () {}),
          ],
        ),
      ),
    );

    expect(
      _node(tester, '전체'),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    expect(
      _node(tester, '아우터'),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('옷장 검색창은 힌트 문구가 필드 라벨로 노출된다 (D-1)', (tester) async {
    // Android는 입력 필드 라벨을 content-desc가 아닌 hintText로 내보내 덤프에는
    // 보이지 않는다. 필드 노드에 힌트가 실리는지는 여기서 검증한다.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        WardrobeFilterBar(
          query: '',
          category: null,
          sort: WardrobeSort.statusCleanFirst,
          onQueryChanged: (_) {},
          onCategoryChanged: (_) {},
          onSortChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('옷 이름 또는 브랜드 검색'))),
      isSemantics(isTextField: true),
    );
    handle.dispose();
  });

  testWidgets('세탁 바구니 타일은 "<옷 이름> 상세 보기"로 읽히고 이름을 눌러도 상세로 간다 (D-2)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final item = Item(
      name: '울 코트',
      category: Category.outer,
      washCycle: 5,
      createdAt: DateTime(2026, 1, 1),
    )..id = 1;
    var toggled = 0;
    final router = GoRouter(
      initialLocation: '/laundry',
      routes: [
        GoRoute(
          path: '/laundry',
          builder: (ctx, st) => Scaffold(
            body: LaundryTile(
              item: item,
              selected: false,
              onToggleSelection: () => toggled++,
            ),
          ),
        ),
        GoRoute(
          path: '/item/:id',
          name: Routes.itemDetail,
          builder: (ctx, st) =>
              Scaffold(body: Text('DETAIL ${st.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: buildClosetimoTheme(),
          routerConfig: router,
        ),
      ),
    );

    expect(
      _node(tester, RegExp(r'^울 코트 상세 보기')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    // 체크를 눌러도 상세로 가지 않는다(탭 영역 분리).
    await tester.tap(find.bySemanticsLabel('울 코트 선택'));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(find.text('DETAIL 1'), findsNothing);

    // 썸네일이 아닌 이름 텍스트를 눌러도 상세로 간다.
    await tester.tap(find.text('울 코트'));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('설정 알림 행은 라벨 영역을 눌러도 토글된다 (D-3)', (tester) async {
    final values = <bool>[];
    await tester.pumpWidget(
      _host(
        PreferenceRow(label: '세탁 알림', toggleValue: true, onToggle: values.add),
      ),
    );

    await tester.tap(find.text('세탁 알림'));
    expect(values, [false]);
    // 스위치 자체를 눌러도 한 번만 토글된다(행 탭과 중복 호출 없음).
    await tester.tap(find.byType(Switch));
    expect(values, [false, false]);
  });
}
