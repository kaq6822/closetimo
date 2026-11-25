// 005 — 구조화 속성·사진 분석 위젯 테스트 공용 fake와 앱 하네스.
//
// repository 계약 자체는 실제 Isar 테스트(isar_item_repository_test 등)가 검증한다.
// 여기 fake는 화면 흐름 검증용으로 호출을 기록하고 값만 흉내 낸다.

import 'dart:async';
import 'dart:io';

import 'package:closetimo/app/router.dart';
import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/core/vision/color_extractor.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_attributes.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/data/repositories/laundry_repository.dart';
import 'package:closetimo/data/repositories/preferences_repository.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FixedClock implements Clock {
  FixedClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

/// 호출을 기록하는 옷 저장소. 속성은 앱 규칙(`ItemAttributeValues.applyTo`)으로 적용한다.
class FakeItemRepo implements ItemRepository {
  FakeItemRepo([List<Item>? items]) : items = items ?? [];

  final List<Item> items;
  final List<NewItemDraft> created = [];
  final List<(int, ItemPatch)> updated = [];
  final _changes = StreamController<List<Item>>.broadcast();
  int _nextId = 100;

  void _emit() => _changes.add(List.unmodifiable(items));

  @override
  Stream<List<Item>> watchAll() async* {
    yield List.unmodifiable(items);
    yield* _changes.stream;
  }

  @override
  Stream<List<Item>> watchFiltered({
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  }) => watchAll().map(
    (all) => [
      for (final i in all)
        if (filter.matches(i)) i,
    ],
  );

  @override
  Stream<List<Item>> watchRecentlyWorn({int limit = 2}) => const Stream.empty();

  @override
  Stream<WardrobeStats> watchStats() => watchAll().map((all) {
    final active = all.where((i) => !i.isArchived).toList();
    return WardrobeStats(
      total: active.length,
      clean: active.where((i) => i.status == ItemStatus.clean).length,
      dirty: active.where((i) => i.status == ItemStatus.dirty).length,
      perBucket: {
        for (final b in HomeBucket.values)
          b: active.where((i) => i.category.homeBucket == b).length,
      },
    );
  });

  @override
  Future<Item?> get(int id) async {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<int> create(NewItemDraft draft) async {
    created.add(draft);
    final id = _nextId++;
    final item = Item(
      name: draft.name,
      category: draft.category,
      washCycle: draft.washCycle,
      purposes: draft.purposes,
      createdAt: DateTime(2026, 11, 1),
      imagePath: draft.tempPhoto == null ? null : 'items/$id.jpg',
      cutoutPath: draft.tempPhoto != null && draft.tempCutout != null
          ? 'items/${id}_cutout.png'
          : null,
    )..id = id;
    draft.attributes.applyTo(item);
    items.add(item);
    _emit();
    return id;
  }

  @override
  Future<void> update(int id, ItemPatch patch) async {
    updated.add((id, patch));
    final item = await get(id);
    if (item == null) return;
    item
      ..name = patch.name
      ..category = patch.category
      ..purposes = patch.purposes;
    (patch.attributes ?? ItemAttributeValues.of(item)).applyTo(item);
    _emit();
  }

  @override
  Future<void> delete(int id) async {
    items.removeWhere((i) => i.id == id);
    _emit();
  }
}

class BatchCall {
  BatchCall(this.ids, this.wornOn, this.note);
  final List<int> ids;
  final DateTime? wornOn;
  final String? note;
}

class RecordingEventRepo implements EventRepository {
  final List<BatchCall> batches = [];
  final List<List<int>> undone = [];

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(const []);

  @override
  Future<int?> recordWear(int itemId, {String? note, DateTime? wornOn}) async =>
      1;

  @override
  Future<WearBatchResult> recordWearBatch(
    Iterable<int> itemIds, {
    DateTime? wornOn,
    String? note,
  }) async {
    final ids = itemIds.toList();
    batches.add(BatchCall(ids, wornOn, note));
    return WearBatchResult(
      eventIds: [for (var i = 0; i < ids.length; i++) 500 + i],
      skipped: 0,
    );
  }

  @override
  Future<void> deleteWearEvents(Iterable<int> eventIds) async =>
      undone.add(eventIds.toList());

  @override
  Future<void> updateWearDate(int eventId, DateTime wornOn) async {}
  @override
  Future<void> updateEventNote(int eventId, String? note) async {}
  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

class FakeLaundryRepo implements LaundryRepository {
  FakeLaundryRepo([this.basket = const []]);

  final List<Item> basket;
  final List<List<int>> completed = [];

  @override
  Stream<List<Item>> watchBasket() => Stream.value(basket);
  @override
  Future<void> toggle(int itemId) async {}
  @override
  Future<int> completeWashFor(List<int> itemIds) async {
    completed.add(itemIds);
    return itemIds.length;
  }
}

class FakePrefsRepo implements PreferencesRepository {
  FakePrefsRepo([UserPreferences? prefs]) : prefs = prefs ?? UserPreferences();

  UserPreferences prefs;
  final _changes = StreamController<UserPreferences>.broadcast();

  @override
  Stream<UserPreferences> watch() async* {
    yield prefs;
    yield* _changes.stream;
  }

  void _set(void Function(UserPreferences) f) {
    f(prefs);
    _changes.add(prefs);
  }

