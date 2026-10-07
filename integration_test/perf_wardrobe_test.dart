// T080 — 옷장 성능 검증.
//
// SC-004("옷 100점 상태에서 필터·정렬·검색 결과가 200ms 이내 표시")의 측정
// 근거를 만든다. 검색·필터·정렬 지연은 SC-004의 대상이고, 첫 프레임·스크롤
// 프레임은 별개 지표이므로 서로 섞어 판정하지 않는다.
//
// ── 측정 항목 ────────────────────────────────────────────────
//  A. 조건 변경부터 실제 repository 스트림 결과의 화면 레이아웃까지(SC-004).
//     5회 표본 모두 200ms 이내인지 확인한다.
//  B. 프레임 지연 (T080 대상, SC-004와 별개)
//     그리드 첫 프레임과 스크롤 중 프레임 빌드 시간을 잰다.
//     두 지표는 "화면이 얼마나 빨리 그려지는가"를, A는 "데이터가 얼마나 빨리
//     화면에 반영되는가"를 본다. 기준이 다르므로 판정도 분리한다.
//
// 실행 모드: 성능 판정은 profile 모드가 적절하다. debug 모드는 최적화가 없어
// 측정값이 실제보다 크게 나올 수 있다. debug로 실행한 결과는 반드시 그 사실을
// 함께 보고한다.
//   flutter drive --profile --driver=test_driver/integration_test.dart \
//     --target=integration_test/perf_wardrobe_test.dart -d <physical-device>
//
// 실행 (앱 데이터가 비어 있어야 하므로 사전에 시뮬레이터에서 앱 삭제 권장):
//   xcrun simctl uninstall booted com.closetimo.closetimoApp

import 'dart:io';

import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/providers/isar_provider.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/features/wardrobe/widgets/wardrobe_filter_bar.dart';
import 'package:closetimo/features/wardrobe/widgets/garment_tile.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/main.dart' as app;

/// SC-004 기준. 검증 없이 완화하지 않는다.
const int kSearchFilterBudgetMs = 200;

/// 시드 옷 수. spec SC-004가 정의한 컬렉션 규모.
const int kSeedItemCount = 100;

/// 각 시나리오 반복 횟수. 중앙값·최댓값을 보고하며 모든 표본에 기준을 적용한다.
const int kPerfRepeatCount = 5;

/// 측정 표본 모음. 샘플 단위는 마이크로초다(밀리초로 잴 경우 0으로 반올림된다).
class _PerfSample {
  _PerfSample(this.scenario, this.samples);

  final String scenario;

  /// 마이크로초 단위 표본.
  final List<int> samples;

  int get medianMicros {
    final sorted = [...samples]..sort();
    return sorted[sorted.length ~/ 2];
  }

  int get maxMicros => samples.reduce((a, b) => a > b ? a : b);

  double get medianMs => medianMicros / 1000;

  double get maxMs => maxMicros / 1000;

  bool get withinBudget => maxMicros <= kSearchFilterBudgetMs * 1000;
}

/// 엔진 프레임 지연과 UI·raster 스레드의 작업 시간을 따로 기록한다.
/// totalSpan은 vsync부터 raster 완료까지의 지연이며 FPS의 역수가 아니다.
class _FrameTimingSample {
  _FrameTimingSample(this.label, this.timings);

  final String label;
  final List<FrameTiming> timings;

  /// 60fps 예산. 프레임 하나에 주어지는 시간.
  static const int fpsBudgetMicros = 16667; // 16.67ms

  /// vsync 시작부터 raster 완료까지 지연의 중앙값/최댓값.
  double get medianMs => _medianMs(timings.map((t) => t.totalSpan));

  double get maxMs {
    final totals = timings
        .map((t) => t.totalSpan)
        .whereType<Duration>()
        .toList();
    if (totals.isEmpty) return 0;
    return totals.reduce((a, b) => a > b ? a : b).inMicroseconds / 1000;
  }

  double get medianBuildMs => _medianMs(timings.map((t) => t.buildDuration));

  double get medianRasterMs => _medianMs(timings.map((t) => t.rasterDuration));

  /// UI 또는 raster 작업이 60fps 예산을 넘긴 표본의 비율(%).
  double get overBudgetRatioPercent {
    if (timings.isEmpty) return 0;
    final over = timings
        .where(
          (t) =>
              t.buildDuration.inMicroseconds > fpsBudgetMicros ||
              t.rasterDuration.inMicroseconds > fpsBudgetMicros,
        )
        .length;
    return over / timings.length * 100;
  }

