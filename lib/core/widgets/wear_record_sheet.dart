// US3 T054a — 착용 기록 시트.
//
// "착용 기록하기" 액션이 띄우는 가벼운 바텀시트. 착용 날짜(기본 오늘, 어제,
// 날짜 선택 — #39 FR-010)와 단일행 ≤80자 메모(선택)를 받아, 메모는 trim 후 빈
// 입력을 null로 정규화해 돌려준다(FR-010, contracts/repositories.md §3 UI 흐름).
// 옷 상세(한 벌)와 옷장 다중 선택(여러 벌, FR-008c)이 함께 쓴다.

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../utils/date_formatter.dart';
import 'chip_filter.dart';
import 'note_sheet_scaffold.dart';

class WearRecordResult {
  const WearRecordResult(this.note, {required this.wornOn});
  final String? note;

  /// 착용 날짜(시각 없는 달력 날짜).
  final DateTime wornOn;
}

/// 날짜 선택에서 고를 수 있는 기간(오늘 기준 과거 일수).
const int kWearDatePickerDays = 365;

/// 착용 날짜 선택 다이얼로그. 오늘 이후는 고를 수 없다(FR-010d).
Future<DateTime?> pickWearDate(
  BuildContext context, {
  required DateTime today,
  DateTime? initial,
}) {
  final last = DateTime(today.year, today.month, today.day);
  final first = DateTime(last.year, last.month, last.day - kWearDatePickerDays);
  var init = initial == null
      ? last
      : DateTime(initial.year, initial.month, initial.day);
  if (init.isAfter(last)) init = last;
  if (init.isBefore(first)) init = first;
  return showDatePicker(
    context: context,
    initialDate: init,
    firstDate: first,
    lastDate: last,
    helpText: '착용 날짜',
    cancelText: '취소',
    confirmText: '확인',
  );
}

class WearRecordSheet extends StatefulWidget {
  const WearRecordSheet({required this.today, this.count = 1, super.key});

  /// 기준 시각(Clock). 날짜 기본값과 "오늘/어제" 표기에 쓴다.
  final DateTime today;

  /// 함께 기록할 옷 수. 2 이상이면 여러 벌 기록 문구를 보인다(FR-008c).
  final int count;

  /// Shows the sheet and resolves to a [WearRecordResult] when the user
  /// confirms, or `null` when the sheet is dismissed.
  static Future<WearRecordResult?> show(
    BuildContext context, {
    required DateTime today,
    int count = 1,
  }) {
    return showModalBottomSheet<WearRecordResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WearRecordSheet(today: today, count: count),
    );
  }

  @override
  State<WearRecordSheet> createState() => _WearRecordSheetState();
}

class _WearRecordSheetState extends State<WearRecordSheet> {
  late final DateTime _today = DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day,
  );
  late DateTime _wornOn = _today;

  DateTime get _yesterday =>
      DateTime(_today.year, _today.month, _today.day - 1);

  bool get _isCustom => _wornOn != _today && _wornOn != _yesterday;

  Future<void> _pickDate() async {
    final picked = await pickWearDate(
      context,
      today: widget.today,
      initial: _wornOn,
    );
    if (picked == null || !mounted) return;
    setState(() => _wornOn = DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = formatWearDay(_wornOn, now: widget.today);
    final multi = widget.count > 1;
    return NoteSheetScaffold(
      title: '$dayLabel의 착용',
      subtitle: multi
          ? '선택한 ${widget.count}벌을 같은 날짜로 기록해요. 메모는 비워 두어도 괜찮아요.'
          : '한 줄 메모를 함께 남길 수 있어요. 비워 두어도 괜찮아요.',
      hint: '예: 오피스 미팅, 약간 더웠음',
      confirmLabel: multi ? '${widget.count}벌 기록' : '기록',
      confirmIcon: Icons.check_rounded,
      header: Semantics(
        container: true,
        label: '착용 날짜',
        child: Wrap(
          spacing: ClosetimoSpacing.sm,
          runSpacing: ClosetimoSpacing.sm,
          children: [
            ChipFilter(
              label: '오늘',
              active: _wornOn == _today,
              onTap: () => setState(() => _wornOn = _today),
            ),
            ChipFilter(
              label: '어제',
              active: _wornOn == _yesterday,
              onTap: () => setState(() => _wornOn = _yesterday),
            ),
            ChipFilter(
              label: _isCustom ? formatMonthDay(_wornOn) : '날짜 선택',
              active: _isCustom,
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      onConfirm: (note) =>
          Navigator.of(context).pop(WearRecordResult(note, wornOn: _wornOn)),
    );
  }
}
