// US1 골든 패스 테스트. 디바이스 없이도 동작하는 widget-level integration이다.
// 진짜 integration_test로 승격하려면 `IntegrationTestWidgetsFlutterBinding`로
// 바인딩만 교체하면 된다(plan.md T040 deviation 참조).

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/add_item/add_item_screen.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeClock implements Clock {
  _FakeClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

/// 위젯 UI 테스트용 간이 double이다. `update()`의 clamp/정규화/status 재평가
/// 로직은 편의상 흉내만 냈을 뿐, repository 로직 계약(단일 진실 원천)은
/// `isar_item_repository_test.dart`가 실제 Isar 인스턴스로 검증한다. 이 클래스가
/// 계약 검증의 근거로 쓰이지 않도록 주의할 것.
class _InMemoryItemRepository implements ItemRepository {
  final List<Item> items = [];
  int _nextId = 1;

  @override
  Future<int> create(NewItemDraft draft) async {
    if (draft.name.trim().isEmpty) {
      throw ArgumentError('name empty');
    }
    final id = _nextId++;
    items.insert(
      0,
      Item(
        name: draft.name.trim(),
        brand: draft.brand.trim().isEmpty ? null : draft.brand.trim(),
        category: draft.category,
        careMethod: draft.careMethod,
        washCycle: draft.washCycle,
        createdAt: DateTime.now(),
      )..id = id,
    );
    return id;
  }

  @override
  Future<Item?> get(int id) async =>
      items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null);

  @override
  Stream<List<Item>> watchAll() => Stream.value(List.unmodifiable(items));

  @override
  Stream<List<Item>> watchFiltered({
    Category? category,
    String query = '',
    required WardrobeSort sort,
  }) => watchAll();

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();

  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();

  @override
  Future<void> update(int id, ItemPatch patch) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final item = items[idx];
    item
      ..name = patch.name.trim()
      ..brand = patch.brand == null || patch.brand!.trim().isEmpty
          ? null
          : patch.brand!.trim()
      ..category = patch.category
      ..careMethod = patch.careMethod
      ..washCycle = patch.washCycle <= 0 ? 1 : patch.washCycle
      ..purchasedAt = patch.purchasedAt
      ..status = item.wearSinceWash >= item.washCycle
          ? ItemStatus.dirty
          : ItemStatus.clean;
  }

  @override
  Future<void> delete(int id) async {
    items.removeWhere((i) => i.id == id);
  }
}

