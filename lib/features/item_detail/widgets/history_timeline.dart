// US3 T052 — 착용·세탁 이벤트 타임라인.
//
// US3 T054(c·d): wear 이벤트 항목은 long-press 시 액션 시트로 "메모 편집"/
// "기록 삭제" 메뉴를 노출해 onEdit/onDelete 콜백을 호출한다(FR-010a·FR-010b).
// wash 이벤트는 본 릴리스에서 사후 변경을 지원하지 않으므로 long-press가 비활성.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/wear_event.dart';
import '../../../data/providers/app_providers.dart';

class HistoryTimeline extends ConsumerWidget {
  const HistoryTimeline({
    required this.itemId,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final int itemId;
  final void Function(WearEvent event)? onEdit;
  final void Function(WearEvent event)? onDelete;

  bool get _hasActions => onEdit != null || onDelete != null;

  Future<void> _showActions(BuildContext context, WearEvent e) async {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaces.containerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ClosetimoRadius.xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: ClosetimoSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: surfaces.containerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: ClosetimoSpacing.sm),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: ClosetimoColors.ink),
                title: const Text(
                  '메모 편집',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: ClosetimoColors.ink,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEdit?.call(e);
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: ClosetimoColors.error),
                title: const Text(
                  '기록 삭제',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: ClosetimoColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDelete?.call(e);
                },
              ),
            const SizedBox(height: ClosetimoSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(eventRepositoryProvider).watchForItem(itemId);
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return StreamBuilder<List<WearEvent>>(
      stream: stream,
      builder: (ctx, snap) {
        final events = snap.data ?? const [];
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              '아직 기록된 이벤트가 없어요.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: ClosetimoColors.muted,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 42),
          child: Stack(
            children: [
              Positioned(
                left: -27,
                top: 12,
                bottom: 12,
                child: Container(width: 2, color: surfaces.containerHigh),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in events)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress:
                            e.kind == EventKind.wear && _hasActions
                                ? () => _showActions(context, e)
                                : null,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -42,
                              top: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: e.kind == EventKind.wash
                                      ? surfaces.bgMint
                                      : surfaces.container,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  e.kind == EventKind.wash
                                      ? Icons.opacity_rounded
                                      : Icons.checkroom_rounded,
                                  size: 14,
                                  color: ClosetimoColors.primary,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatMonthDay(e.occurredAt),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    color: ClosetimoColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e.kind == EventKind.wash
                                      ? '세탁 완료'
                                      : '착용 기록',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: ClosetimoColors.ink,
                                  ),
                                ),
                                if (e.note != null && e.note!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    e.note!,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      color: ClosetimoColors.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
