// 005 FR-507 — 홈 "오늘 입은 옷": 썸네일을 눌러 고르고 한 번에 착용을 기록한다(SC-503).
// 기록은 #39 일괄 기록(`recordWearBatch`)과 실행 취소(`deleteWearEvents`)를 재사용한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/action_guard.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/item_photo.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/widgets/wear_record_sheet.dart';
import '../../../data/models/item.dart';
import '../../../data/models/item_attributes.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/repositories/event_repository.dart';

class TodayWearCard extends ConsumerStatefulWidget {
  const TodayWearCard({super.key});

  /// 보여 줄 최대 후보 수.
  static const candidateLimit = 12;

  @override
  ConsumerState<TodayWearCard> createState() => _TodayWearCardState();
}

class _TodayWearCardState extends ConsumerState<TodayWearCard>
    with ActionGuardMixin {
  final Set<int> _selected = {};

  void _toggle(int id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  /// [askDate]면 기존 착용 시트(날짜·메모)를 띄우고, 아니면 오늘로 바로 기록한다.
  Future<void> _record(Set<int> ids, {required bool askDate}) async {
    if (ids.isEmpty) return;
    final now = ref.read(clockProvider).now();
    var wornOn = now;
    String? note;
    if (askDate) {
      final result = await WearRecordSheet.show(
        context,
        today: now,
        count: ids.length,
      );
      if (result == null || !mounted) return;
      wornOn = result.wornOn;
      note = result.note;
    }
    final events = ref.read(eventRepositoryProvider);
    WearBatchResult? outcome;
    final ok = await runGuarded(() async {
      outcome = await events.recordWearBatch(ids, wornOn: wornOn, note: note);
    }, failureMessage: '착용을 기록하지 못했어요. 다시 시도해 주세요.');
    final done = outcome;
    if (!ok || done == null || !mounted) return;
    setState(_selected.clear);
    if (done.recorded == 0) {
      showClosetimoToast(context, '기록할 수 있는 옷이 없어요');
      return;
    }
    final day = formatWearDay(wornOn, now: now);
    showClosetimoToast(
      context,
      '$day의 착용을 ${done.eventIds.length}벌 기록했어요',
      actionLabel: '실행 취소',
      onAction: () async {
        await events.deleteWearEvents(done.eventIds);
        if (!mounted) return;
        showClosetimoToast(context, '착용 기록을 취소했어요');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(itemRepositoryProvider);
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Container(
      padding: const EdgeInsets.all(ClosetimoSpacing.space20),
      decoration: BoxDecoration(
        color: surfaces.containerLowest,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xlMinus),
        boxShadow: ClosetimoElevation.cardShadow,
      ),
      child: StreamStateBuilder<List<Item>>(
        stream: repo.watchAll,
        streamKey: repo,
        errorMessage: '옷 목록을 불러오지 못했어요',
        builder: (ctx, all) {
          final candidates = todayWearCandidates(
            all,
            limit: TodayWearCard.candidateLimit,
          );
          // 목록에서 사라진 옷(보관·바구니 등)은 선택으로 치지 않는다(build에서 상태를 바꾸지 않는다).
          final shown = {for (final c in candidates) c.id};
          final selected = _selected.intersection(shown);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '오늘 입은 옷',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ClosetimoColors.ink,
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.xs),
              Text(
                candidates.isEmpty
                    ? '옷을 등록하면 여기서 바로 착용을 기록할 수 있어요.'
                    : '입은 옷을 눌러 고른 뒤 한 번에 기록하세요.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: ClosetimoColors.muted,
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.space14),
              if (candidates.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.pushNamed(Routes.addItem),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('첫 옷 등록하기'),
                  ),
                )
              else ...[
                SizedBox(
                  height:
                      ClosetimoSize.todayWearThumb + ClosetimoSpacing.space32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: ClosetimoSpacing.space12),
                    itemBuilder: (_, i) {
                      final item = candidates[i];
                      return _WearThumb(
                        item: item,
                        selected: selected.contains(item.id),
                        onTap: () => _toggle(item.id),
                      );
                    },
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  const SizedBox(height: ClosetimoSpacing.space12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: ClosetimoColors.primary,
                            foregroundColor: ClosetimoColors.onPrimary,
                            minimumSize: const Size.fromHeight(
                              ClosetimoSize.minTouchTarget,
                            ),
                          ),
                          onPressed: actionBusy
                              ? null
                              : () => _record(selected, askDate: false),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            actionBusy ? '기록 중…' : '오늘 ${selected.length}벌 기록',
                          ),
                        ),
                      ),
                      const SizedBox(width: ClosetimoSpacing.sm),
                      TextButton(
                        onPressed: actionBusy
                            ? null
                            : () => _record(selected, askDate: true),
                        child: const Text('날짜·메모'),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WearThumb extends StatelessWidget {
  const _WearThumb({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final Item item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.name} 선택',
      checked: selected,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClosetimoRadius.md),
        child: SizedBox(
          width: ClosetimoSize.todayWearThumb,
          child: Column(
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: ClosetimoSize.todayWearThumb,
                    height: ClosetimoSize.todayWearThumb,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ClosetimoRadius.md),
                      border: Border.all(
                        width: ClosetimoSize.controlOutline,
                        color: selected
                            ? ClosetimoColors.primary
                            : ClosetimoColors.outlineVariantGhost,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ItemPhoto(
                      imagePath: item.displayImagePath,
                      cutout: item.showsCutout,
                      originalPath: item.imagePath,
                      fallback: Color(item.fallbackColor),
                      cacheWidth: 240,
                      cutoutPadding: ClosetimoSpacing.xs,
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      top: ClosetimoSpacing.xs,
                      right: ClosetimoSpacing.xs,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: ClosetimoColors.primary,
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: ClosetimoColors.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ClosetimoSpacing.xs),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: ClosetimoColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
