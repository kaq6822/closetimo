// US3 T054b — wear 이벤트 메모 편집 시트(FR-010a).
//
// 타임라인 wear 항목 long-press 메뉴의 "메모 편집" 액션이 띄운다.
// WearRecordSheet과 동일한 단일행 ≤80자 제약 + 초기값 prefill.

import 'package:flutter/material.dart';

import 'note_sheet_scaffold.dart';

class EditNoteResult {
  const EditNoteResult(this.note);
  final String? note;
}

class EditNoteSheet extends StatelessWidget {
  const EditNoteSheet({required this.initial, super.key});

  final String? initial;

  static Future<EditNoteResult?> show(
    BuildContext context, {
    required String? initial,
  }) {
    return showModalBottomSheet<EditNoteResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditNoteSheet(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NoteSheetScaffold(
      title: '메모 편집',
      subtitle: '이 착용 기록의 메모만 수정해요. 카운터·상태는 그대로 유지돼요.',
      hint: '예: 외부 행사, 약간 더웠음',
      initial: initial,
      confirmLabel: '저장',
      confirmIcon: Icons.check_rounded,
      onConfirm: (note) =>
          Navigator.of(context).pop(EditNoteResult(note)),
    );
  }
}