  /// nullable Duration 목록의 중앙값(밀리초).
  static double _medianMs(Iterable<Duration?> values) {
    final sorted = values.whereType<Duration>().toList()..sort();
    if (sorted.isEmpty) return 0;
    return sorted[sorted.length ~/ 2].inMicroseconds / 1000;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '옷 100점 기준 검색·필터·정렬 지연과 프레임 빌드를 측정한다',
    (tester) async {
      const mode = kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug';
      final report = <String>[
        '=== closetimo perf (T080 / SC-004) ===',
        'mode: $mode',
        'platform: ${Platform.operatingSystem} '
            '${Platform.operatingSystemVersion}',
        'seed items: $kSeedItemCount',
        'repeat: $kPerfRepeatCount',
        'SC-004 budget: ${kSearchFilterBudgetMs}ms '
            '(condition change to UI layout)',
        if (mode == 'debug')
          'WARNING: debug measurements require a profile rerun.',
      ];

      // main.dart의 진입점과 이름이 겹치므로 접두사로 호출한다.
      await app.main();
      await tester.pumpAndSettle();

      final isar = await _appIsar(tester);
      expect(
        isar.items.count(),
        0,
        reason: 'Performance tests require an empty dedicated test device.',
      );
      _seedItems(isar);
      final seeded = isar.items.count();
      report.add('seeded items: $seeded');
      expect(
        seeded,
        kSeedItemCount,
        reason: 'Expected exactly 100 seeded items.',
      );

      await tester.tap(find.text('옷장'));
      await tester.pumpAndSettle();
      expect(find.text('내 옷장'), findsOneWidget);

      // 조건 변경 콜백부터 production 스트림 결과의 레이아웃 완료까지 잰다.
      final samples = <_PerfSample>[
        await _measureUi(tester, 'category outer', category: Category.outer),
        await _measureUi(tester, 'category top', category: Category.top),
        await _measureUi(tester, 'search coat', query: '코트'),
        await _measureUi(tester, 'search brand', query: 'ZARA'),
        await _measureUi(
          tester,
          'sort clean',
          sort: WardrobeSort.statusCleanFirst,
        ),
        await _measureUi(
          tester,
          'sort recent',
          sort: WardrobeSort.recentlyWorn,
        ),
        await _measureUi(tester, 'sort wears', sort: WardrobeSort.mostWorn),
        await _measureUi(
          tester,
          'combined',
          category: Category.outer,
          query: '코트',
          sort: WardrobeSort.mostWorn,
        ),
      ];

      for (final s in samples) {
        report.add(
          '[SC-004] ${s.scenario}: median=${s.medianMs.toStringAsFixed(2)}ms '
          'max=${s.maxMs.toStringAsFixed(2)}ms '
          '${s.withinBudget ? "PASS" : "FAIL"} '
          '(samples ${s.samples.join(', ')}us)',
        );
      }

      // ── B. 프레임 지연 (T080, SC-004와 별개) ──────────
      // 엔진이 실제로 소비한 프레임 시간을 쓴다. 60fps 예산은 16.67ms/frame.
      final firstFrame = await _measureFirstFrame(tester);
      report.add(
        '[FRAME] ${firstFrame.label} ${firstFrame.timings.length} samples: '
        'total median=${firstFrame.medianMs.toStringAsFixed(2)}ms '
        'max=${firstFrame.maxMs.toStringAsFixed(2)}ms '
        '(build ${firstFrame.medianBuildMs.toStringAsFixed(2)}ms / '
        'raster ${firstFrame.medianRasterMs.toStringAsFixed(2)}ms)',
      );

      final scrollSample = await _measureScrollFrames(tester);
      report.add(
        '[FRAME] ${scrollSample.label} ${scrollSample.timings.length} samples: '
        'total median=${scrollSample.medianMs.toStringAsFixed(2)}ms '
        'max=${scrollSample.maxMs.toStringAsFixed(2)}ms '
        '(build ${scrollSample.medianBuildMs.toStringAsFixed(2)}ms / '
        'raster ${scrollSample.medianRasterMs.toStringAsFixed(2)}ms) '
        'frames over 60fps budget '
        '${scrollSample.overBudgetRatioPercent.toStringAsFixed(1)}%',
      );
      await binding.takeScreenshot('perf_wardrobe_100');

      final text = report.join('\n');
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['perfReport'] = text;
      debugPrint(text);
      await _writeReport(text);

      // ── 판정 ──────────────────────────────────────────
      // SC-004는 검색·필터·정렬 지연에만 적용한다. 첫 프레임·스크롤은 별도
      // 지표이므로 200ms 예산을 그대로 적용하지 않는다.
      final failed = samples
          .where((s) => !s.withinBudget)
          .map((s) => '${s.scenario} (max ${s.maxMs.toStringAsFixed(2)}ms)')
          .toList();
      expect(failed, isEmpty, reason: 'SC-004 budget exceeded: $failed\n$text');
      if (kProfileMode || kReleaseMode) {
        expect(
          firstFrame.maxMs,
          lessThanOrEqualTo(200),
          reason: 'Frame latency exceeded the T080 budget.',
        );
        expect(
          scrollSample.overBudgetRatioPercent,
          0,
          reason: 'Scroll build/raster samples exceeded the 60fps budget.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

/// 실행 중인 앱의 실제 Isar 인스턴스를 가져온다.
///
/// 별도 테스트 저장소를 만들지 않는다. 앱이 이미 열고 있는 인스턴스를 그대로
/// 재사용해야 실제 저장소 성능을 측정할 수 있다.
Future<Isar> _appIsar(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(app.ClosetimoApp)),
  );
  return container.read(isarProvider.future);
}

/// 옷 100점을 시드한다. 정렬·필터 분기를 모두 태우도록 상태를 섞는다.
void _seedItems(Isar isar) {
  final now = DateTime(2026, 5, 18);
  final items = <Item>[
    for (var i = 0; i < kSeedItemCount; i++)
      Item(
        name: i.isEven ? '캐시미어 코트 $i' : '린넨 셔츠 $i',
        brand: i.isEven ? 'ZARA' : 'COS',
        category: Category.values[i % 4],
        careMethod: CareMethod.values[i % 3],
        washCycle: 5,
        // 절반은 세탁 임계에 도달해 dirty 로 만든다.
        wearSinceWash: i.isEven ? 5 : 1,
        totalWears: i,
        lastWornAt: now.subtract(Duration(hours: i)),
        lastWashedAt: now.subtract(Duration(days: i % 7 + 1)),
        status: i.isEven ? ItemStatus.dirty : ItemStatus.clean,
        createdAt: now.subtract(Duration(hours: 100 - i)),
      ),
  ];
  isar.write((isar) {
    // Item의 id는 기본값 0이므로 그대로 putAll하면 마지막 1건만 남는다.
    // autoIncrement()로 고유 id를 부여해 100점을 실제로 저장한다.
    for (final item in items) {
      item.id = isar.items.autoIncrement();
    }
    isar.items.putAll(items);
  });
}

/// 복제 로직 없이 실제 조건 변경·repository 스트림·sliver 레이아웃을 측정한다.
///
/// 각 표본 전에는 검색 무결과 상태로 바꿔 이전 결과를 완료 신호로 오인하지 않는다.
/// 기대 결과는 측정 밖에서 production repository로 얻고, 렌더링된 타일의 ID와
/// 그리드 개수로 갱신 완료를 확인한다. GPU 표시 시각 자체를 측정하지는 않는다.
Future<_PerfSample> _measureUi(
  WidgetTester tester,
  String scenario, {
  Category? category,
  String query = '',
  WardrobeSort sort = WardrobeSort.statusCleanFirst,
}) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(app.ClosetimoApp)),
  );
  final expected = await container
      .read(itemRepositoryProvider)
      .watchFiltered(category: category, query: query, sort: sort)
      .first;
  expect(expected, isNotEmpty);
  final samples = <int>[];
  for (var i = 0; i < kPerfRepeatCount; i++) {
    var bar = tester.widget<WardrobeFilterBar>(find.byType(WardrobeFilterBar));
    bar.onQueryChanged('__no_results__');
    final resetWait = Stopwatch()..start();
    while (resetWait.elapsed < const Duration(seconds: 5)) {
      await tester.pump();
      if (find.text('검색 결과가 없습니다.').evaluate().isNotEmpty) break;
    }
    resetWait.stop();
    expect(
      find.text('검색 결과가 없습니다.'),
      findsOneWidget,
      reason: 'The reset stream did not finish.',
    );
    expect(find.byType(SliverGrid), findsNothing);
    bar = tester.widget<WardrobeFilterBar>(find.byType(WardrobeFilterBar));
    final sw = Stopwatch()..start();
    bar.onCategoryChanged(category);
    bar.onSortChanged(sort);
    bar.onQueryChanged(query);
    var reflected = false;
    while (sw.elapsed < const Duration(seconds: 5)) {
      await tester.pump();
      final grids = find.byType(SliverGrid);
      final tiles = find.byType(GarmentTile);
      if (grids.evaluate().isNotEmpty && tiles.evaluate().isNotEmpty) {
        final delegate =
            tester.widget<SliverGrid>(grids).delegate
                as SliverChildBuilderDelegate;
        reflected =
            delegate.childCount == expected.length &&
            tester.widget<GarmentTile>(tiles.first).item.id ==
                expected.first.id;
        if (reflected) break;
      }
    }
    sw.stop();
    expect(reflected, isTrue, reason: 'UI did not reflect $scenario');
    samples.add(sw.elapsedMicroseconds);
    debugPrint(
      'UI latency: $scenario sample=$i elapsed=${sw.elapsedMicroseconds}us',
    );
  }
  return _PerfSample(scenario, samples);
}

