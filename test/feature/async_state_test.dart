// #48 FR-029·FR-030 — 로딩·빈 상태·읽기 실패 구분과 재시도, 쓰기 액션의 중복 입력
// 차단·진행 표시·실패 토스트.

import 'dart:async';

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/widgets/action_guard.dart';
import 'package:closetimo/core/widgets/async_state_view.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/home/home_screen.dart';
import 'package:closetimo/features/home/widgets/stats_row.dart';
import 'package:closetimo/features/laundry/laundry_screen.dart';
import 'package:closetimo/features/laundry/laundry_selection_provider.dart';
import 'package:closetimo/features/wardrobe/selection/selection_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(int id) => Item(
  name: '옷$id',
  category: Category.top,
  washCycle: 3,
  createdAt: DateTime(2026, 1, id),
)..id = id;

/// 구독마다 [failSubscriptions]번까지는 오류를 내고, 그 뒤로는 [basket]을 낸다.
class _FlakyLaundryRepo implements LaundryRepository {
  _FlakyLaundryRepo(this.basket, {this.failSubscriptions = 0});

  List<Item> basket;
  int failSubscriptions;
  int subscriptions = 0;
  int completeCalls = 0;

  /// 설정하면 세탁 완료 처리가 이 Completer를 기다린다(진행 중 상태 검증).
  Completer<void>? gate;
  bool failComplete = false;

  @override
  Stream<List<Item>> watchBasket() async* {
    subscriptions++;
    if (failSubscriptions > 0) {
      failSubscriptions--;
      throw StateError('basket read failed');
    }
    yield basket;
  }

  @override
  Future<void> toggle(int itemId) async {}

  @override
  Future<int> completeWashFor(List<int> itemIds) async {
    completeCalls++;
    await gate?.future;
    if (failComplete) throw StateError('complete failed');
    return itemIds.length;
  }
}

