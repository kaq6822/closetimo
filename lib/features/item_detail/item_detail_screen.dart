// US3 T054 — 옷 상세 화면.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/chip_filter.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/models/wear_event.dart';
import '../../data/providers/app_providers.dart';
import 'widgets/delete_event_dialog.dart';
import 'widgets/delete_item_dialog.dart';
import 'widgets/edit_note_sheet.dart';
import 'widgets/hero_image.dart';
import 'widgets/history_timeline.dart';
import 'widgets/stats_grid.dart';
import 'widgets/wear_record_sheet.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  Item? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.get(widget.id);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
    if (item == null && context.mounted) {
      showClosetimoToast(context, '옷을 찾을 수 없어요');
      context.pop();
    }
  }

  Future<void> _refresh() async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.get(widget.id);
    if (mounted) setState(() => _item = item);
  }

  // ignore_for_file: use_build_context_synchronously
  // #22 — 상세 화면에 머무는 토스트는 방금 누른 버튼(스크롤 후 화면 하단에 오기
  // 쉬움)을 가리지 않도록 상단바 아래에 띄운다. 화면을 벗어나는 토스트는 기본(하단).
  Future<void> _recordWear() async {
    final result = await WearRecordSheet.show(context);
    if (result == null) return;
    await ref
        .read(eventRepositoryProvider)
        .recordWear(widget.id, note: result.note);
    await _refresh();
    if (!context.mounted) return;
    showClosetimoToast(
      context,
      '오늘의 착용이 기록되었어요',
      placement: ToastPlacement.top,
    );
  }

  Future<void> _toggleLaundry() async {
    if (_item == null) return;
    final wasIn = _item!.inLaundry;
    await ref.read(laundryRepositoryProvider).toggle(widget.id);
    await _refresh();
    if (!context.mounted) return;
    showClosetimoToast(
      context,
      wasIn ? '세탁 바구니에서 제외됐어요' : '세탁 바구니에 담겼어요',
      placement: ToastPlacement.top,
    );
  }

  Future<void> _editEventNote(WearEvent event) async {
    final result = await EditNoteSheet.show(context, initial: event.note);
    if (result == null) return;
    await ref
        .read(eventRepositoryProvider)
        .updateEventNote(event.id, result.note);
    if (!context.mounted) return;
    showClosetimoToast(
      context,
      '메모를 수정했어요',
      placement: ToastPlacement.top,
    );
  }

  Future<void> _deleteEvent(WearEvent event) async {
    final ok = await DeleteEventDialog.confirm(context);
    if (!ok) return;
    await ref.read(eventRepositoryProvider).deleteWearEvent(event.id);
    await _refresh();
    if (!context.mounted) return;
    showClosetimoToast(
      context,
      '착용 기록을 삭제했어요',
      placement: ToastPlacement.top,
    );
  }

  // 002 FR-001 — 수정 화면 진입 후 복귀 시 상세를 갱신한다.
  Future<void> _edit() async {
    await context.pushNamed(
      Routes.editItem,
      pathParameters: {'id': '${widget.id}'},
    );
    await _refresh();
  }

  // 002 FR-008~012 — 확인 후 옷을 삭제하고 옷장으로 복귀한다.
  Future<void> _delete() async {
    final ok = await DeleteItemDialog.confirm(context);
    if (!ok) return;
    await ref.read(itemRepositoryProvider).delete(widget.id);
    if (!context.mounted) return;
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
    final item = _item;
    if (item == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              onBack: () => context.pop(),
              rightSlot: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (value) {
                  if (value == 'edit') {
                    _edit();
                  } else if (value == 'delete') {
                    _delete();
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'edit', child: Text('수정하기')),
                  PopupMenuItem(value: 'delete', child: Text('삭제하기')),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.md,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.huge + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroImage(item: item),
                    const SizedBox(height: ClosetimoSpacing.xl + 2),
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
                    Row(
                      children: [
                        ChipFilter(
                          label: item.category.label,
                          active: false,
                          onTap: () {},
                        ),
                        const SizedBox(width: ClosetimoSpacing.sm),
                        ChipFilter(
                          label: item.careMethod.label,
                          active: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl + 2),
                    StatsGrid(item: item),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    PrimaryButton(
                      label: '착용 기록하기',
                      leading: const Icon(Icons.add_rounded),
                      onPressed: _recordWear,
                    ),
                    const SizedBox(height: ClosetimoSpacing.sm + 4),
                    SoftButton(
                      label: item.inLaundry ? '바구니에서 제외' : '세탁 바구니',
                      leading: const Icon(Icons.local_laundry_service_rounded),
                      onPressed: _toggleLaundry,
                    ),
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
                    const SizedBox(height: ClosetimoSpacing.md + 2),
                    HistoryTimeline(
                      itemId: item.id,
                      onEdit: _editEventNote,
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
