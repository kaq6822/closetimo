// #46 — 태그 재사용(등록 폼 제안), 옷장 태그 필터·결과 수·초기화, 다중 선택 일괄 태그,
// 태그 관리(이름 변경·병합·삭제) 위젯 테스트.

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/tag_repository.dart';
import 'package:closetimo/features/add_item/add_item_screen.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/tags/tag_manage_screen.dart';
import 'package:closetimo/features/wardrobe/wardrobe_screen.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository(this.items);

  final List<Item> items;
  final List<NewItemDraft> created = [];

  @override
  Stream<List<Item>> watchFiltered({
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  }) => Stream.value([
    for (final i in items)
      if (filter.matches(i)) i,
  ]);

  @override
  Future<int> create(NewItemDraft draft) async {
    created.add(draft);
    return created.length;
  }

  @override
  Future<Item?> get(int id) async => null;
  @override
  Stream<List<Item>> watchAll() => Stream.value(items);
  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();
  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
  @override
  Future<void> update(int id, ItemPatch patch) async {}
  @override
  Future<void> delete(int id) async {}
}

class _FakeTagRepository implements TagRepository {
  final List<String> calls = [];

  /// null이면 선택한 옷 수만큼 바뀐 것으로 돌려준다.
  int? changed;

  @override
  Future<int> addTag(Set<int> itemIds, String tag) async {
    calls.add('add ${(itemIds.toList()..sort()).join(',')} $tag');
    return itemIds.length;
  }

  @override
  Future<int> removeTag(Set<int> itemIds, String tag) async {
    calls.add('remove ${(itemIds.toList()..sort()).join(',')} $tag');
    return itemIds.length;
  }

  @override
  Future<int> addTags(Set<int> itemIds, Iterable<String> tags) async {
    calls.add('add ${(itemIds.toList()..sort()).join(',')} ${tags.join('|')}');
    return changed ?? itemIds.length;
  }

  @override
  Future<int> removeTags(Set<int> itemIds, Iterable<String> tags) async {
    calls.add(
      'remove ${(itemIds.toList()..sort()).join(',')} ${tags.join('|')}',
    );
    return itemIds.length;
  }

  @override
  Future<int> renameTag(String from, String to) async {
    calls.add('rename $from $to');
    return 1;
  }

  @override
  Future<int> deleteTag(String tag) async {
    calls.add('delete $tag');
    return 1;
  }
}

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 10, 17);
}

Item _item(int id, String name, List<String> tags) => Item(
  name: name,
  category: Category.top,
  washCycle: 5,
  createdAt: DateTime(2026, 10, id),
  tags: tags,
)..id = id;

final _items = [
  _item(1, '린넨 셔츠', ['여름', '흰색']),
  _item(2, '반팔 티', ['여름']),
  _item(3, '울 니트', ['겨울']),
  _item(4, '태그 없는 셔츠', []),
];

Widget _app({
  required ItemRepository items,
  required TagRepository tags,
  required String initial,
}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/wardrobe',
        name: Routes.wardrobe,
        builder: (ctx, st) => Scaffold(
          body: WardrobeScreen(
            initialFilter: wardrobeFilterFromQuery(st.uri.queryParameters),
          ),
        ),
      ),
      GoRoute(path: '/add', builder: (ctx, st) => const AddItemScreen()),
      GoRoute(path: '/tags', builder: (ctx, st) => const TagManageScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(items),
      tagRepositoryProvider.overrideWithValue(tags),
      clockProvider.overrideWithValue(_FixedClock()),
      imageStoreProvider.overrideWithValue(ImageStore()),
    ],
    child: MaterialApp.router(
      theme: buildClosetimoTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      routerConfig: router,
    ),
  );
}

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.8125;
  addTearDown(tester.view.reset);
}

