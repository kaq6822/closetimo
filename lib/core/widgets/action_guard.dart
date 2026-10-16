// #48 FR-030 — 비동기 쓰기 액션의 중복 입력 차단·진행 상태·실패 토스트.
//
// - [runWithFailureToast]: 실패하면 영문 로그 + 오류 토스트. 재진입 차단이 필요 없는
//   곳(팝업 메뉴처럼 실행 중 다시 누를 수 없는 진입점)에서 쓴다.
// - [ActionGuardMixin.runGuarded]: 위 처리 + 진행 중 재진입 차단 + 진행 상태
//   ([actionBusy]/[isActionBusy])로 버튼 진행 표시·비활성화를 그린다.
// 성공 토스트는 결과 문구가 액션마다 달라 액션 본문이 직접 띄운다.

import 'package:flutter/material.dart';

import 'toast.dart';

/// [action]을 실행하고, 예외가 나면 로그를 남긴 뒤 [failureMessage] 오류 토스트를
/// 띄운다. 성공하면 true.
Future<bool> runWithFailureToast(
  BuildContext context,
  Future<void> Function() action, {
  required String failureMessage,
  ToastPlacement placement = ToastPlacement.bottom,
}) async {
  try {
    await action();
    return true;
  } catch (e, st) {
    debugPrint('Action failed ($failureMessage): $e\n$st');
    if (context.mounted) {
      showClosetimoToast(
        context,
        failureMessage,
        placement: placement,
        isError: true,
      );
    }
    return false;
  }
}

/// State에 섞어 쓰는 액션 가드. 한 화면에서 쓰기 액션은 한 번에 하나만 실행한다.
mixin ActionGuardMixin<W extends StatefulWidget> on State<W> {
  /// 진행 중인 액션의 태그. null이면 대기 상태.
  Object? _busyTag;

  /// 어떤 액션이든 진행 중인가. 진행 중에는 다른 쓰기 버튼도 비활성화한다.
  bool get actionBusy => _busyTag != null;

  /// [tag] 액션이 진행 중인가. 눌린 버튼에만 진행 표시를 그릴 때 쓴다.
  bool isActionBusy(Object tag) => _busyTag == tag;

  /// [action]을 실행한다. 이미 다른 액션이 진행 중이면 실행하지 않고 false.
  /// 실패하면 [failureMessage] 오류 토스트를 띄우고 false, 성공하면 true.
  Future<bool> runGuarded(
    Future<void> Function() action, {
    required String failureMessage,
    Object tag = 'action',
    ToastPlacement placement = ToastPlacement.bottom,
  }) async {
    if (_busyTag != null) return false;
    setState(() => _busyTag = tag);
    try {
      return await runWithFailureToast(
        context,
        action,
        failureMessage: failureMessage,
        placement: placement,
      );
    } finally {
      if (mounted) setState(() => _busyTag = null);
    }
  }
}
