// US1 골든 패스 테스트. 디바이스 없이도 동작하는 widget-level integration이다.
// 진짜 integration_test로 승격하려면 `IntegrationTestWidgetsFlutterBinding`로
// 바인딩만 교체하면 된다(plan.md T040 deviation 참조).

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
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
  }) =>
      watchAll();

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) =>
      const Stream.empty();

  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
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
              builder: (ctx) => TextButton(
                onPressed: () => ctx.push('/add'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/add',
        builder: (ctx, st) => const AddItemScreen(),
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
}