/// 검색어 변경 후 그리드가 다시 그려질 때까지의 엔진 실측 프레임 시간.
///
/// `tester.pump()`를 Stopwatch로 재는 방식은 **위젯 빌드 호출 시간**만 잰다.
/// 격자 레이아웃·페인트·GPU 업로드가 전혀 포함되지 않아 실제 화면 갱신보다
/// orders of magnitude 작게 나온다. 엔진이 실제로 소비한 시간을 보려면
/// `FrameTiming`의 build/raster/총 구간을 읽어야 한다.
Future<_FrameTimingSample> _measureFirstFrame(WidgetTester tester) async {
  final searchField = find.byType(TextField).first;
  await tester.ensureVisible(searchField);
  await tester.pumpAndSettle();

  final timings = <FrameTiming>[];
  final binding = SchedulerBinding.instance;
  void listener(List<FrameTiming> list) => timings.addAll(list);
  binding.addTimingsCallback(listener);
  final sw = Stopwatch()..start();
  try {
    await tester.enterText(searchField, '코트');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } finally {
    sw.stop();
    binding.removeTimingsCallback(listener);
  }
  if (timings.isEmpty) {
    throw StateError(
      'No engine FrameTiming collected (elapsed=${sw.elapsedMilliseconds}ms).',
    );
  }
  return _FrameTimingSample('search update frames', timings);
}

