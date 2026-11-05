// #43 — 옷장 필터 조건을 한 줄 문구로 요약한다(다중 선택 바 FR-008b).

import '../../data/models/item.dart';
import '../../data/models/item_attributes.dart';
import '../../data/models/item_filter.dart';

/// [filter]를 "상의 · 용도: 운동 · 입을 수 있음 · 검색 "니트"" 형태로 요약한다.
/// 조건이 없으면 "전체".
String describeItemFilter(ItemFilter filter) {
  final parts = <String>[];
  if (filter.groupBucket case final bucket?) {
    parts.add('${bucket.label} 전체');
  } else {
    final cats = filter.categories.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    parts.addAll(cats.map((c) => c.label));
  }
  // 005 — 세부 종류·색상·계절은 같은 축 안 OR이라 '또는'으로 잇는다.
  final subs = [
    for (final d in ItemAttributes.subTypes)
      if (filter.subTypes.contains(d.code)) d.label,
  ];
  if (subs.isNotEmpty) parts.add(subs.join(' 또는 '));
  final colors = [
    for (final d in ItemAttributes.colors)
      if (filter.colors.contains(d.code)) d.label,
  ];
  if (colors.isNotEmpty) parts.add('색상: ${colors.join(' 또는 ')}');
  final seasons = [
    for (final s in Season.values)
      if (filter.seasons.contains(s)) s.label,
  ];
  if (seasons.isNotEmpty) parts.add('계절: ${seasons.join(' 또는 ')}');
  final purposes = filter.purposes.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  parts.addAll(purposes.map((p) => '용도: ${p.label}'));
  // #46 — 같은 축 안은 OR임을 문구로 드러낸다.
  if (filter.tags.isNotEmpty) {
    parts.add('태그: ${(filter.tags.toList()..sort()).join(' 또는 ')}');
  }
  if (filter.readyToWear) parts.add('입을 수 있음');
  if (filter.season case final s?) parts.add('${s.label} 옷');
  final q = filter.query.trim();
  if (q.isNotEmpty) parts.add('검색 "$q"');
  return parts.isEmpty ? '전체' : parts.join(' · ');
}
