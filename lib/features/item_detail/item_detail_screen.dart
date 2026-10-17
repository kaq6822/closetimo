// US3 T054 — 옷 상세 화면.
// #48 FR-029·030 — 읽기 실패 안내·재시도, 쓰기 액션 중복 입력 차단·진행 표시·실패 토스트.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/action_guard.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/chip_filter.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/status_label.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../core/widgets/wear_record_sheet.dart';
import '../../data/models/item.dart';
import '../../data/models/wear_event.dart';
import '../../data/providers/app_providers.dart';
import '../../data/repositories/event_repository.dart';
import 'widgets/archive_item_dialog.dart';
import 'widgets/delete_event_dialog.dart';
import 'widgets/delete_item_dialog.dart';
import 'widgets/edit_note_sheet.dart';
import 'widgets/hero_image.dart';
import 'widgets/history_timeline.dart';
import 'widgets/stats_grid.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

/// 진행 표시를 그릴 버튼별 액션 태그(#48).
enum _DetailAction { wear, restore, other }

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen>
    with ActionGuardMixin {
  Item? _item;
  bool _loading = true;

  /// #48 FR-029 — 옷 정보를 읽지 못했다. "옷을 찾을 수 없음"과 구분한다.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(itemRepositoryProvider);
    final Item? item;
    try {
      item = await repo.get(widget.id);
    } catch (e) {
      debugPrint('Failed to load item ${widget.id}: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
      _loadFailed = false;
    });
    if (item == null && context.mounted) {
      showClosetimoToast(context, '옷을 찾을 수 없어요');
      context.pop();
    }
  }

  void _retryLoad() {
    setState(() => _loading = true);
    _load();
  }

  Future<void> _refresh() async {
    // 화면을 떠난 뒤 실행 취소가 끝나는 경우 ref를 읽을 수 없다.
    if (!mounted) return;
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.get(widget.id);
    if (mounted) setState(() => _item = item);
  }

  /// #48 FR-030 — 쓰기 액션을 한 번에 하나만 실행하고 실패하면 상단 오류 토스트.
  /// 확인 시트·다이얼로그는 가드 밖에서 먼저 받고, 저장소 쓰기만 감싼다.
  Future<bool> _guard(
    Future<void> Function() write, {
    required String failureMessage,
    _DetailAction tag = _DetailAction.other,
  }) => runGuarded(
    write,
    failureMessage: failureMessage,
    tag: tag,
    placement: ToastPlacement.top,
  );

  // ignore_for_file: use_build_context_synchronously
  // #22 — 상세 화면에 머무는 토스트는 방금 누른 버튼(스크롤 후 화면 하단에 오기
  // 쉬움)을 가리지 않도록 상단바 아래에 띄운다. 화면을 벗어나는 토스트는 기본(하단).
  Future<void> _recordWear() async {
    final now = ref.read(clockProvider).now();
    final result = await WearRecordSheet.show(context, today: now);
    if (result == null) return;
    int? eventId;
    final ok = await _guard(
      () async {
        eventId = await ref
            .read(eventRepositoryProvider)
            .recordWear(widget.id, note: result.note, wornOn: result.wornOn);
        await _refresh();
      },
      tag: _DetailAction.wear,
      failureMessage: '착용을 기록하지 못했어요. 다시 시도해 주세요.',
    );
    if (!ok || !context.mounted) return;
    final id = eventId;
    // 토스트는 화면을 떠난 뒤에도 남으므로 저장소를 미리 잡아 둔다(unmounted ref 접근 방지).
    final events = ref.read(eventRepositoryProvider);
    // #39 FR-010e — 직후 실행 취소.
    showClosetimoToast(
      context,
      '${formatWearDay(result.wornOn, now: now)}의 착용이 기록되었어요',
      placement: ToastPlacement.top,
      actionLabel: id == null ? null : '실행 취소',
      onAction: id == null ? null : () => _undoWear(events, id),
    );
  }

  Future<void> _undoWear(EventRepository events, int eventId) async {
    final ok = await _guard(() async {
      await events.deleteWearEvents([eventId]);
      await _refresh();
    }, failureMessage: '착용 기록을 취소하지 못했어요. 다시 시도해 주세요.');
    if (!ok || !mounted) return;
    showClosetimoToast(context, '착용 기록을 취소했어요', placement: ToastPlacement.top);
  }

  // #39 FR-010c — 기록 날짜 수정. 카운터·상태 재계산은 repository가 맡는다.
  Future<void> _editEventDate(WearEvent event) async {
    final now = ref.read(clockProvider).now();
    final picked = await pickWearDate(
      context,
      today: now,
      initial: event.occurredAt,
    );
    if (picked == null) return;
    final ok = await _guard(() async {
      await ref.read(eventRepositoryProvider).updateWearDate(event.id, picked);
      await _refresh();
    }, failureMessage: '착용 날짜를 바꾸지 못했어요. 다시 시도해 주세요.');
    if (!ok || !context.mounted) return;
    showClosetimoToast(
      context,
      '착용 날짜를 ${formatMonthDay(picked)}로 바꿨어요',
      placement: ToastPlacement.top,
    );
  }

  Future<void> _toggleLaundry() async {
    if (_item == null) return;
    final wasIn = _item!.inLaundry;
    final ok = await _guard(() async {
      await ref.read(laundryRepositoryProvider).toggle(widget.id);
      await _refresh();
    }, failureMessage: '세탁 바구니를 바꾸지 못했어요. 다시 시도해 주세요.');
    if (!ok || !context.mounted) return;
    showClosetimoToast(
      context,
      wasIn ? '세탁 바구니에서 제외됐어요' : '세탁 바구니에 담겼어요',
      placement: ToastPlacement.top,
    );
  }

  Future<void> _editEventNote(WearEvent event) async {
    final result = await EditNoteSheet.show(context, initial: event.note);
    if (result == null) return;
    final ok = await _guard(
      () => ref
          .read(eventRepositoryProvider)
          .updateEventNote(event.id, result.note),
      failureMessage: '메모를 수정하지 못했어요. 다시 시도해 주세요.',
    );
    if (!ok || !context.mounted) return;
    showClosetimoToast(context, '메모를 수정했어요', placement: ToastPlacement.top);
  }

  Future<void> _deleteEvent(WearEvent event) async {
    final confirmed = await DeleteEventDialog.confirm(context);
    if (!confirmed) return;
    final ok = await _guard(() async {
      await ref.read(eventRepositoryProvider).deleteWearEvent(event.id);
      await _refresh();
    }, failureMessage: '착용 기록을 삭제하지 못했어요. 다시 시도해 주세요.');
    if (!ok || !context.mounted) return;
    showClosetimoToast(context, '착용 기록을 삭제했어요', placement: ToastPlacement.top);
  }

  // 002 FR-001 — 수정 화면 진입 후 복귀 시 상세를 갱신한다.
  Future<void> _edit() async {
    await context.pushNamed(
      Routes.editItem,
      pathParameters: {'id': '${widget.id}'},
    );
    await _refresh();
  }

  // #44 — 기록을 남긴 채 활성 옷장에서 뺀다. 상세에 머물러 바로 되돌릴 수 있게 한다.
  Future<void> _archive() async {
    final reason = await ArchiveItemDialog.show(context);
    if (reason == null) return;
    final ok = await _guard(() async {
      await ref
          .read(archiveRepositoryProvider)
          .archive(widget.id, reason: reason);
      await _refresh();
    }, failureMessage: '보관하지 못했어요. 다시 시도해 주세요.');
    if (!ok || !context.mounted) return;
    showClosetimoToast(
      context,
      '보관함으로 옮겼어요. 기록은 그대로 남아요',
      placement: ToastPlacement.top,
    );
  }

  // #44 — 보관을 해제해 기록을 유지한 채 활성 옷장으로 되돌린다.
  Future<void> _restore() async {
    final ok = await _guard(
      () async {
        await ref.read(archiveRepositoryProvider).restore(widget.id);
        await _refresh();
      },
      tag: _DetailAction.restore,
      failureMessage: '옷장으로 꺼내지 못했어요. 다시 시도해 주세요.',
    );
    if (!ok || !context.mounted) return;
    showClosetimoToast(context, '옷장으로 다시 꺼냈어요', placement: ToastPlacement.top);
  }

  // 002 FR-008~012 — 확인 후 옷을 삭제하고 옷장으로 복귀한다.
  Future<void> _delete() async {
    final confirmed = await DeleteItemDialog.confirm(context);
    if (!confirmed) return;
    final ok = await _guard(
      () => ref.read(itemRepositoryProvider).delete(widget.id),
      failureMessage: '옷을 삭제하지 못했어요. 다시 시도해 주세요.',
    );
    if (!ok || !context.mounted) return;
    showClosetimoToast(context, '옷을 옷장에서 삭제했어요');
    // FR-012 — 삭제 후에는 진입 경로(홈·세탁 타일 포함)와 무관하게 옷장 탭으로
    // 복귀해야 한다. pop()은 진입 스택으로 돌아가므로 goNamed로 탭을 전환한다.
    // 단, 옷장에서 push로 들어왔다면(push 아래 기준 URI가 옷장) pop해서
    // 칩 필터(`?category=`)·검색어·스크롤을 그대로 유지한다(#13 부수 효과 방지).
    final base = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    if (base.path == BottomNavTab.wardrobe.path && context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.wardrobe);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_loadFailed) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(onBack: () => context.pop()),
              AsyncErrorView(message: '옷 정보를 불러오지 못했어요', onRetry: _retryLoad),
            ],
          ),
        ),
      );
    }
    final item = _item;
    if (item == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final busy = actionBusy;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              onBack: () => context.pop(),
              rightSlot: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                enabled: !busy,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _edit();
                    case 'archive':
                      _archive();
                    case 'restore':
                      _restore();
                    case 'delete':
                      _delete();
                  }
                },
                // #44 — 보관(기록 유지)과 삭제(기록까지 제거)를 나란히 두어 구분한다.
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('수정하기')),
                  if (item.isArchived)
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('옷장으로 꺼내기'),
                    )
                  else
                    const PopupMenuItem(value: 'archive', child: Text('보관하기')),
                  const PopupMenuItem(value: 'delete', child: Text('삭제하기')),
                ],
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.md,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.space76,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroImage(item: item),
                    const SizedBox(height: ClosetimoSpacing.space26),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.md),
                    // 좁은 화면에서 칩·상태 라벨이 넘치지 않도록 줄바꿈한다.
                    Wrap(
                      spacing: ClosetimoSpacing.sm,
                      runSpacing: ClosetimoSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ChipFilter(
                          label: item.category.label,
                          active: false,
                          onTap: () {},
                        ),
                        ChipFilter(
                          label: item.careMethod.label,
                          active: false,
                          onTap: () {},
                        ),
                        // FR-009a — 상태를 이름 바로 아래에서 확인한다.
                        StatusLabel(
                          variant: item.status == ItemStatus.dirty
                              ? StatusLabelVariant.dirty
                              : StatusLabelVariant.clean,
                        ),
                      ],
                    ),
                    // FR-009a(#47) — 주요 기록 액션을 통계 카드보다 먼저 둬
                    // 첫 화면 안에서 닿게 한다. 통계는 액션 아래로 내린다.
                    const SizedBox(height: ClosetimoSpacing.xl),
                    // #44 — 보관한 옷은 착용 기록·바구니 담기 대신 복원만 제공한다.
                    if (item.isArchived) ...[
                      _ArchivedNotice(item: item),
                      const SizedBox(height: ClosetimoSpacing.space12),
                      PrimaryButton(
                        label: '옷장으로 꺼내기',
                        leading: const Icon(Icons.unarchive_outlined),
                        busy: isActionBusy(_DetailAction.restore),
                        onPressed: busy ? null : _restore,
                      ),
                    ] else ...[
                      PrimaryButton(
                        label: '착용 기록하기',
                        leading: const Icon(Icons.add_rounded),
                        busy: isActionBusy(_DetailAction.wear),
                        onPressed: busy ? null : _recordWear,
                      ),
                      const SizedBox(height: ClosetimoSpacing.space12),
                      SoftButton(
                        label: item.inLaundry ? '바구니에서 제외' : '세탁 바구니',
                        leading: const Icon(
                          Icons.local_laundry_service_rounded,
                        ),
                        onPressed: busy ? null : _toggleLaundry,
                      ),
                    ],
                    const SizedBox(height: ClosetimoSpacing.space26),
                    StatsGrid(item: item),
                    const SizedBox(height: ClosetimoSpacing.xxl),
                    const Text(
                      '착용 히스토리',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.space18),
                    HistoryTimeline(
                      itemId: item.id,
                      onEdit: _editEventNote,
                      onEditDate: _editEventDate,
                      onDelete: _deleteEvent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// #44 — 보관 중인 옷 안내. 사유·보관일과 함께 "기록은 남아 있다"는 점을 알린다.
class _ArchivedNotice extends StatelessWidget {
  const _ArchivedNotice({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final reason = item.archiveReason == ArchiveReason.unspecified
        ? null
        : item.archiveReason.label;
    final headline = [
      '보관 중',
      ?reason,
      '${formatFullDate(item.archivedAt!)} 보관',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(ClosetimoSpacing.md),
      decoration: BoxDecoration(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lgPlus),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ClosetimoColors.ink,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.space4),
          const Text(
            '옷장·홈 통계·세탁 바구니에서 빠져 있어요. 착용·세탁 기록은 그대로 남아 있어요.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: ClosetimoColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