  @override
  Future<void> setNotifWash(bool v) async => _set((p) => p.notifWash = v);
  @override
  Future<void> setNotifWeekly(bool v) async => _set((p) => p.notifWeekly = v);
  @override
  Future<void> setNotifUnworn(bool v) async => _set((p) => p.notifUnworn = v);
  @override
  Future<void> setAccent(String accentKey) async =>
      _set((p) => p.accent = accentKey);
  @override
  Future<void> setLastTab(String tab) async => _set((p) => p.lastTab = tab);
  @override
  Future<void> setRemoveBackground(bool v) async =>
      _set((p) => p.removeBackground = v);
  @override
  Future<void> setOnDeviceAi(bool v) async => _set((p) => p.onDeviceAi = v);
}

/// 네이티브 채널 fake. [analysisFor]로 사진마다 결과를 정한다.
class FakeVision implements NativeVision {
  FakeVision({
    this.caps = VisionCapabilities.none,
    this.analysisFor,
    this.description,
  });

  VisionCapabilities caps;
  NativeAnalysis Function(File photo)? analysisFor;
  OnDeviceDescription? description;

  /// 지정하면 [analyze]가 이 Future가 끝날 때까지 기다린다(분석 도중 화면 이탈 재현용).
  Future<void>? analyzeGate;
  final List<String> analyzed = [];
  int prewarmCalls = 0;
  Map<String, List<String>>? lastSchema;

  @override
  Future<VisionCapabilities> capabilities() async => caps;

  @override
  Future<NativeAnalysis> analyze(
    File photo, {
    required bool removeBackground,
  }) async {
    analyzed.add(photo.path);
    if (analyzeGate case final gate?) await gate;
    return analysisFor?.call(photo) ?? const NativeAnalysis();
  }

  @override
  Future<OnDeviceDescription> describe(
    File photo, {
    Map<String, List<String>> schema = const {},
  }) async {
    lastSchema = schema;
    return description ?? (throw UnsupportedError('no AI'));
  }

  @override
  Future<void> prewarm() async => prewarmCalls++;
}

/// 사진 경로마다 정한 색을 돌려주는 색상 추출 fake.
class FakeColors implements ColorExtractor {
  FakeColors([this.colors = const []]);

  List<String> colors;

  @override
  Future<List<String>> extract(
    Uint8List bytes,
    Map<String, int> palette,
  ) async => colors;
}

/// 1×1 PNG. 사진 파일이 실제 이미지여야 Image 위젯이 디코딩 오류를 내지 않는다.
final Uint8List onePixelPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x02, 0x00,
  0x00, 0x05, 0x00, 0x01, 0xE9, 0xFA, 0xDC, 0xD8, 0x00, 0x00, 0x00, 0x00,
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// image_picker 플랫폼 채널을 가로채 정해진 파일 경로를 돌려준다.
void mockImagePicker({String? single, List<String> multi = const []}) {
  const channel = MethodChannel('plugins.flutter.io/image_picker');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'pickImage':
            return single;
          case 'pickMultiImage':
          case 'pickMultipleMedia':
            return multi;
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
}

void phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2408);
  tester.view.devicePixelRatio = 2.8125;
  addTearDown(tester.view.reset);
}

/// 실제 라우트 표([goRouterProvider])로 앱을 띄운다.
Widget testApp({
  required FakeItemRepo items,
  RecordingEventRepo? events,
  FakeLaundryRepo? laundry,
  FakePrefsRepo? prefs,
  FakeVision? vision,
  FakeColors? colors,
  DateTime? now,
  List<Override> extra = const [],
}) {
  final visionFake = vision ?? FakeVision();
  return ProviderScope(
    overrides: [
      itemRepositoryProvider.overrideWithValue(items),
      eventRepositoryProvider.overrideWithValue(events ?? RecordingEventRepo()),
      laundryRepositoryProvider.overrideWithValue(laundry ?? FakeLaundryRepo()),
      preferencesRepositoryProvider.overrideWithValue(prefs ?? FakePrefsRepo()),
      clockProvider.overrideWithValue(
        FixedClock(now ?? DateTime(2026, 11, 2, 9)),
      ),
      imageStoreProvider.overrideWithValue(
        ImageStore(overrideRoot: Directory.systemTemp),
      ),
      nativeVisionProvider.overrideWithValue(visionFake),
      attributeSuggesterProvider.overrideWithValue(
        AttributeSuggester(
          vision: visionFake,
          colorExtractor: colors ?? FakeColors(),
        ),
      ),
      tagUsageProvider.overrideWith((ref) => Stream.value(const [])),
      ...extra,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        // 라우터는 prefs가 준비된 뒤 만든다(앱 부트와 같은 순서).
        final ready = ref.watch(preferencesStreamProvider).hasValue;
        if (!ready) return const SizedBox.shrink();
        return MaterialApp.router(
          theme: buildClosetimoTheme(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko', 'KR')],
          routerConfig: ref.watch(goRouterProvider),
        );
      },
    ),
  );
}

/// 현재 라우터 위치.
Uri currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Navigator).first),
).routeInformationProvider.value.uri;

Item testItem(
  int id,
  String name, {
  Category category = Category.top,
  String? subType,
  List<String> colors = const [],
  List<Season> seasons = const [],
  DateTime? lastWornAt,
  int totalWears = 0,
  bool inLaundry = false,
  CareMethod careMethod = CareMethod.unspecified,
  DateTime? createdAt,
}) => Item(
  name: name,
  category: category,
  washCycle: 5,
  createdAt: createdAt ?? DateTime(2026, 10, id),
  subType: subType,
  colors: colors,
  seasons: seasons,
  lastWornAt: lastWornAt,
  totalWears: totalWears,
  inLaundry: inLaundry,
  careMethod: careMethod,
)..id = id;

/// 토스트 타이머를 흘려보낸다.
Future<void> drainToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
