// 005 #58 — 여러 장 등록 사진 제안 정리 규칙.

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:closetimo/features/add_item/batch_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hint = AttributeSuggestion(category: Category.top, subType: 'tshirt');

  test('미분류로 남은 옷의 제안만 남긴다', () {
    final pruned = pruneBatchSuggestions(
      const {1: hint, 2: hint, 3: hint},
      {1, 3, 7},
    );
    expect(pruned.keys, unorderedEquals([1, 3]));
    expect(pruned[1], same(hint));
  });

  test('지울 것이 없으면 같은 인스턴스를 돌려준다', () {
    const all = {1: hint, 2: hint};
    expect(pruneBatchSuggestions(all, {1, 2, 3}), same(all));
    const empty = <int, AttributeSuggestion>{};
    expect(pruneBatchSuggestions(empty, const {}), same(empty));
  });

  test('미분류 옷이 없으면 모두 지운다', () {
    expect(pruneBatchSuggestions(const {1: hint}, const {}), isEmpty);
  });
}
