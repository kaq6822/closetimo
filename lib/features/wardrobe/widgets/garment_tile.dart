// US2 T043 — 옷장 그리드 단일 타일.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_label.dart';
import '../../../data/models/item.dart';

class GarmentTile extends ConsumerWidget {
  const GarmentTile({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final showCleanBadge = item.wearSinceWash == 0;
    final showDirtyBadge = item.status == ItemStatus.dirty;
    return Material(
      color: surfaces.containerLowest,
      borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed(
          Routes.itemDetail,
          pathParameters: {'id': '${item.id}'},
        ),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '착용 횟수',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: ClosetimoColors.muted,
                        ),
                      ),
                      Text(
                        '마지막 세탁',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: ClosetimoColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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

class _ItemImage extends ConsumerWidget {
  const _ItemImage({required this.imagePath, required this.fallback});

  final String? imagePath;
  final Color fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imagePath == null) {
      return Container(color: fallback);
    }
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(imagePath!),
      builder: (ctx, snap) {
        if (snap.data == null) return Container(color: fallback);
        final file = File(snap.data!);
        if (!file.existsSync()) return Container(color: fallback);
        return Image.file(file, fit: BoxFit.cover);
      },
    );
  }
}
