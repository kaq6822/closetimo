// #39 — 선택 바 "착용 기록" 액션(spec FR-008c·FR-010d·FR-010e).
//
// 선택한 옷을 같은 날짜·메모로 한 번에 기록한다. 쓰기는
// `EventRepository.recordWearBatch`가 단일 트랜잭션으로 처리하고(중복·보관 제외),
// 직후 토스트의 "실행 취소"는 `deleteWearEvents`로 되돌린다. 다른 선택 액션과
// 섞이지 않도록 옷장 화면에서는 [wearRecordSelectionAction] 한 줄로만 연결한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/wear_record_sheet.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/repositories/event_repository.dart';
import 'item_selection.dart';
import 'selection_action_bar.dart';

/// 선택 바에 넣는 "착용 기록" 액션.
SelectionAction wearRecordSelectionAction(
  BuildContext context,
  WidgetRef ref,
  Set<int> ids,
) {
  return SelectionAction(
    label: '착용 기록',
    icon: Icons.checkroom_rounded,
    onPressed: () => recordWearForSelection(context, ref, ids),
  );
}

/// 시트로 날짜·메모를 받아 [ids]를 일괄 기록한다. 실패하면 선택을 유지한다.
Future<void> recordWearForSelection(
  BuildContext context,
  WidgetRef ref,
  Set<int> ids,
) async {
  if (ids.isEmpty) return;
  final now = ref.read(clockProvider).now();
  final result = await WearRecordSheet.show(
    context,
    today: now,
    count: ids.length,
  );
  if (result == null || !context.mounted) return;
  final events = ref.read(eventRepositoryProvider);
  final WearBatchResult outcome;
  try {
    outcome = await events.recordWearBatch(
      ids,
      wornOn: result.wornOn,
      note: result.note,
    );
  } catch (e) {
    debugPrint('Failed to record wear for ${ids.length} items: $e');
    if (!context.mounted) return;
    showClosetimoToast(context, '착용을 기록하지 못했어요. 선택은 그대로 두었어요.', isError: true);
    return;
  }
  if (!context.mounted) return;
  ref.read(wardrobeSelectionProvider.notifier).exit();
  if (outcome.recorded == 0) {
    showClosetimoToast(context, '기록할 수 있는 옷이 없어요');
    return;
  }
  final day = formatWearDay(result.wornOn, now: now);
  final skipped = outcome.skipped > 0 ? ' (${outcome.skipped}벌 제외)' : '';
  showClosetimoToast(
    context,
    '$day의 착용을 ${outcome.eventIds.length}벌 기록했어요$skipped',
    actionLabel: '실행 취소',
    onAction: () async {
      await events.deleteWearEvents(outcome.eventIds);
      if (!context.mounted) return;
      showClosetimoToast(context, '착용 기록을 취소했어요');
    },
  );
}
