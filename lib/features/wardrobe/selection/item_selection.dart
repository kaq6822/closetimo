// #43 — 옷장 다중 선택 상태(spec FR-008b).
//
// 다중 착용 기록(#39)·일괄 편집(#46)이 이 상태와 [SelectionActionBar]를 재사용한다.
// 재사용 규칙은 lib/features/AGENTS.md "옷장 다중 선택 인프라" 절 참조.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 다중 선택 모드 여부와 선택된 옷 id 집합. 불변 값 객체다.
@immutable
class ItemSelection {
  const ItemSelection({this.active = false, this.ids = const {}});

  /// 선택 모드가 켜져 있는지. 0개 선택이어도 모드는 유지될 수 있다.
  final bool active;

  /// 선택된 옷 id. 모드가 꺼져 있으면 항상 비어 있다.
  final Set<int> ids;

  int get count => ids.length;

  bool contains(int id) => ids.contains(id);

  @override
  bool operator ==(Object other) =>
      other is ItemSelection &&
      other.active == active &&
      other.ids.length == ids.length &&
      other.ids.containsAll(ids);

  @override
  int get hashCode => Object.hash(active, Object.hashAllUnordered(ids));
}

/// 선택 상태 전이. 화면은 [wardrobeSelectionProvider]로 구독한다.
class ItemSelectionController extends Notifier<ItemSelection> {
  @override
  ItemSelection build() => const ItemSelection();

  /// 선택 모드에 들어간다. [initialId]가 있으면 그 옷을 선택한 채로 시작한다
  /// (타일 길게 누르기).
  void start([int? initialId]) {
    state = ItemSelection(active: true, ids: {...state.ids, ?initialId});
  }

  /// [id]의 선택을 반전한다. 모드가 꺼져 있으면 모드를 켜고 선택한다.
  void toggle(int id) {
    final next = {...state.ids};
    if (!next.add(id)) next.remove(id);
    state = ItemSelection(active: true, ids: next);
  }

  /// 현재 보이는 목록 전체를 선택한다.
  void selectAll(Iterable<int> ids) {
    state = ItemSelection(active: true, ids: {...ids});
  }

  /// 선택만 비우고 모드는 유지한다("선택 초기화").
  void clear() {
    state = ItemSelection(active: state.active);
  }

  /// 모드를 끄고 선택을 모두 비운다("종료", 액션 완료 후).
  void exit() {
    state = const ItemSelection();
  }

  /// 목록에 남아 있는 id만 선택으로 유지한다. 필터·검색 변경이나 삭제로
  /// 보이지 않게 된 옷을 액션 대상에서 빼기 위해 목록이 갱신될 때마다 부른다.
  void retainOnly(Iterable<int> visibleIds) {
    final keep = visibleIds.toSet();
    if (state.ids.every(keep.contains)) return;
    state = ItemSelection(
      active: state.active,
      ids: state.ids.where(keep.contains).toSet(),
    );
  }
}

/// 옷장 화면의 다중 선택 상태. 옷장 브랜치 State처럼 탭 전환 사이에도 유지된다.
final wardrobeSelectionProvider =
    NotifierProvider<ItemSelectionController, ItemSelection>(
      ItemSelectionController.new,
    );
