// US3 T052 — 착용·세탁 이벤트 타임라인.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/wear_event.dart';
import '../../../data/providers/app_providers.dart';

class HistoryTimeline extends ConsumerWidget {
  const HistoryTimeline({required this.itemId, super.key});

  final int itemId;

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
                                e.kind == EventKind.wash ? '세탁 완료' : '착용 기록',
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
