// 005 FR-505·506 — 여러 장 등록에서 나온 사진 제안(종류·세부 종류)을 정리하기 카드까지 넘긴다.
//
// 여러 장 등록은 옷을 미분류로 만들고(사진·배경 제거본·색상·자동 이름만 저장), 사진 분석의 종류 제안은
// 여기에 옷 id별로 둔다. 정리하기 카드는 미분류 옷이면 이 제안을 미리 선택해 보여 주고, 사용자가
// "저장하고 다음"을 눌렀을 때만 저장한다. "나중에"로 넘긴 옷은 미분류로 남아 홈 정리 대기에 잡힌다.
// 제안일 뿐이라 메모리에만 두며, 앱을 다시 시작하면 사라진다.
// 저장·삭제·보관·종류 변경으로 처리가 끝난 옷의 제안은 정리하기 화면에 들어올 때
// [pruneBatchSuggestions]로 걷어 낸다(아직 미분류인 옷의 제안만 남긴다).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/suggestions/attribute_suggester.dart';

final batchSuggestionsProvider = StateProvider<Map<int, AttributeSuggestion>>(
  (ref) => const {},
);

/// [suggestions]에서 [pendingIds](보관하지 않은 미분류 옷 id)에 든 제안만 남긴다.
///
/// 지울 것이 없으면 같은 인스턴스를 돌려줘 불필요한 상태 갱신을 막는다.
Map<int, AttributeSuggestion> pruneBatchSuggestions(
  Map<int, AttributeSuggestion> suggestions,
  Set<int> pendingIds,
) {
  if (suggestions.keys.every(pendingIds.contains)) return suggestions;
  return {
    for (final e in suggestions.entries)
      if (pendingIds.contains(e.key)) e.key: e.value,
  };
}
