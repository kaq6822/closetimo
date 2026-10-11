// T080 후속 회귀 테스트 — 옷장 그리드 스크롤 동작.
//
// 두 가지 동작을 고정한다.
//  1. 그리드는 lazy sliver로 빌드된다 (T080 성능 개선의 근거).
//     `GridView.builder(shrinkWrap: true, NeverScrollableScrollPhysics)` 는
//     스크롤 여부와 무관하게 100개 타일을 전부 한 번에 레이아웃해 첫 프레임
//     build 시간이 20ms까지 치솟았다. 화면에 보이는 타일만 빌드해야 한다.
//  2. 옷장이 비면 스크롤이 최상단으로 되감긴다.
//     sliver 전환 후 콘텐츠가 갑자기 줄어들면 스크롤 오프셋이 남아, 삭제 후
//     "내 옷장" 제목이 화면 위로 밀려난 화면이 그대로 남았다.

import 'dart:async';

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/wardrobe/wardrobe_screen.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:closetimo/app/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 목록을 외부에서 바꿀 수 있는 저장소 대역.
class _MutableItemRepository implements ItemRepository {
  _MutableItemRepository(this.items);

  List<Item> items;

  void _emit() => _controller.add([...items]);

  late final StreamController<List<Item>> _controller =
      StreamController<List<Item>>.broadcast();

  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) {
    final q = query.trim();
    return _controller.stream.map(
      (all) => [
        for (final i in all)
          if ((category == null || i.category == category) &&
              (q.isEmpty || i.name.contains(q)))
            i,
      ],
    );
  }

  @override
  Future<int> create(NewItemDraft draft) async => 0;

  @override
  Future<Item?> get(int id) async => null;

  @override
  Stream<List<Item>> watchAll() => _controller.stream.map((l) => [...l]);

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();

  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();

  @override
  Future<void> update(int id, ItemPatch patch) async {}

  @override
  Future<void> delete(int id) async {
    items = [
      for (final i in items)
        if (i.id != id) i,
    ];
    _emit();
  }

  void deleteAll() {
    items = [];
    _emit();
  }

  void dispose() => _controller.close();
}

Widget _harness(ItemRepository repo) {
  final router = GoRouter(
    initialLocation: '/wardrobe',
    routes: [
      GoRoute(
        path: '/wardrobe',
        name: Routes.wardrobe,
        builder: (_, __) => const Scaffold(body: WardrobeScreen()),
      ),
    ],
  );
  return ProviderScope(
    overrides: [itemRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      theme: buildClosetimoTheme(),
      routerConfig: router,
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
    ),
  );
}

void main() {
  testWidgets('그리드는 lazy sliver로 빌드된다 (전체 타일을 한 번에 만들지 않는다)', (tester) async {
    final repo = _MutableItemRepository([
      for (var i = 0; i < 100; i++)
        Item(
          name: '옷 $i',
          category: Category.top,
          washCycle: 5,
          createdAt: DateTime(2026, 1, 1),
        )..id = i + 1,
    ]);
    addTearDown(repo.dispose);

    await tester.pumpWidget(_harness(repo));
    repo._emit();
    await tester.pumpAndSettle();

    // shrinkWrap 그리드가 남아 있으면 GridView가 렌더 트리에 존재한다.
    expect(
      find.byType(GridView),
      findsNothing,
      reason: 'shrinkWrap 그리드는 100개를 전부 빌드하므로 sliver로 해야 한다',
    );
    expect(find.byType(SliverGrid), findsOneWidget);

    // 화면에 보이는 타일만 빌드된다. 100점이 모두 만들어져 있으면 lazy가 아니다.
    final builtTiles = find
        .byWidgetPredicate(
          (w) => w is Text && RegExp(r'^옷 \d+$').hasMatch(w.data ?? ''),
        )
        .evaluate()
        .length;
    expect(
      builtTiles,
      lessThan(20),
      reason: '100점이 전부 빌드되었다면 lazy sliver가 아니다 (actual=$builtTiles)',
    );
  });

  testWidgets('스크롤 끝에서도 마지막 타일 아래 탭바 회피 여백이 남는다', (tester) async {
    final repo = _MutableItemRepository([
      for (var i = 0; i < 30; i++)
        Item(
          name: '옷 $i',
          category: Category.top,
          washCycle: 5,
          createdAt: DateTime(2026, 1, 1),
        )..id = i + 1,
    ]);
    addTearDown(repo.dispose);
    await tester.pumpWidget(_harness(repo));
    repo._emit();
    await tester.pumpAndSettle();
    final controller = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final lastTile = find.ancestor(
      of: find.text('옷 29'),
      matching: find.byType(GarmentTile),
    );
    final viewport = tester.getRect(find.byType(CustomScrollView));
    final lastRect = tester.getRect(lastTile);
    expect(
      viewport.bottom - lastRect.bottom,
      closeTo(ClosetimoSpacing.space76, 0.1),
    );
  });

  testWidgets('옷장이 비면 스크롤이 최상단으로 되감겨 제목이 보인다', (tester) async {
    final repo = _MutableItemRepository([
      for (var i = 0; i < 30; i++)
        Item(
          name: '옷 $i',
          category: Category.top,
          washCycle: 5,
          createdAt: DateTime(2026, 1, 1),
        )..id = i + 1,
    ]);
    addTearDown(repo.dispose);

    await tester.pumpWidget(_harness(repo));
    repo._emit();
    await tester.pumpAndSettle();

    // 아래로 스크롤해서 제목이 화면 밖으로 밀어낸다.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('내 옷장'), findsNothing, reason: '사전 조건: 스크롤됨');

    // 옷을 모두 삭제해 그리드가 통째로 사라지게 한다(콘텐츠가 급격히 줄어든다).
    repo.deleteAll();
    await tester.pumpAndSettle();

    // 스크롤이 되감기지 않으면 제목이 화면 위로 밀려난 채 남는다.
    expect(
      find.text('내 옷장'),
      findsOneWidget,
      reason: '옷장이 비면 스크롤이 초기화되지 않아 제목이 보이지 않는다',
    );
    expect(
      find.text('아직 등록된 옷이 없어요.\n오른쪽 위 + 버튼으로 첫 옷을 등록해 보세요.'),
      findsOneWidget,
    );
  });
}
