// #47 FR-021 — 홈 세탁 바구니 미리보기: 실제 썸네일, 전체 대기 수, 세탁 화면 이동,
// 빈 바구니 안내를 정상(390×844)·좁은(320×568) 화면에서 검증한다.

import 'dart:io';

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/home/widgets/laundry_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeLaundryRepo implements LaundryRepository {
  _FakeLaundryRepo(this.items);
  final List<Item> items;

  @override
  Stream<List<Item>> watchBasket() => Stream.value(items);
  @override
  Future<void> toggle(int itemId) async {}
  @override
  Future<void> completeWashFor(List<int> itemIds) async {}
}

Item _item(int id, {String? imagePath}) => Item(
  name: '바구니 옷 $id',
  category: Category.top,
  washCycle: 5,
  wearSinceWash: 3,
  inLaundry: true,
  imagePath: imagePath,
  createdAt: DateTime(2026, 1, 1),
)..id = id;

Future<void> _pump(
  WidgetTester tester,
  List<Item> basket, {
  Size size = const Size(390, 844),
  ImageStore? store,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        name: Routes.home,
        builder: (ctx, st) => const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(22.4),
            child: LaundryPreview(),
          ),
        ),
      ),
      GoRoute(
        path: '/laundry',
        name: Routes.laundry,
        builder: (ctx, st) => const Scaffold(body: Text('LAUNDRY_SCREEN')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        laundryRepositoryProvider.overrideWithValue(_FakeLaundryRepo(basket)),
        imageStoreProvider.overrideWithValue(store ?? ImageStore()),
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
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('laundry_preview_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('빈 바구니는 대기 항목과 구분되는 안내를 보여준다 ($label)', (tester) async {
      await _pump(tester, const [], size: size);

      expect(find.textContaining('바구니가 비어 있어요'), findsOne);
      expect(find.textContaining('점 대기'), findsNothing);
      expect(find.textContaining('바구니 옷'), findsNothing);
      // 빈 상태에서도 세탁 화면 이동 경로는 남는다.
      expect(find.text('세탁 화면으로 ›'), findsOne);
    });

    testWidgets('대기 수·외 N점·미리보기 3점을 보여준다 ($label)', (tester) async {
      await _pump(tester, [for (var i = 1; i <= 5; i++) _item(i)], size: size);

      expect(find.text('5점 대기'), findsOne);
      expect(find.text('외 2점'), findsOne);
      expect(find.textContaining('바구니 옷'), findsNWidgets(3));
      expect(find.textContaining('바구니가 비어 있어요'), findsNothing);
    });
  }

  testWidgets('3점 이하면 "외 N점"을 표시하지 않는다', (tester) async {
    await _pump(tester, [_item(1), _item(2)]);
    expect(find.text('2점 대기'), findsOne);
    expect(find.textContaining('외 '), findsNothing);
  });

  testWidgets('"세탁 화면으로"를 누르면 세탁 탭으로 이동한다', (tester) async {
    await _pump(tester, [_item(1)]);
    await tester.tap(find.text('세탁 화면으로 ›'));
    await tester.pumpAndSettle();
    expect(find.text('LAUNDRY_SCREEN'), findsOne);
  });

  testWidgets('사진이 있는 옷은 실제 썸네일을, 없는 옷은 대표 색상을 쓴다', (tester) async {
    File('${tmp.path}/1.jpg').writeAsBytesSync(const [0, 1, 2, 3]);
    await _pump(tester, [
      _item(1, imagePath: 'items/1.jpg'),
      _item(2),
    ], store: ImageStore(overrideRoot: tmp));

    final photo = find.byKey(const ValueKey('laundry-preview-photo'));
    expect(photo, findsOne);
    final image = tester.widget<Image>(photo);
    expect((image.image as ResizeImage).imageProvider, isA<FileImage>());
  });
}