/// 홈 통계 읽기만 실패시키는 가짜 repository. 나머지 스트림은 빈 결과.
class _FailingStatsItemRepo implements ItemRepository {
  @override
  Stream<WardrobeStats> watchStats() =>
      Stream.error(StateError('stats read failed'));

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pumpLaundry(
  WidgetTester tester,
  _FlakyLaundryRepo repo,
) async {
  final container = ProviderContainer(
    overrides: [laundryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildClosetimoTheme(),
        home: const Scaffold(body: LaundryScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

/// 토스트 타이머(2초)와 퇴장 애니메이션을 끝까지 흘린다.
Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('StreamStateBuilder', () {
    testWidgets('로딩 → 실패 → 다시 시도 → 빈 데이터를 구분해 그린다', (tester) async {
      var calls = 0;
      final controllers = <StreamController<List<int>>>[];
      addTearDown(() {
        for (final c in controllers) {
          c.close();
        }
      });
      Stream<List<int>> open() {
        calls++;
        final c = StreamController<List<int>>();
        controllers.add(c);
        return c.stream;
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: buildClosetimoTheme(),
          home: Scaffold(
            body: StreamStateBuilder<List<int>>(
              stream: open,
              errorMessage: '목록을 불러오지 못했어요',
              builder: (_, data) =>
                  Text(data.isEmpty ? '비어 있어요' : '${data.length}개'),
            ),
          ),
        ),
      );

      // 최초 로딩: 빈 상태 문구가 아니라 로딩 표시.
      expect(find.byType(AsyncLoadingView), findsOneWidget);
      expect(find.text('비어 있어요'), findsNothing);

      // 읽기 실패: 실패 안내와 다시 시도.
      controllers.last.addError(StateError('boom'));
      await tester.pump();
      expect(find.text('목록을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('비어 있어요'), findsNothing);

      // 다시 시도는 스트림을 새로 구독한다.
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(calls, 2);
      expect(find.byType(AsyncLoadingView), findsOneWidget);

      controllers.last.add(const []);
      await tester.pump();
      expect(find.text('비어 있어요'), findsOneWidget);
      expect(find.text('목록을 불러오지 못했어요'), findsNothing);
    });

    testWidgets('부모가 다시 그려져도 streamKey가 같으면 다시 구독하지 않는다', (tester) async {
      var calls = 0;
      Stream<int> open() {
        calls++;
        return Stream.value(1);
      }

      Widget host(Object key) => MaterialApp(
        home: StreamStateBuilder<int>(
          stream: open,
          streamKey: key,
          errorMessage: 'x',
          builder: (_, v) => Text('$v'),
        ),
      );

      await tester.pumpWidget(host('a'));
      await tester.pumpWidget(host('a'));
      expect(calls, 1);
      await tester.pumpWidget(host('b'));
      expect(calls, 2);
    });
  });

  group('세탁 바구니 (FR-029)', () {
    testWidgets('읽기 실패는 빈 바구니처럼 보이지 않고 다시 시도로 복구한다', (tester) async {
      final repo = _FlakyLaundryRepo([_item(1)], failSubscriptions: 1);
      await _pumpLaundry(tester, repo);

      expect(find.text('세탁 바구니를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('세탁할 옷이 없어요.'), findsNothing);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      await tester.pump();
      expect(repo.subscriptions, 2);
      expect(find.text('세탁 대기 1점'), findsOneWidget);
      expect(find.text('세탁 바구니를 불러오지 못했어요'), findsNothing);
    });

    testWidgets('정상 빈 바구니는 빈 안내를 보인다', (tester) async {
      await _pumpLaundry(tester, _FlakyLaundryRepo(const []));
      expect(find.text('세탁할 옷이 없어요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    });
  });

  group('세탁 완료 처리 (FR-030)', () {
    testWidgets('진행 중에는 진행 문구를 보이고 반복 탭은 한 번만 처리한다', (tester) async {
      final repo = _FlakyLaundryRepo([_item(1), _item(2)])
        ..gate = Completer<void>();
      final container = await _pumpLaundry(tester, repo);
      container.read(laundrySelectionProvider.notifier).selectAll([1, 2]);
      await tester.pump();

      await tester.tap(find.text('선택 항목 세탁 완료 처리'));
      await tester.pump();
      expect(find.text('세탁 완료 처리 중…'), findsOneWidget);
      await tester.tap(find.text('세탁 완료 처리 중…'), warnIfMissed: false);
      await tester.pump();
      expect(repo.completeCalls, 1);

      repo.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('2점의 세탁이 완료됐어요'), findsOneWidget);
      expect(find.text('선택 항목 세탁 완료 처리'), findsOneWidget);
      await _drainToast(tester);
    });

    testWidgets('실패하면 오류 토스트를 띄우고 선택을 유지한다', (tester) async {
      final repo = _FlakyLaundryRepo([_item(1)])..failComplete = true;
      final container = await _pumpLaundry(tester, repo);
      container.read(laundrySelectionProvider.notifier).selectAll([1]);
      await tester.pump();

      await tester.tap(find.text('선택 항목 세탁 완료 처리'));
      await tester.pump();
      await tester.pump();
      expect(find.text('세탁 완료 처리에 실패했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(container.read(laundrySelectionProvider), {1});
      await _drainToast(tester);

      // 재시도 가능: 버튼이 다시 활성화된다.
      repo.failComplete = false;
      await tester.tap(find.text('선택 항목 세탁 완료 처리'));
      await tester.pump();
      await tester.pump();
      expect(repo.completeCalls, 2);
      await _drainToast(tester);
    });
  });

  testWidgets('홈 통계 읽기 실패는 0점이 아니라 실패 안내로 보인다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(_FailingStatsItemRepo()),
          laundryRepositoryProvider.overrideWithValue(
            _FlakyLaundryRepo(const []),
          ),
        ],
        child: MaterialApp(
          theme: buildClosetimoTheme(),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('옷장 정보를 불러오지 못했어요'), findsOneWidget);
    expect(find.byType(StatsRow), findsNothing);
  });

  testWidgets('다중 선택 바는 액션이 끝날 때까지 다른 액션을 막는다', (tester) async {
    final gate = Completer<void>();
    var runs = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildClosetimoTheme(),
        home: Scaffold(
          body: SelectionActionBar(
            count: 2,
            filterSummary: '전체',
            onSelectAll: () {},
            onClear: () {},
            onExit: () {},
            actions: [
              SelectionAction(
                label: '바구니에 담기',
                icon: Icons.add,
                onPressed: () async {
                  runs++;
                  await gate.future;
                },
              ),
              SelectionAction(
                label: '태그',
                icon: Icons.sell_outlined,
                onPressed: () => runs++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('바구니에 담기'));
    await tester.pump();
    expect(find.text('2개 처리 중…'), findsOneWidget);
    await tester.tap(find.text('바구니에 담기'));
    await tester.tap(find.text('태그'));
    await tester.pump();
    expect(runs, 1);

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('2개 선택'), findsOneWidget);
    await tester.tap(find.text('태그'));
    await tester.pump();
    expect(runs, 2);
  });

  group('ActionGuardMixin', () {
    testWidgets('진행 중 재진입을 막고 실패하면 오류 토스트를 띄운다', (tester) async {
      final harness = GlobalKey<_GuardHarnessState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildClosetimoTheme(),
          home: Scaffold(body: _GuardHarness(key: harness)),
        ),
      );
      final state = harness.currentState!;
      final gate = Completer<void>();
      var runs = 0;

      final first = state.runGuarded(() async {
        runs++;
        await gate.future;
      }, failureMessage: 'x');
      await tester.pump();
      expect(state.actionBusy, isTrue);
      expect(state.isActionBusy('action'), isTrue);
      expect(find.text('busy'), findsOneWidget);

      // 진행 중 두 번째 실행은 건너뛴다.
      expect(
        await state.runGuarded(() async => runs++, failureMessage: 'x'),
        isFalse,
      );
      expect(runs, 1);

      gate.complete();
      expect(await first, isTrue);
      await tester.pump();
      expect(state.actionBusy, isFalse);
      expect(find.text('idle'), findsOneWidget);

      final ok = await state.runGuarded(
        () async => throw StateError('write failed'),
        failureMessage: '저장하지 못했어요. 다시 시도해 주세요.',
      );
      await tester.pump();
      expect(ok, isFalse);
      expect(state.actionBusy, isFalse);
      expect(find.text('저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await _drainToast(tester);
    });
  });
}

class _GuardHarness extends StatefulWidget {
  const _GuardHarness({super.key});

  @override
  State<_GuardHarness> createState() => _GuardHarnessState();
}

class _GuardHarnessState extends State<_GuardHarness> with ActionGuardMixin {
  @override
  Widget build(BuildContext context) => Text(actionBusy ? 'busy' : 'idle');
}
