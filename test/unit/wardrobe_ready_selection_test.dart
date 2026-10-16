// #43 — '입을 수 있음' 필터 정의, 필터 요약 문구, 다중 선택 상태 전이 단위 테스트.

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_filter.dart';
import 'package:closetimo/features/wardrobe/filter_summary.dart';
import 'package:closetimo/features/wardrobe/selection/item_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item({
  ItemStatus status = ItemStatus.clean,
  bool inLaundry = false,
  CareMode careMode = CareMode.wearCycle,
  String name = '셔츠',
}) => Item(
  name: name,
  category: Category.top,
  washCycle: 3,
  createdAt: DateTime(2026, 10, 1),
  status: status,
  inLaundry: inLaundry,
  careMode: careMode,
);

void main() {
  group('ItemReadiness.isReadyToWear (FR-005a)', () {
    test('깨끗하고 바구니에 없으면 입을 수 있다', () {
      expect(_item().isReadyToWear, isTrue);
    });

    test('관리 권장(dirty)이면 제외된다', () {
      expect(_item(status: ItemStatus.dirty).isReadyToWear, isFalse);
    });

    test('세탁 바구니에 있으면 상태와 무관하게 제외된다', () {
      expect(_item(inLaundry: true).isReadyToWear, isFalse);
    });

    test('manual 관리 옷은 바구니에 없으면 포함된다', () {
      final manual = _item(careMode: CareMode.manual)..wearSinceWash = 9;
      expect(manual.isReadyToWear, isTrue);
    });
  });

  group('ItemFilter.readyToWear', () {
    test('다른 축과 AND로 결합한다', () {
      const filter = ItemFilter(readyToWear: true, query: '셔츠');
      expect(filter.matches(_item()), isTrue);
      expect(filter.matches(_item(inLaundry: true)), isFalse);
      expect(filter.matches(_item(name: '니트')), isFalse);
    });

    test('기본값은 false이고 켜면 hasScope·isActive가 된다', () {
      expect(const ItemFilter().readyToWear, isFalse);
      const ready = ItemFilter(readyToWear: true);
      expect(ready.hasScope, isTrue);
      expect(ready.isActive, isTrue);
    });

    test('copyWith·동등성에 반영된다', () {
      const base = ItemFilter();
      final ready = base.copyWith(readyToWear: true);
      expect(ready, isNot(base));
      expect(ready, const ItemFilter(readyToWear: true));
      expect(ready.hashCode, const ItemFilter(readyToWear: true).hashCode);
      expect(ready.copyWith(query: 'a').readyToWear, isTrue);
    });
  });

  group('describeItemFilter', () {
    test('조건이 없으면 전체', () {
      expect(describeItemFilter(const ItemFilter()), '전체');
    });

    test('종류·용도·입을 수 있음·검색어를 순서대로 잇는다', () {
      const filter = ItemFilter(
        categories: {Category.top},
        purposes: {ItemPurpose.sport},
        readyToWear: true,
        query: ' 니트 ',
      );
      expect(describeItemFilter(filter), '상의 · 용도: 운동 · 입을 수 있음 · 검색 "니트"');
    });

    test('홈 합산 범위는 "그 외 전체"로 표시한다', () {
      expect(
        describeItemFilter(ItemFilter.homeBucket(HomeBucket.others)),
        '그 외 전체',
      );
    });
  });

  group('ItemSelectionController (FR-008b)', () {
    late ProviderContainer container;
    ItemSelection read() => container.read(wardrobeSelectionProvider);
    ItemSelectionController ctl() =>
        container.read(wardrobeSelectionProvider.notifier);

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('기본은 비활성·0개', () {
      expect(read().active, isFalse);
      expect(read().count, 0);
    });

    test('start(id)는 모드를 켜고 그 옷을 선택한다', () {
      ctl().start(3);
      expect(read().active, isTrue);
      expect(read().ids, {3});
    });

    test('toggle은 선택을 반전하고 0개가 돼도 모드는 유지한다', () {
      ctl()
        ..start(1)
        ..toggle(2);
      expect(read().ids, {1, 2});
      ctl()
        ..toggle(1)
        ..toggle(2);
      expect(read().count, 0);
      expect(read().active, isTrue);
    });

    test('selectAll·clear·exit', () {
      ctl().selectAll([1, 2, 3]);
      expect(read().ids, {1, 2, 3});
      ctl().clear();
      expect(read().active, isTrue);
      expect(read().count, 0);
      ctl()
        ..selectAll([4])
        ..exit();
      expect(read(), const ItemSelection());
    });

    test('retainOnly는 목록에 남은 id만 유지한다', () {
      ctl().selectAll([1, 2, 3]);
      ctl().retainOnly([2, 3, 9]);
      expect(read().ids, {2, 3});
      expect(read().active, isTrue);
    });
  });
}
