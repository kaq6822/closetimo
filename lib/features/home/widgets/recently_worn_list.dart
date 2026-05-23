// US5 T069 — 홈 "최근 입은 옷" 섹션.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/item.dart';
import '../../../data/providers/app_providers.dart';

class RecentlyWornList extends ConsumerWidget {
  const RecentlyWornList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream =
        ref.watch(itemRepositoryProvider).watchRecentlyWorn(limit: 2);
    final clock = ref.watch(clockProvider);
    return StreamBuilder<List<Item>>(
      stream: stream,
      builder: (ctx, snap) {
        final items = snap.data ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 입은 옷',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: ClosetimoColors.ink,
                  ),
                ),
                TextButton(
                  onPressed: () => context.goNamed(Routes.wardrobe),
                  child: const Text('전체보기 ›'),
                ),
              ],
            ),
            const SizedBox(height: ClosetimoSpacing.md),
            for (var i = 0; i < items.length; i++) ...[
              _RecentCard(item: items[i], now: clock.now()),
              if (i < items.length - 1)
                const SizedBox(height: ClosetimoSpacing.md - 2),
            ],
          ],
        );
      },
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.item, required this.now});

  final Item item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Material(
      color: surfaces.containerLowest,
      borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          Routes.itemDetail,
          pathParameters: {'id': '${item.id}'},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1 / 1.1,
              child: _Image(
                imagePath: item.imagePath,
                fallback: Color(item.fallbackColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.brand ?? '브랜드 미지정'} · ${item.lastWornAt == null ? '—' : formatRelative(item.lastWornAt!, now: now)}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: ClosetimoColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: surfaces.bgChip,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.totalWears}회 착용',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: ClosetimoColors.ink,
                      ),
                    ),
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

class _Image extends ConsumerWidget {
  const _Image({required this.imagePath, required this.fallback});
  final String? imagePath;
  final Color fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imagePath == null) return Container(color: fallback);
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(imagePath!),
      builder: (ctx, snap) {
        if (snap.data == null) return Container(color: fallback);
        final file = File(snap.data!);
        if (!file.existsSync()) return Container(color: fallback);
        return Image.file(file, fit: BoxFit.cover, cacheWidth: 720);
      },
    );
  }
}
