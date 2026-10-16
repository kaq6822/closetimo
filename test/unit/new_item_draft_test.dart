// 002 T002 — NewItemDraft.fromItem prefill 계약.
// item_edit_delete_test.dart에서 이전됨(순수 모델 로직이라 test/unit 소속).

import 'dart:io';

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

  group('#42 빠른 등록 규칙', () {
    test('기본 카테고리는 기타(미분류)다', () {
      expect(const NewItemDraft().category, Category.etc);
    });

    test('명칭도 사진도 없으면 빠른 저장 불가', () {
      const draft = NewItemDraft(name: '   ');
      expect(draft.canSave, isFalse);
      expect(draft.canQuickSave, isFalse);
    });

    test('사진만 있으면 빠른 저장 가능하고 "이름 없는 옷"으로 채운다', () {
      final draft = NewItemDraft(tempPhoto: File('photo.jpg'));
      expect(draft.canSave, isFalse); // 수정 모드 기준은 여전히 명칭 필수
      expect(draft.canQuickSave, isTrue);
      final created = draft.forCreate();
      expect(created.name, NewItemDraft.untitledName);
      expect(created.tempPhoto, same(draft.tempPhoto));
    });

    test('명칭이 있으면 forCreate는 그대로 둔다', () {
      const draft = NewItemDraft(name: '흰 셔츠');
      expect(draft.canQuickSave, isTrue);
      expect(draft.forCreate(), draft);
    });
  });
}