Widget _harness(_InMemoryItemRepository repo) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (ctx, st) => Scaffold(
          body: Center(
            child: Builder(
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => ctx.push('/add'),
                    child: const Text('open'),
                  ),
                  TextButton(
                    onPressed: () => ctx.push('/edit/1'),
                    child: const Text('openEdit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      GoRoute(path: '/add', builder: (ctx, st) => const AddItemScreen()),
      GoRoute(
        path: '/edit/:id',
        builder: (ctx, st) =>
            AddItemScreen(editId: int.parse(st.pathParameters['id']!)),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(_FakeClock(DateTime(2026, 5, 19))),
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

void main() {
  testWidgets('US1: 명칭 입력 + 등록하기로 새 옷이 등록된다', (tester) async {
    final repo = _InMemoryItemRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '테스트 코트');
    await tester.pumpAndSettle();

    // 카테고리 chip은 스크롤 영역 아래에 있을 수 있어 명시적으로 노출시킨다.
    final scrollable = find.byType(Scrollable).first;
    final chip = find.text('상의');
    await tester.scrollUntilVisible(chip, 300, scrollable: scrollable);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // 하단 글래스모피즘 등록 버튼은 Stack의 Positioned로 고정되어 스크롤
    // 없이도 노출된다.
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(repo.items, hasLength(1));
    expect(repo.items.first.name, '테스트 코트');
    expect(repo.items.first.category, Category.top);

    // 토스트 타이머가 정리되도록 충분히 대기.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('US1: 명칭이 비어 있으면 등록되지 않는다', (tester) async {
    final repo = _InMemoryItemRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 명칭 입력 없이 등록하기 탭 (canSave=false라 토스트 미발생, 타이머 없음)
    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    expect(repo.items, isEmpty);
  });

  testWidgets('002 US1: 수정 모드는 기존 값을 prefill하고 저장 시 update한다', (tester) async {
    final repo = _InMemoryItemRepository();
    repo.items.add(
      Item(
        name: '기존 코트',
        category: Category.outer,
        washCycle: 5,
        createdAt: DateTime(2026, 1, 1),
      )..id = 1,
    );
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('openEdit'));
    await tester.pumpAndSettle();

    // prefill: subtitle·버튼 라벨·기존 명칭 노출
    expect(find.text('옷 정보 수정'), findsOneWidget);
    expect(find.text('수정 완료'), findsOneWidget);
    // TextField의 초기값은 controller.text이므로 값으로 직접 확인
    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.controller?.text, '기존 코트');

    await tester.enterText(find.byType(TextField).first, '수정된 코트');
    await tester.pumpAndSettle();

    await tester.tap(find.text('수정 완료'));
    await tester.pumpAndSettle();

    expect(repo.items.single.name, '수정된 코트');
    // 파생 필드 보존
    expect(repo.items.single.washCycle, 5);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('002 US1: 수정 모드에서 명칭을 비우면 수정 완료가 비활성', (tester) async {
    final repo = _InMemoryItemRepository();
    repo.items.add(
      Item(
        name: '기존 코트',
        category: Category.outer,
        washCycle: 5,
        createdAt: DateTime(2026, 1, 1),
      )..id = 1,
    );
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('openEdit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    final button = tester.widget<TextButton>(
      find.ancestor(of: find.text('저장'), matching: find.byType(TextButton)),
    );
    expect(button.onPressed, isNull); // 비활성
  });

  // 이슈 #5 — 수정 모드 dirty-back 폐기 흐름(spec Edge Case).
  // PopScope(canPop: !_isDirty)가 시스템 back을 가로채 확인 다이얼로그를 띄우는지 검증한다.
  group('002 수정 모드 dirty-back 폐기 흐름', () {
    Future<_InMemoryItemRepository> seedAndEnterEdit(
      WidgetTester tester,
    ) async {
      final repo = _InMemoryItemRepository();
      repo.items.add(
        Item(
          name: '기존 코트',
          category: Category.outer,
          washCycle: 5,
          createdAt: DateTime(2026, 1, 1),
        )..id = 1,
      );
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('openEdit'));
      await tester.pumpAndSettle();
      expect(find.text('옷 정보 수정'), findsOneWidget);
      return repo;
    }

    testWidgets('dirty 상태에서 시스템 back → 확인 다이얼로그 노출', (tester) async {
      await seedAndEnterEdit(tester);

      await tester.enterText(find.byType(TextField).first, '수정된 코트');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('작성을 그만두시겠어요?'), findsOneWidget);
    });

    testWidgets('"계속 작성" 선택 시 다이얼로그가 닫히고 수정 화면이 유지된다', (tester) async {
      await seedAndEnterEdit(tester);

      await tester.enterText(find.byType(TextField).first, '수정된 코트');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('작성을 그만두시겠어요?'), findsOneWidget);

      await tester.tap(find.text('계속 작성'));
      await tester.pumpAndSettle();

      expect(find.text('작성을 그만두시겠어요?'), findsNothing);
      expect(find.text('옷 정보 수정'), findsOneWidget);
    });

    testWidgets('"나가기" 선택 시 수정 화면을 벗어나 홈으로 돌아간다', (tester) async {
      await seedAndEnterEdit(tester);

      await tester.enterText(find.byType(TextField).first, '수정된 코트');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('작성을 그만두시겠어요?'), findsOneWidget);

      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();

      expect(find.text('옷 정보 수정'), findsNothing);
      expect(find.text('openEdit'), findsOneWidget);
    });

    testWidgets('변경 없이 시스템 back 시 다이얼로그 없이 즉시 pop된다', (tester) async {
      await seedAndEnterEdit(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('작성을 그만두시겠어요?'), findsNothing);
      expect(find.text('옷 정보 수정'), findsNothing);
      expect(find.text('openEdit'), findsOneWidget);
    });
  });
}
