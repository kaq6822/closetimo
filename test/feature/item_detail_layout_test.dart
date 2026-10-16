// #47 FR-009a — 상세 첫 화면에서 이름·상태·주요 기록 액션에 닿는지 검증한다.
// 사진 없는 옷은 3:4 빈 영역 대신 짧은 헤더를, 사진 있는 옷은 높이 제한된 사진을
// 쓰며 정상(390×844)·좁은(320×568) 화면 모두 "착용 기록하기"가 스크롤 없이 보인다.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/widgets/primary_button.dart';
import 'package:closetimo/core/widgets/soft_button.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/features/item_detail/item_detail_screen.dart';
import 'package:closetimo/features/item_detail/widgets/hero_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeItemRepo implements ItemRepository {
  _FakeItemRepo(this.item);
  final Item item;

  @override
  Future<Item?> get(int id) async => id == item.id ? item : null;
  @override
  Future<int> create(_) async => throw UnimplementedError();
  @override
  Future<void> update(int id, ItemPatch patch) async =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) async => throw UnimplementedError();
  @override
  Stream<List<Item>> watchAll() => const Stream.empty();
  @override
  Stream<List<Item>> watchFiltered({
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  }) => const Stream.empty();
  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();
  @override
  Stream<WardrobeStats> watchStats() => const Stream.empty();
}

class _FakeEventRepo implements EventRepository {
  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(const []);
  @override
  Future<void> recordWear(int itemId, {String? note}) async {}
  @override
  Future<void> updateEventNote(int eventId, String? note) async {}
  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

class _FakeLaundryRepo implements LaundryRepository {
  @override
  Stream<List<Item>> watchBasket() => const Stream.empty();
  @override
  Future<void> toggle(int itemId) async {}
  @override
  Future<int> completeWashFor(List<int> itemIds) async => itemIds.length;
}

Item _item({String? imagePath, ItemStatus status = ItemStatus.clean}) => Item(
  name: '오버사이즈 캐시미어 코트',
  brand: 'ZARA',
  category: Category.accessory,
  careMethod: CareMethod.dryClean,
  washCycle: 5,
  imagePath: imagePath,
  status: status,
  createdAt: DateTime(2026, 1, 1),
)..id = 1;

Future<void> _pump(WidgetTester tester, Item item, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/item/1',
    routes: [
      GoRoute(
        path: '/item/:id',
        builder: (ctx, st) =>
            ItemDetailScreen(id: int.parse(st.pathParameters['id']!)),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(_FakeItemRepo(item)),
        eventRepositoryProvider.overrideWithValue(_FakeEventRepo()),
        laundryRepositoryProvider.overrideWithValue(_FakeLaundryRepo()),
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
    ),
  );
  await tester.pumpAndSettle();
}

const _normal = Size(390, 844);
const _narrow = Size(320, 568);

/// 위젯 전체가 스크롤 없이 화면 안에 보이는지.
void _expectOnFirstScreen(WidgetTester tester, Finder finder, Size size) {
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0), reason: '$finder $rect');
  expect(rect.bottom, lessThanOrEqualTo(size.height), reason: '$finder $rect');
}

void main() {
  for (final size in [_normal, _narrow]) {
    final label = '${size.width.toInt()}×${size.height.toInt()}';

    testWidgets('사진 없는 옷: 짧은 헤더 뒤 이름·상태·기록 액션이 첫 화면에 ($label)', (
      tester,
    ) async {
      await _pump(tester, _item(), size);

      // 3:4 빈 영역 대신 짧은 스와치 헤더.
      expect(find.byKey(const ValueKey('detail-compact-swatch')), findsOne);
      final heroHeight = tester.getSize(find.byType(HeroImage)).height;
      expect(heroHeight, lessThan(size.width / 2));

      _expectOnFirstScreen(tester, find.text('오버사이즈 캐시미어 코트'), size);
      _expectOnFirstScreen(tester, find.text('깨끗함'), size);
      _expectOnFirstScreen(
        tester,
        find.widgetWithText(PrimaryButton, '착용 기록하기'),
        size,
      );
      _expectOnFirstScreen(
        tester,
        find.widgetWithText(SoftButton, '세탁 바구니'),
        size,
      );
      // 브랜드는 헤더에 유지된다.
      expect(find.text('ZARA'), findsOne);
    });

    testWidgets('사진 있는 옷: 사진을 유지하되 기록 액션이 첫 화면에 ($label)', (tester) async {
      await _pump(tester, _item(imagePath: 'items/1.jpg'), size);

      expect(find.byKey(const ValueKey('detail-compact-swatch')), findsNothing);
      final heroHeight = tester.getSize(find.byType(HeroImage)).height;
      expect(
        heroHeight,
        lessThanOrEqualTo(size.height * HeroImage.maxScreenHeightFraction),
      );
      // 사진 영역이 의미 있는 크기로 남는다(빈 헤더로 축소되지 않음).
      expect(
        heroHeight,
        greaterThanOrEqualTo(
          size.height * HeroImage.minScreenHeightFraction,
        ),
      );

      _expectOnFirstScreen(
        tester,
        find.widgetWithText(PrimaryButton, '착용 기록하기'),
        size,
      );
    });
  }

  test('사진 최대 높이: 정상 화면 45%, 좁은 화면은 액션 몫을 남기되 최소 30%', () {
    expect(HeroImage.maxHeightFor(844), closeTo(844 * 0.45, 0.01));
    expect(HeroImage.maxHeightFor(568), closeTo(568 - 380, 0.01));
    expect(HeroImage.maxHeightFor(400), closeTo(400 * 0.3, 0.01));
  });

  testWidgets('세탁 필요 상태는 이름 아래 상태 라벨로 보인다', (tester) async {
    await _pump(tester, _item(status: ItemStatus.dirty), _normal);
    expect(find.text('세탁 필요'), findsOne);
    final nameBottom = tester.getRect(find.text('오버사이즈 캐시미어 코트')).bottom;
    final labelTop = tester.getRect(find.text('세탁 필요')).top;
    final buttonTop = tester
        .getRect(find.widgetWithText(PrimaryButton, '착용 기록하기'))
        .top;
    expect(labelTop, greaterThan(nameBottom));
    expect(labelTop, lessThan(buttonTop));
  });
}
