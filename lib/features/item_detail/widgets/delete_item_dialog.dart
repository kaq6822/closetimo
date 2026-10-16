// 002 T012 — 옷 삭제 확인 다이얼로그(FR-009). 되돌릴 수 없는 파괴적 동작이므로
// 삭제 전 반드시 사용자 확인을 거친다. 001 DeleteEventDialog 패턴을 재사용한다.

import 'package:flutter/material.dart';

class DeleteItemDialog {
  const DeleteItemDialog._();

  /// 삭제 확인 다이얼로그를 띄우고 "삭제" 확정 시 true를 반환한다.
  static Future<bool> confirm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이 옷을 삭제할까요?'),
        // 좁은 화면에서 단어 중간 줄바꿈('없어\n요')을 피하도록 수동 개행.
        // #44 — 보관(기록 유지)과 구분되도록 기록까지 지워짐을 명시한다.
        content: const Text(
          '사진과 착용·세탁 기록까지 모두 지워지고\n'
          '되돌릴 수 없어요.\n'
          '기록을 남기려면 \'보관하기\'를 이용하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
