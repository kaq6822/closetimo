// US2 T043 — 옷장 그리드 단일 타일.
// #43 — 빠른 동작 메뉴(착용 기록·바구니 담기/빼기, FR-008a)와 다중 선택(FR-008b).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/item_placeholder.dart';
import '../../../core/widgets/status_label.dart';
import '../../../core/widgets/toast.dart';
import '../../../data/models/item.dart';
import '../../../data/providers/app_providers.dart';
import '../selection/item_selection.dart';

enum _QuickAction { recordWear, toggleLaundry }

class GarmentTile extends ConsumerWidget {
  const GarmentTile({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final showCleanBadge = item.wearSinceWash == 0;
    final showDirtyBadge = item.status == ItemStatus.dirty;
    final (selecting, selected) = ref.watch(
      wardrobeSelectionProvider.select((s) => (s.active, s.contains(item.id))),
    );
    final selection = ref.read(wardrobeSelectionProvider.notifier);
    return Material(
      color: selected ? ClosetimoColors.primarySoft : surfaces.containerLowest,
      borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selecting
            ? () => selection.toggle(item.id)
            : () => context.pushNamed(
                Routes.itemDetail,
                pathParameters: {'id': '${item.id}'},
              ),
        onLongPress: selecting
            ? () => selection.toggle(item.id)
            : () => selection.start(item.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1 / 1.05,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ItemImage(
                      imagePath: item.imagePath,
                      fallback: Color(item.fallbackColor),
                    ),
                    if (showCleanBadge || showDirtyBadge)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: StatusLabel(
                          variant: showCleanBadge
                              ? StatusLabelVariant.clean
                              : StatusLabelVariant.dirty,
                        ),
                      ),
                    Positioned(
                      top: ClosetimoSpacing.space4,
                      right: ClosetimoSpacing.space4,
                      child: selecting
                          ? _SelectionMark(selected: selected)
                          : _QuickActionMenu(item: item),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClosetimoSpacing.space14,
                ClosetimoSpacing.space14,
                ClosetimoSpacing.space14,
                ClosetimoSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ClosetimoColors.ink,
                    ),
                  ),
                  const SizedBox(height: ClosetimoSpacing.space10),
                  // #19 — 큰 글꼴에서 "마지막 세/탁"처럼 단어 중간에서 줄바꿈하지 않도록
                  // 한 줄을 유지하고 공간이 모자라면 글자를 줄인다.
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetaLabel('착용 횟수'),
                      SizedBox(width: ClosetimoSpacing.space4),
                      _MetaLabel('마지막 세탁', alignEnd: true),
                    ],
                  ),
                  const SizedBox(height: ClosetimoSpacing.space2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.wearSinceWash}/${item.washCycle}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ClosetimoColors.ink,
                        ),
                      ),
                      Text(
                        item.lastWashedAt == null
                            ? '—'
                            : formatMonthDay(item.lastWashedAt!),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ClosetimoColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel(this.text, {this.alignEnd = false});

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: ClosetimoColors.muted,
          ),
        ),
      ),
    );
  }
}

/// 다중 선택 모드에서 타일 우상단에 선택 여부를 보여준다.
class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Semantics(
      checked: selected,
      label: selected ? '선택됨' : '선택 안 됨',
      child: Padding(
        padding: const EdgeInsets.all(ClosetimoSpacing.space8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? ClosetimoColors.primary
                : surfaces.containerLowest,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(ClosetimoSpacing.space2),
            child: Icon(
              selected ? Icons.check_rounded : Icons.circle_outlined,
              size: 20,
              color: selected
                  ? ClosetimoColors.onPrimary
                  : ClosetimoColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// 상세를 열지 않고 실행하는 빠른 동작(FR-008a).
class _QuickActionMenu extends ConsumerWidget {
  const _QuickActionMenu({required this.item});

  final Item item;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    _QuickAction action,
  ) async {
    switch (action) {
      case _QuickAction.recordWear:
        // 메모 없이 기록한다. 메모는 상세 타임라인에서 사후 편집(FR-010a).
        await ref.read(eventRepositoryProvider).recordWear(item.id);
        if (!context.mounted) return;
        showClosetimoToast(context, '오늘의 착용이 기록되었어요');
      case _QuickAction.toggleLaundry:
        final wasIn = item.inLaundry;
        await ref.read(laundryRepositoryProvider).toggle(item.id);
        if (!context.mounted) return;
        showClosetimoToast(context, wasIn ? '세탁 바구니에서 제외됐어요' : '세탁 바구니에 담겼어요');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Material(
      color: surfaces.containerLowest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<_QuickAction>(
        tooltip: '${item.name} 빠른 동작',
        icon: const Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: ClosetimoColors.ink,
        ),
        color: surfaces.containerLowest,
        onSelected: (a) => _run(context, ref, a),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: _QuickAction.recordWear,
            child: Text('착용 기록'),
          ),
          PopupMenuItem(
            value: _QuickAction.toggleLaundry,
            child: Text(item.inLaundry ? '세탁 바구니에서 빼기' : '세탁 바구니에 담기'),
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends ConsumerWidget {
  const _ItemImage({required this.imagePath, required this.fallback});

  final String? imagePath;
  final Color fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imagePath == null) {
      return ItemPlaceholder(color: fallback);
    }
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(imagePath!),
      builder: (ctx, snap) {
        if (snap.data == null) return Container(color: fallback);
        final file = File(snap.data!);
        if (!file.existsSync()) return Container(color: fallback);
        // cacheWidth=480은 2x retina 기준 240lp 그리드 타일에 충분하며
        // 1600px 원본을 매 스크롤 디코딩하지 않도록 막는다(SC-004 가드).
        return Image.file(file, fit: BoxFit.cover, cacheWidth: 480);
      },
    );
  }
}
