// #46 — 실제 Isar로 태그 저장·일괄 편집·이름 변경(병합)·삭제가 옷과 기록을
// 지우지 않고 태그만 바꾸는지 검증한다.

import 'dart:io';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/data/models/item_patch.dart';
import 'package:closetimo/data/models/item_tags.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/repositories/isar_archive_repository.dart';
import 'package:closetimo/data/repositories/isar_event_repository.dart';
import 'package:closetimo/data/repositories/isar_item_repository.dart';
import 'package:closetimo/data/repositories/isar_laundry_repository.dart';
import 'package:closetimo/data/repositories/isar_tag_repository.dart';
import 'package:closetimo/data/repositories/item_repository.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

import '../support/isar_plus_test_support.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 10, 17, 9);
}

void main() {
  setUpAll(initializeIsarPlusForTests);

  late Directory dir;
  late Isar isar;
  late IsarItemRepository items;
  late IsarTagRepository tags;
  late IsarEventRepository events;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('closetimo_tags');
    isar = Isar.open(
      schemas: [ItemSchema, WearEventSchema, UserPreferencesSchema],
      directory: dir.path,
      name: 'tags',
      inspector: false,
    );
    final clock = _FixedClock();
    items = IsarItemRepository(
      isar: isar,
      imageStore: ImageStore(overrideRoot: dir),
      clock: clock,
    );
    tags = IsarTagRepository(isar: isar);
    events = IsarEventRepository(isar: isar, clock: clock);
  });

  tearDown(() {
    if (isar.isOpen) isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<int> create(String name, {List<String> t = const []}) =>
      items.create(NewItemDraft(name: name, tags: t));

  List<String> tagsOf(int id) => isar.items.get(id)!.tags;

  ItemPatch patchFor(Item item, {List<String>? tags}) => ItemPatch(
    name: item.name,
    category: item.category,
    careMethod: item.careMethod,
    washCycle: item.washCycle,
    careMode: item.careMode,
    purposes: item.purposes,
    tags: tags,
  );

  test('등록 시 태그를 정규화해 저장하고 태그 없이도 등록된다', () async {
    final a = await create('셔츠', t: [' 여름 ', 'Black', 'black', '']);
    final b = await create('바지');
    expect(tagsOf(a), ['여름', 'Black']);
    expect(tagsOf(b), isEmpty);
  });

  test('수정에서 tags가 null이면 유지하고 목록이면 교체한다', () async {
    final a = await create('셔츠', t: ['여름']);
    await items.update(a, patchFor(isar.items.get(a)!));
    expect(tagsOf(a), ['여름']);
    await items.update(a, patchFor(isar.items.get(a)!, tags: ['겨울', '겨울']));
    expect(tagsOf(a), ['겨울']);
    await items.update(a, patchFor(isar.items.get(a)!, tags: []));
    expect(tagsOf(a), isEmpty);
  });

  test('여러 옷에 일괄로 붙이고 떼며 바뀐 옷 수를 돌려준다', () async {
    final a = await create('셔츠', t: ['여름']);
    final b = await create('바지');
    final c = await create('코트');

    expect(await tags.addTag({a, b, 999}, '여름'), 1); // a는 이미 있음
    expect(tagsOf(a), ['여름']);
    expect(tagsOf(b), ['여름']);
    expect(tagsOf(c), isEmpty);

    expect(await tags.removeTag({a, c}, '여름'), 1);
    expect(tagsOf(a), isEmpty);
    expect(tagsOf(b), ['여름']);

    expect(() => tags.addTag({a}, '  '), throwsArgumentError);
  });

  test('태그로 검색·필터링된다', () async {
    final a = await create('셔츠', t: ['여름']);
    await create('코트', t: ['겨울']);
    final filtered = await items
        .watchFiltered(
          filter: const ItemFilter(tags: {'여름'}),
          sort: WardrobeSort.mostWorn,
        )
        .first;
    expect(filtered.map((i) => i.id), [a]);
    final searched = await items
        .watchFiltered(
          filter: const ItemFilter(query: '겨'),
          sort: WardrobeSort.mostWorn,
        )
        .first;
    expect(searched.map((i) => i.name), ['코트']);
  });

  test('이름 변경은 모든 옷(보관 포함)에 반영되고 같은 이름이 있으면 병합한다', () async {
    final a = await create('셔츠', t: ['회사', '여름']);
    final b = await create('슬랙스', t: ['출근', '회사']);
    final c = await create('블레이저', t: ['출근']);
    await IsarArchiveRepository(isar: isar, clock: _FixedClock()).archive(c);

    expect(await tags.renameTag('회사', '출근'), 2);
    expect(tagsOf(a), ['출근', '여름']); // 원래 자리에 새 이름
    expect(tagsOf(b), ['출근']); // 중복 병합
    expect(tagsOf(c), ['출근']);

    final usage = summarizeTags(isar.items.where().findAll());
    expect(
      usage.first,
      const TagUsage(name: '출근', itemCount: 3, activeItemCount: 2),
    );

    expect(await tags.renameTag('출근', '출근'), 0);
    expect(() => tags.renameTag('출근', ' '), throwsArgumentError);
  });

  test('태그 삭제는 옷·착용 기록·카운터·바구니·보관 상태를 바꾸지 않는다', () async {
    final a = await create('셔츠', t: ['여름']);
    final b = await create('코트', t: ['여름', '겨울']);
    await events.recordWear(a, note: '출근');
    await events.recordWear(a);
    await IsarLaundryRepository(isar: isar, clock: _FixedClock()).toggle(a);
    await IsarArchiveRepository(isar: isar, clock: _FixedClock()).archive(b);
    final before = isar.items.get(a)!;

    expect(await tags.deleteTag('여름'), 2);

    final after = isar.items.get(a)!;
    expect(isar.items.count(), 2);
    expect(after.tags, isEmpty);
    expect(after.totalWears, before.totalWears);
    expect(after.wearSinceWash, before.wearSinceWash);
    expect(after.lastWornAt, before.lastWornAt);
    expect(after.status, before.status);
    expect(after.inLaundry, isTrue);
    expect(isar.items.get(b)!.tags, ['겨울']);
    expect(isar.items.get(b)!.isArchived, isTrue);
    final history = await events.watchForItem(a).first;
    expect(history, hasLength(2));
    expect(history.map((e) => e.note), contains('출근'));
  });

  group('대소문자 무시 (리뷰 #50)', () {
    test('removeTag·deleteTag·renameTag는 대소문자만 다른 태그도 대상으로 본다', () async {
      final a = await create('셔츠', t: ['Summer']);
      final b = await create('바지', t: ['summer']);

      expect(await tags.removeTag({a, b}, 'SUMMER'), 2);
      expect(tagsOf(a), isEmpty);
      expect(tagsOf(b), isEmpty);

      await tags.addTag({a}, 'Summer');
      await tags.addTag({b}, 'summer');
      expect(await tags.renameTag('SUMMER', '여름'), 2);
      expect(tagsOf(a), ['여름']);
      expect(tagsOf(b), ['여름']);

      await tags.addTag({a, b}, 'Black');
      await tags.addTag({a}, 'black'); // 이미 Black이 있으므로 그대로
      expect(tagsOf(a), ['여름', 'Black']);
      expect(await tags.deleteTag('bLaCk'), 2);
      expect(tagsOf(a), ['여름']);
      expect(tagsOf(b), ['여름']);
    });
  });

  group('여러 태그 일괄 편집 (리뷰 #50)', () {
    test('addTags는 한 번에 적용하고 바뀐 옷 수를 옷 단위로 센다', () async {
      final a = await create('셔츠', t: ['여름']);
      final b = await create('바지');

      expect(await tags.addTags({a, b}, ['여름', '검정']), 2);
      expect(tagsOf(a), ['여름', '검정']);
      expect(tagsOf(b), ['여름', '검정']);
      expect(await tags.addTags({a, b}, ['여름', '검정']), 0);
    });

    test('addTags는 빈 태그가 섞이면 아무것도 쓰지 않고 거부한다', () async {
      final a = await create('셔츠');
      expect(() => tags.addTags({a}, ['검정', '  ']), throwsArgumentError);
      expect(tagsOf(a), isEmpty);
    });

    test('removeTags는 옷 단위로 센다', () async {
      final a = await create('셔츠', t: ['여름', '검정']);
      final b = await create('바지', t: ['검정']);
      expect(await tags.removeTags({a, b}, ['여름', '검정']), 2);
      expect(tagsOf(a), isEmpty);
      expect(tagsOf(b), isEmpty);
    });
  });

  test('보관한 옷에는 recordWear가 기록하지 않는다 (리뷰 #50)', () async {
    final a = await create('셔츠');
    await IsarArchiveRepository(isar: isar, clock: _FixedClock()).archive(a);

    expect(await events.recordWear(a), isNull);

    final item = isar.items.get(a)!;
    expect(item.totalWears, 0);
    expect(item.lastWornAt, isNull);
    expect(await events.watchForItem(a).first, isEmpty);
  });
}
