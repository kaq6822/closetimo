// US3 T054c — wear 이벤트 삭제 확인 다이얼로그(FR-010b).
//
// 타임라인 wear 항목 long-press 메뉴의 "기록 삭제" 액션이 띄운다.
// 확정 시 EventRepository.deleteWearEvent(eventId) 호출은 호출 측에서 수행한다.

import 'package:flutter/material.dart';

class DeleteEventDialog {
  /// Returns `true` when the user confirms deletion, `false` otherwise.
  static Future<bool> confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이 착용 기록을 삭제할까요?'),
        content: const Text(
          '삭제하면 옷의 착용 카운터와 상태가 함께 조정돼요. 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
