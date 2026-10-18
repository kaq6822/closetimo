// #46 — 사용자 태그 정규화·집계 규칙. data-model.md §1.1c 참조.
//
// 태그는 색상·계절·장소처럼 사용자가 반복해서 찾는 단서를 자유롭게 붙이는
// 선택 속성이다. 관리 상태(세탁 필요·바구니·보관)와 관리 방법은 태그가 아니라
// 시스템 필드로 남긴다.

import 'package:characters/characters.dart';

import 'item.dart';

/// 태그 1개의 최대 길이(정규화 후 글자 수). 사용자가 보는 글자(grapheme cluster) 단위라
/// 이모지·결합 문자도 1글자로 세며, 입력창 `maxLength`와 같은 기준이다.
const int maxTagLength = 20;

/// 태그 1개를 정규화한다. 앞뒤 공백을 지우고 연속 공백을 하나로 줄이며,
/// 쉼표(입력 구분자·라우트 쿼리 구분자)는 공백으로 바꾼다. [maxTagLength]를
/// 넘으면 자른다. 빈 문자열이 되면 null.
String? normalizeTag(String raw) {
  final collapsed = raw
      .replaceAll(',', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (collapsed.isEmpty) return null;
  final chars = collapsed.characters;
  if (chars.length <= maxTagLength) return collapsed;
  return chars.take(maxTagLength).toString().trim();
}

/// 태그 목록을 정규화한다. 빈 값은 버리고, 대소문자만 다른 중복은 먼저 나온
/// 표기를 남긴다. 순서는 입력 순서를 유지한다.
List<String> normalizeTags(Iterable<String> raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final r in raw) {
    final tag = normalizeTag(r);
    if (tag == null) continue;
    if (seen.add(tag.toLowerCase())) result.add(tag);
  }
  return result;
}

/// 사용자가 한 번에 입력한 문자열("여름, 검정")을 쉼표로 나눠 태그 목록으로 만든다.
List<String> parseTagInput(String input) => normalizeTags(input.split(','));

/// 태그 1개의 사용 현황. 저장하지 않는 집계 값이다.
class TagUsage {
  const TagUsage({
    required this.name,
    required this.itemCount,
    required this.activeItemCount,
  });

  final String name;

  /// 이 태그가 붙은 옷 수(보관한 옷 포함). 태그 관리 화면에 쓴다.
  final int itemCount;

  /// 보관하지 않은 옷 중 이 태그가 붙은 옷 수. 옷장 필터에 쓴다.
  final int activeItemCount;

  @override
  bool operator ==(Object other) =>
      other is TagUsage &&
      other.name == name &&
      other.itemCount == itemCount &&
      other.activeItemCount == activeItemCount;

  @override
  int get hashCode => Object.hash(name, itemCount, activeItemCount);

  @override
  String toString() => 'TagUsage($name, $itemCount, $activeItemCount)';
}

/// 두 태그가 같은 태그인가(대소문자 무시). 필터·집계·일괄 편집이 같은 기준을 쓴다.
bool isSameTag(String a, String b) => a.toLowerCase() == b.toLowerCase();

/// 옷 목록에서 태그 사용 현황을 집계한다. 대소문자만 다른 표기는 하나로 모으고,
/// 이름은 가장 많이 쓰인 표기(같으면 사전순 앞)를 쓴다. 많이 쓴 순, 같으면 이름순.
List<TagUsage> summarizeTags(Iterable<Item> items) {
  final total = <String, int>{};
  final active = <String, int>{};
  final spellings = <String, Map<String, int>>{};
  for (final item in items) {
    // 한 옷 안의 대소문자 중복은 한 번만 센다.
    final seen = <String>{};
    for (final tag in item.tags) {
      final key = tag.toLowerCase();
      if (!seen.add(key)) continue;
      total[key] = (total[key] ?? 0) + 1;
      if (!item.isArchived) active[key] = (active[key] ?? 0) + 1;
      final forKey = spellings.putIfAbsent(key, () => {});
      forKey[tag] = (forKey[tag] ?? 0) + 1;
    }
  }
  final usages = [
    for (final e in total.entries)
      TagUsage(
        name: _canonicalSpelling(spellings[e.key]!),
        itemCount: e.value,
        activeItemCount: active[e.key] ?? 0,
      ),
  ];
  usages.sort((a, b) {
    final byCount = b.itemCount.compareTo(a.itemCount);
    return byCount != 0 ? byCount : a.name.compareTo(b.name);
  });
  return usages;
}

String _canonicalSpelling(Map<String, int> counts) {
  final names = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return names.first;
}
