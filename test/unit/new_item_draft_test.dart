// 002 T002 — NewItemDraft.fromItem prefill 계약.
// item_edit_delete_test.dart에서 이전됨(순수 모델 로직이라 test/unit 소속).

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item({required int id, String name = '코트', int washCycle = 5}) => Item(
  name: name,
  category: Category.outer,
  washCycle: washCycle,
  createdAt: DateTime(2026, 1, 1),
)..id = id;

void main() {
  test('NewItemDraft.fromItem이 편집 가능 필드를 그대로 옮긴다', () {
    final item = _item(id: 1, name: '린넨 셔츠', washCycle: 7)
      ..brand = 'COS'
      ..careMethod = CareMethod.handWash
      ..category = Category.top;
    final draft = NewItemDraft.fromItem(item);

    expect(draft.name, '린넨 셔츠');
    expect(draft.brand, 'COS');
    expect(draft.category, Category.top);
    expect(draft.washCycle, 7);
    expect(draft.careMethod, CareMethod.handWash);
    expect(draft.tempPhoto, isNull);
  });
}
