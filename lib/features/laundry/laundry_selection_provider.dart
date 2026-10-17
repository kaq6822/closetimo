// US4 T061 — 세탁 바구니 선택 상태(화면 단위).

import 'package:flutter_riverpod/flutter_riverpod.dart';

class LaundrySelectionNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void toggle(int id) {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void selectAll(Iterable<int> ids) {
    state = {...ids};
  }

  /// 현재 바구니에 남아 있는 id만 선택 상태로 유지한다.
  void retainOnly(Iterable<int> basketIds) {
    final keep = basketIds.toSet();
    if (state.every(keep.contains)) return;
    state = state.where(keep.contains).toSet();
  }

  void clear() => state = const <int>{};
}

final laundrySelectionProvider =
    NotifierProvider<LaundrySelectionNotifier, Set<int>>(
      LaundrySelectionNotifier.new,
    );
