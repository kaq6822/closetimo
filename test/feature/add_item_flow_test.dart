// US1 골든 패스 테스트. 디바이스 없이도 동작하는 widget-level integration이다.
// 진짜 integration_test로 승격하려면 `IntegrationTestWidgetsFlutterBinding`로
// 바인딩만 교체하면 된다(plan.md T040 deviation 참조).

import 'dart:async';

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/core/widgets/primary_button.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
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

  /// #42 — 중복 탭 검증용. 설정되면 create가 완료되기 전까지 대기한다.
  Completer<void>? gate;

  /// #42 — 다음 create 1회를 실패시킨다.
  bool failNext = false;

  int createCalls = 0;

  @override
  Future<int> create(NewItemDraft draft) async {
    createCalls++;
    if (gate != null) await gate!.future;
    if (failNext) {
      failNext = false;
      throw StateError('simulated failure');
    }
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
        careMode: draft.careMode,
        purposes: draft.purposes,
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
    ItemFilter filter = const ItemFilter(),
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
      ..careMode = patch.careMode
      ..purposes = patch.purposes
      ..washCycle = patch.washCycle <= 0 ? 1 : patch.washCycle
      ..purchasedAt = patch.purchasedAt;
    item.status = item.derivedStatus;
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

  testWidgets('#41·#45: 기본값은 미분류·미지정이고 횟수 관리를 끄면 주기 없이 저장된다', (tester) async {
    final repo = _InMemoryItemRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '가죽 가방');
    await tester.pumpAndSettle();

    // #42 — 관리 정보는 접힌 "추가 정보 (선택)" 안에 있다.
    final optional = find.text('추가 정보 (선택)');
    await tester.ensureVisible(optional);
    await tester.tap(optional);
    await tester.pumpAndSettle();

    // 기본은 횟수 기반: 스테퍼와 '세탁 필요' 안내가 보인다.
    expect(find.bySemanticsLabel('착용 횟수 늘리기'), findsOneWidget);
    expect(find.text("설정한 횟수만큼 착용하면 '세탁 필요'로 표시돼요."), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    final toggle = find.text('착용 횟수로 관리');
    await tester.scrollUntilVisible(toggle, 300, scrollable: scrollable);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('착용 횟수 늘리기'), findsNothing);
    expect(find.text('횟수와 관계없이 필요할 때 세탁 바구니에 직접 담아요.'), findsOneWidget);

    // 관리 방법 미지정 + 케어 라벨 안내.
    final careHint = find.textContaining('케어 라벨');
    await tester.scrollUntilVisible(careHint, 300, scrollable: scrollable);
    expect(careHint, findsOneWidget);
    expect(
      tester.getSemantics(
        find
            .ancestor(of: find.text('미지정'), matching: find.byType(Semantics))
            .first,
      ),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    // legacy 운동복은 종류로 고를 수 없고 용도 '운동'으로 고른다.
    expect(find.text('운동복'), findsNothing);
    final sport = find.text('운동');
    await tester.scrollUntilVisible(sport, 300, scrollable: scrollable);
    await tester.tap(sport);
    await tester.pumpAndSettle();

    await tester.tap(find.text('등록하기'));
    await tester.pumpAndSettle();

    final saved = repo.items.single;
    expect(saved.category, Category.uncategorized);
    expect(saved.careMethod, CareMethod.unspecified);
    expect(saved.careMode, CareMode.manual);
    expect(saved.washCycle, 5);
    expect(saved.purposes, [ItemPurpose.sport]);

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

  testWidgets('#24: 수정 모드는 변경 전 저장이 비활성이고 변경하면 활성이 된다', (tester) async {
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

    VoidCallback? topSave() => tester
        .widget<TextButton>(
          find.ancestor(of: find.text('저장'), matching: find.byType(TextButton)),
        )
        .onPressed;
    VoidCallback? bottomSave() =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed;

    expect(topSave(), isNull);
    expect(bottomSave(), isNull);

    await tester.enterText(find.byType(TextField).first, '수정된 코트');
    await tester.pumpAndSettle();
    expect(topSave(), isNotNull);
    expect(bottomSave(), isNotNull);

    // 원래 값으로 되돌리면 다시 비활성
    await tester.enterText(find.byType(TextField).first, '기존 코트');
    await tester.pumpAndSettle();
    expect(topSave(), isNull);
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

  // #22 N-02 — 수정 저장 토스트는 상세(하단 탭 없음)로 돌아가므로 상단, 신규 등록
  // 토스트는 탭 화면으로 돌아가므로 하단(탭 위)에 뜬다. 기본 뷰포트 800×600.
  Future<double> toastCenterY(WidgetTester tester, String message) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final toast = find.ancestor(
      of: find.text(message),
      matching: find.byType(Container),
    );
    expect(toast, findsWidgets);
    return tester.getCenter(toast.first).dy;
  }

  testWidgets('N-02: 수정 완료 토스트는 상단에 뜬다', (tester) async {
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

    await tester.enterText(find.byType(TextField).first, '수정된 코트');
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정 완료'));
    expect(await toastCenterY(tester, '옷 정보를 수정했어요'), lessThan(300));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('N-02: 신규 등록 토스트는 하단(탭 위)을 유지한다', (tester) async {
    final repo = _InMemoryItemRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '테스트 코트');
    await tester.pumpAndSettle();

    await tester.tap(find.text('등록하기'));
    expect(await toastCenterY(tester, '새 옷이 옷장에 등록됐어요'), greaterThan(300));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  // #42 — 빠른·연속 등록.
  group('#42 빠른·연속 등록', () {
    Future<_InMemoryItemRepository> openAdd(WidgetTester tester) async {
      final repo = _InMemoryItemRepository();
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return repo;
    }

    Future<void> drainToast(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    testWidgets('추가 정보는 기본 접힘이고 선택 정보임을 표기한다', (tester) async {
      await openAdd(tester);

      expect(find.text('추가 정보 (선택)'), findsOneWidget);
      expect(find.text('선택'), findsOneWidget);
      expect(find.text('이름 또는 사진 중 하나만 있어도 돼요'), findsOneWidget);
      // 접힘 상태에서는 브랜드·구매일 필드를 그리지 않는다.
      expect(find.text('구매일 선택'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      final header = find.text('추가 정보 (선택)');
      await tester.ensureVisible(header);
      await tester.tap(header);
      await tester.pumpAndSettle();
      // 명칭 + 브랜드 + 태그(#46, 추가 정보 안에 접혀 있음).
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('구매일 선택'), findsOneWidget);
    });

    testWidgets('이름만 입력하고 등록하면 기본값(미분류·주기 5)으로 저장된다', (tester) async {
      final repo = await openAdd(tester);
      await tester.enterText(find.byType(TextField).first, '흰 셔츠');
      await tester.pumpAndSettle();

      await tester.tap(find.text('등록하기'));
      await tester.pumpAndSettle();

      expect(repo.items, hasLength(1));
      expect(repo.items.single.category, Category.uncategorized);
      expect(repo.items.single.washCycle, 5);
      expect(find.text('신규 옷 등록'), findsNothing); // pop
      await drainToast(tester);
    });

    testWidgets('이름도 사진도 없으면 모든 저장 버튼이 비활성', (tester) async {
      final repo = await openAdd(tester);
      for (final label in ['저장', '저장하고 다음 옷 등록']) {
        final button = tester.widget<TextButton>(
          find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
        );
        expect(button.onPressed, isNull, reason: label);
      }
      await tester.tap(find.text('저장하고 다음 옷 등록'));
      await tester.pumpAndSettle();
      expect(repo.createCalls, 0);
    });

    testWidgets('저장하고 다음 옷 등록: 화면 유지·폼 초기화·카테고리 유지', (tester) async {
      final repo = await openAdd(tester);
      await tester.enterText(find.byType(TextField).first, '흰 셔츠');
      final chip = find.text('상의');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장하고 다음 옷 등록'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.items, hasLength(1));
      expect(repo.items.single.name, '흰 셔츠');
      expect(find.text('저장했어요. 다음 옷을 등록해 주세요'), findsOneWidget);
      expect(find.text('신규 옷 등록'), findsOneWidget); // 화면 유지
      final name = tester.widget<TextField>(find.byType(TextField).first);
      expect(name.controller?.text, isEmpty);
      await drainToast(tester);

      // 두 번째 옷은 + 없이 바로 입력. 직전 카테고리(상의)가 유지된다.
      await tester.enterText(find.byType(TextField).first, '검정 셔츠');
      await tester.pumpAndSettle();
      await tester.tap(find.text('등록하기'));
      await tester.pumpAndSettle();

      expect(repo.items.map((i) => i.name), ['검정 셔츠', '흰 셔츠']);
      expect(repo.items.first.category, Category.top);
      expect(find.text('신규 옷 등록'), findsNothing);
      await drainToast(tester);
    });

    testWidgets('연속 등록 후 빈 폼에서 뒤로 가면 확인 없이 닫히고 저장분은 남는다', (tester) async {
      final repo = await openAdd(tester);
      await tester.enterText(find.byType(TextField).first, '흰 셔츠');
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장하고 다음 옷 등록'));
      await tester.pumpAndSettle();
      await drainToast(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('작성을 그만두시겠어요?'), findsNothing);
      expect(find.text('open'), findsOneWidget);
      expect(repo.items, hasLength(1));
    });

    testWidgets('저장 중 반복 탭은 1건만 생성한다', (tester) async {
      final repo = await openAdd(tester);
      repo.gate = Completer<void>();
      await tester.enterText(find.byType(TextField).first, '흰 셔츠');
      await tester.pumpAndSettle();

      await tester.tap(find.text('등록하기'));
      await tester.pump();
      // 저장 진행 중: 모든 저장 버튼이 비활성이라 추가 탭이 무시된다.
      await tester.tap(find.text('등록하기'), warnIfMissed: false);
      await tester.tap(find.text('저장하고 다음 옷 등록'), warnIfMissed: false);
      await tester.tap(find.text('저장'), warnIfMissed: false);
      await tester.pump();
      expect(repo.createCalls, 1);

      repo.gate!.complete();
      repo.gate = null;
      await tester.pumpAndSettle();
      expect(repo.items, hasLength(1));
      await drainToast(tester);
    });

    testWidgets('저장 실패 시 아무것도 생성하지 않고 입력을 유지한다', (tester) async {
      final repo = await openAdd(tester);
      repo.failNext = true;
      await tester.enterText(find.byType(TextField).first, '흰 셔츠');
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장하고 다음 옷 등록'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('등록에 실패했어요'), findsOneWidget);
      expect(repo.items, isEmpty);
      final name = tester.widget<TextField>(find.byType(TextField).first);
      expect(name.controller?.text, '흰 셔츠');
      await drainToast(tester);

      // 재시도는 정확히 1건을 만든다.
      await tester.tap(find.text('등록하기'));
      await tester.pumpAndSettle();
      expect(repo.items, hasLength(1));
      await drainToast(tester);
    });

    testWidgets('취소(나가기)는 저장을 호출하지 않는다', (tester) async {
      final repo = await openAdd(tester);
      await tester.enterText(find.byType(TextField).first, '흰 셔츠');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();

      expect(repo.createCalls, 0);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