/// 스크롤 중 엔진이 소비한 프레임 시간을 모은다.
///
/// 그리드는 shrinkWrap + NeverScrollableScrollPhysics라 그리드 자체의 중심이
/// 스크롤을 감싼 상위 SingleChildScrollView 기준으로 화면 밖에 있을 수 있다.
/// 그 상태에서 `drag(grid, …)` 는 화면 밖 좌표를 계산해 실제 스크롤이 일어나지
/// 않는다(히트 테스트 경고가 난다). 따라서 화면 중앙을 기준으로 드래그한다.
Future<_FrameTimingSample> _measureScrollFrames(WidgetTester tester) async {
  // 옷장 그리드는 lazy sliver(SliverGrid)로 구현되어 있으므로 GridView가
  // 아니라 SliverGrid를 찾는다.
  await tester.ensureVisible(find.byType(SliverGrid).first);
  await tester.pumpAndSettle();

  final position = tester
      .widget<Scrollable>(find.byType(Scrollable).first)
      .controller
      ?.position;

  final timings = <FrameTiming>[];
  final binding = SchedulerBinding.instance;
  void listener(List<FrameTiming> list) => timings.addAll(list);
  binding.addTimingsCallback(listener);

  final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  try {
    for (var i = 0; i < 20; i++) {
      await tester.dragFrom(_screenCenter(tester), const Offset(0, -60));
      await tester.pump();
    }
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = previousFatal;
    binding.removeTimingsCallback(listener);
  }

  // 스크롤이 실제로 일어났는지 확인한다. 이동량이 0이면 위 표본은
  // "스크롤 프레임 지연"이 아니라 "제자리 프레임 지연"이므로 무효다.
  final moved = position?.pixels;
  if (moved == null || moved <= 0) {
    throw StateError('No scroll movement detected: pixels=$moved');
  }
  if (timings.isEmpty) {
    throw StateError('No engine FrameTiming collected during scroll.');
  }
  return _FrameTimingSample('scroll frames', timings);
}

/// 화면(logical view) 중앙 좌표.
Offset _screenCenter(WidgetTester tester) {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  return Offset(size.width / 2, size.height / 2);
}

/// 측정 리포트를 파일로 남긴다. 실패해도 원인을 분석할 수 있도록
/// 실패 사유를 로그로 남긴다.
///
/// 앱은 시뮬레이터/기기 안에서 실행되므로 호스트의 상대 경로(`build/…`)에
/// 쓸 수 없다. 앱 Documents 디렉토리에 저장하고 그 절대 경로를 보고한다.
Future<void> _writeReport(String report) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/perf_wardrobe_report.txt');
    await file.writeAsString('$report\n');
    debugPrint('Perf report written: ${file.path}');
  } on Object catch (error) {
    debugPrint('Failed to write perf report: $error');
  }
}
