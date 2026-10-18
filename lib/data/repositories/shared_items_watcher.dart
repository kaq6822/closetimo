// #53 — 옷 컬렉션 전체 watch를 한 번만 구독해 여러 repository가 공유한다.
//
// Isar Plus는 인덱스 조건 watch가 조건 밖으로 나가는 수정을 방출하지 않아(#48)
// 세탁 바구니·보관함·최근 착용·옷장·통계가 모두 "전체 구독 + Dart 필터"를 쓴다.
// 화면마다 따로 구독하면 변경 1건마다 전체 쿼리가 중복 실행되므로, 구독자가
// 있는 동안 업스트림 구독 1개를 유지하고 마지막 값을 새 구독자에게 바로 준다.

import 'dart:async';

import 'package:isar_plus/isar_plus.dart';

import '../models/item.dart';

class SharedItemsWatcher {
  SharedItemsWatcher(this._isar);

  final Isar _isar;
  final _listeners = <MultiStreamController<List<Item>>>{};
  StreamSubscription<List<Item>>? _upstream;
  List<Item>? _latest;

  /// 생성일 내림차순 전체 옷 목록. 구독자 수와 무관하게 Isar 구독은 1개다.
  late final Stream<List<Item>> stream = Stream<List<Item>>.multi((ctrl) {
    _listeners.add(ctrl);
    final latest = _latest;
    if (latest != null) ctrl.add(latest);
    _upstream ??= _isar.items
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .listen(_onData, onError: _onError);
    ctrl.onCancel = () {
      _listeners.remove(ctrl);
      if (_listeners.isEmpty) _release();
    };
  });

  void _onData(List<Item> items) {
    // 구독자가 같은 리스트를 공유하므로 제자리 정렬·수정을 막는다.
    final shared = List<Item>.unmodifiable(items);
    _latest = shared;
    for (final l in _listeners.toList()) {
      l.add(shared);
    }
  }

  void _onError(Object error, StackTrace stack) {
    for (final l in _listeners.toList()) {
      l.addError(error, stack);
    }
  }

  /// provider가 폐기될 때 업스트림 구독과 남은 구독자를 정리한다.
  void dispose() {
    for (final l in _listeners.toList()) {
      l.close();
    }
    _listeners.clear();
    _release();
  }

  void _release() {
    final sub = _upstream;
    _upstream = null;
    _latest = null;
    sub?.cancel();
  }
}
