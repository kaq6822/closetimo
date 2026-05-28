// US3 T054a — 착용 기록 시트.
//
// "착용 기록하기" 액션이 띄우는 가벼운 바텀시트. 단일행 ≤80자 메모(선택)를
// 받아 trim 후 빈 입력은 null로 정규화해 콜백에 전달한다(FR-010,
// contracts/repositories.md §3 UI 흐름).

import 'package:flutter/material.dart';

import 'note_sheet_scaffold.dart';

class WearRecordResult {
  const WearRecordResult(this.note);
  final String? note;
}

class WearRecordSheet extends StatelessWidget {
  const WearRecordSheet({super.key});

  /// Shows the sheet and resolves to a [WearRecordResult] when the user
  /// confirms, or `null` when the sheet is dismissed.
  static Future<WearRecordResult?> show(BuildContext context) {
    return showModalBottomSheet<WearRecordResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WearRecordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NoteSheetScaffold(
      title: '오늘의 착용',
      subtitle: '한 줄 메모를 함께 남길 수 있어요. 비워 두어도 괜찮아요.',
      hint: '예: 오피스 미팅, 약간 더웠음',
      confirmLabel: '기록',
      confirmIcon: Icons.check_rounded,
      onConfirm: (note) =>
          Navigator.of(context).pop(WearRecordResult(note)),
    );
  }
}
