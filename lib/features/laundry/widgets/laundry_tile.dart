// US4 T059 — 세탁 바구니 리스트 타일.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/item.dart';

class LaundryTile extends ConsumerWidget {
  const LaundryTile({
    required this.item,
    required this.selected,
    required this.onToggleSelection,
    super.key,
  });

  final Item item;
  final bool selected;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final progress = item.washCycle == 0
        ? 0.0
        : (item.wearSinceWash / item.washCycle).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(ClosetimoSpacing.md - 2),
      decoration: BoxDecoration(
        color: selected ? surfaces.bgMintSoft : surfaces.containerLowest,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
        boxShadow: selected ? null : ClosetimoElevation.cardShadow,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.goNamed(
              Routes.itemDetail,
              pathParameters: {'id': '${item.id}'},
            ),
            child: _Thumb(
              imagePath: item.imagePath,
              fallback: Color(item.fallbackColor),
            ),
          ),
          const SizedBox(width: ClosetimoSpacing.md - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ClosetimoColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category.label} · ${item.careMethod.label}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: ClosetimoColors.muted,
                  ),
                ),
                const SizedBox(height: ClosetimoSpacing.sm),
                Row(
                  children: [
                    Text(
                      '${item.wearSinceWash}/${item.washCycle}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                    const SizedBox(width: ClosetimoSpacing.sm + 2),
                    Expanded(
                      child: ProgressBar(
                        value: progress,
                        variant: ProgressBarVariant.alert,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: ClosetimoSpacing.sm + 2),
          _CheckCircle(selected: selected, onTap: onToggleSelection),
        ],
      ),
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.imagePath, required this.fallback});

  final String? imagePath;
  final Color fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClosetimoRadius.md),
      child: SizedBox(
        width: 62,
        height: 62,
        child: _resolve(ref),
      ),
    );
  }

  Widget _resolve(WidgetRef ref) {
    if (imagePath == null) return Container(color: fallback);
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(imagePath!),
      builder: (ctx, snap) {
        if (snap.data == null) return Container(color: fallback);
        final file = File(snap.data!);
        if (!file.existsSync()) return Container(color: fallback);
        return Image.file(file, fit: BoxFit.cover, cacheWidth: 256);
      },
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              selected ? ClosetimoColors.primary : surfaces.containerHighest,
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: ClosetimoColors.onPrimary,
              )
            : null,
      ),
    );
  }
}