int _gridCount(WidgetTester tester) {
  final delegate =
      tester.widget<SliverGrid>(find.byType(SliverGrid)).delegate
          as SliverChildBuilderDelegate;
  return delegate.childCount!;
}

Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('태그가 없으면 옷장에 태그 칩·결과 바를 보이지 않는다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(
      _app(
        items: _FakeItemRepository([_item(1, '셔츠', [])]),
        tags: _FakeTagRepository(),
        initial: '/wardrobe',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('태그'), findsNothing);
    expect(find.text('조건 초기화'), findsNothing);
  });

  testWidgets('태그 칩으로 여러 태그(OR)를 고르면 결과 수가 보이고 초기화로 전체로 돌아간다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(
      _app(
        items: _FakeItemRepository(_items),
        tags: _FakeTagRepository(),
        initial: '/wardrobe',
      ),
    );
    await tester.pumpAndSettle();
    expect(_gridCount(tester), 4);

    await tester.ensureVisible(find.text('태그'));
    await tester.tap(find.text('태그'));
    await tester.pumpAndSettle();
    // 시트: 활성 옷 기준 사용 수와 함께 보인다.
    expect(find.text('여름 2'), findsOneWidget);
    await tester.tap(find.text('여름 2'));
    await tester.tap(find.text('겨울 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2개 태그 적용'));
    await tester.pumpAndSettle();

    expect(_gridCount(tester), 3);
    expect(find.text('결과 3벌'), findsOneWidget);
    expect(find.text('태그 2개'), findsOneWidget);
    final location = GoRouter.of(
      tester.element(find.byType(WardrobeScreen)),
    ).routeInformationProvider.value.uri;
    expect(location.queryParameters['tag'], '겨울,여름');

    await tester.tap(find.text('조건 초기화'));
    await tester.pumpAndSettle();
    expect(_gridCount(tester), 4);
    expect(find.text('조건 초기화'), findsNothing);
    expect(find.text('태그'), findsOneWidget);
  });

  testWidgets('라우트 쿼리 tag=로 들어오면 태그 필터가 적용된다', (tester) async {
    _phoneViewport(tester);
    await tester.pumpWidget(
      _app(
        items: _FakeItemRepository(_items),
        tags: _FakeTagRepository(),
        initial: '/wardrobe?tag=${Uri.encodeQueryComponent('흰색')}',
      ),
    );
    await tester.pumpAndSettle();
    expect(_gridCount(tester), 1);
    expect(find.text('태그: 흰색'), findsOneWidget);
    expect(find.text('결과 1벌'), findsOneWidget);
  });

  testWidgets('다중 선택 바의 태그 액션으로 여러 옷에 일괄로 붙이고 뗀다', (tester) async {
    _phoneViewport(tester);
    final tags = _FakeTagRepository()..changed = 1; // 선택 2벌 중 1벌만 새로 붙는 상황
    await tester.pumpWidget(
      _app(
        items: _FakeItemRepository(_items),
        tags: tags,
        initial: '/wardrobe',
      ),
    );
    await tester.pumpAndSettle();

    Finder tile(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(GarmentTile));

    await tester.longPress(tile('린넨 셔츠'));
    await tester.pumpAndSettle();
    // 선택 바(액션 2개)가 하단 타일을 덮을 수 있어 목록을 올려 연다.
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(tile('울 니트'));
    await tester.pumpAndSettle();

    // 새 태그 입력으로 붙이기.
    await tester.tap(find.text('태그').last);
    await tester.pumpAndSettle();
    expect(find.text('선택한 2벌 태그 편집'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '출근, 데일리');
    await tester.pumpAndSettle();
    await tester.tap(find.text('붙이기'));
    await tester.pumpAndSettle();
    // 여러 태그는 한 번의 호출(한 트랜잭션)로 적용한다.
    expect(tags.calls, ['add 1,3 출근|데일리']);
    // 토스트는 선택 수가 아니라 실제로 바뀐 옷 수를 알린다.
    expect(find.text('1벌에 \'출근\', \'데일리\' 태그를 붙였어요'), findsOneWidget);
    // 액션 후 선택 모드가 끝난다.
    expect(find.text('모두 선택'), findsNothing);
    await _drainToast(tester);

    // 선택한 옷에 붙은 태그 떼기.
    tags.calls.clear();
    await tester.longPress(tile('린넨 셔츠'));
    await tester.pumpAndSettle();
    await tester.tap(tile('반팔 티'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('태그').last);
    await tester.pumpAndSettle();
    // 둘 다 '여름'을 가지므로 '이미 쓴 태그 붙이기'에는 '여름'이 없다.
    expect(find.text('+ 여름'), findsNothing);
    expect(find.text('+ 겨울'), findsOneWidget);
    await tester.tap(find.text('여름 ✕ 2'));
    await tester.pumpAndSettle();
    expect(tags.calls, ['remove 1,2 여름']);
    await _drainToast(tester);
  });

  testWidgets('등록 폼은 태그를 접어 두고 이미 쓴 태그를 제안해 재사용한다', (tester) async {
    _phoneViewport(tester);
    final items = _FakeItemRepository(_items);
    await tester.pumpWidget(
      _app(items: items, tags: _FakeTagRepository(), initial: '/add'),
    );
    await tester.pumpAndSettle();
    // 기본 접힘: 태그 입력이 보이지 않는다.
    expect(find.text('+ 여름'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '새 셔츠');
    final header = find.text('추가 정보 (선택)');
    await tester.ensureVisible(header);
    await tester.tap(header);
    await tester.pumpAndSettle();

    // 많이 쓴 순 제안: 여름(2) 먼저.
    expect(find.text('+ 여름'), findsOneWidget);
    await tester.ensureVisible(find.text('+ 여름'));
    await tester.tap(find.text('+ 여름'));
    await tester.pumpAndSettle();
    expect(find.text('여름 ✕'), findsOneWidget);
    expect(find.text('+ 여름'), findsNothing);

    // 입력하면 제안을 부분 일치로 좁히고, 쉼표로 여러 개 입력한다.
    final tagField = find.byType(TextField).last;
    await tester.enterText(tagField, '겨');
    await tester.pumpAndSettle();
    expect(find.text('+ 겨울'), findsOneWidget);
    expect(find.text('+ 흰색'), findsNothing);
    await tester.enterText(tagField, '검정, 여름');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 이 하네스는 등록 화면에서 시작하므로 pop하지 않는 연속 등록으로 저장한다.
    await tester.tap(find.text('저장하고 다음 옷 등록'));
    await tester.pumpAndSettle();
    expect(items.created.single.tags, ['여름', '검정']);
    await _drainToast(tester);
  });

  testWidgets('태그 관리: 같은 이름으로 바꾸면 병합을 확인하고, 삭제는 기록 보존을 안내한다', (tester) async {
    _phoneViewport(tester);
    final tags = _FakeTagRepository();
    await tester.pumpWidget(
      _app(
        items: _FakeItemRepository([
          _item(1, '셔츠', ['회사', '여름']),
          _item(2, '슬랙스', ['출근']),
        ]),
        tags: tags,
        initial: '/tags',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('회사'), findsOneWidget);
    expect(find.text('1벌'), findsNWidgets(3));

    await tester.tap(find.byTooltip("'회사' 이름 변경"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' 출근 ');
    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();
    expect(find.text('태그를 합칠까요?'), findsOneWidget);
    await tester.tap(find.text('합치기'));
    await tester.pumpAndSettle();
    expect(tags.calls, ['rename 회사 출근']);
    expect(find.text("'출근' 태그로 합쳤어요"), findsOneWidget);
    await _drainToast(tester);

    await tester.tap(find.byTooltip("'여름' 삭제"));
    await tester.pumpAndSettle();
    expect(find.textContaining('옷과 착용 기록은 그대로 남아요'), findsOneWidget);
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();
    expect(tags.calls.last, 'delete 여름');
    await _drainToast(tester);
  });
}
