// US3 T053 — 상세 화면 hero 이미지 + 좌하단 브랜드 라벨.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../data/models/item.dart';

class HeroImage extends ConsumerWidget {
  const HeroImage({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ClosetimoRadius.xxl),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: _Image(
              imagePath: item.imagePath,
              fallback: Color(item.fallbackColor),
              container: surfaces.container,
            ),
          ),
        ),
        if (item.brand != null && item.brand!.isNotEmpty)
          Positioned(
            left: -12,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ClosetimoSpacing.lg,
                vertical: ClosetimoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: surfaces.containerLowest,
                borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
                boxShadow: ClosetimoElevation.ambientShadow,
              ),
              child: Text(
                item.brand!,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: ClosetimoColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Image extends ConsumerWidget {
  const _Image({
    required this.imagePath,
    required this.fallback,
    required this.container,
  });

  final String? imagePath;
  final Color fallback;
  final Color container;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imagePath == null) {
      return Container(color: fallback);
    }
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(imagePath!),
      builder: (ctx, snap) {
        if (snap.data == null) return Container(color: container);
        final file = File(snap.data!);
        if (!file.existsSync()) return Container(color: fallback);
        return Image.file(file, fit: BoxFit.cover, cacheWidth: 1200);
      },
    );
  }
}
