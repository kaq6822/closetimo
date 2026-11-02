// 005 — 옷 사진 공용 표시(옷장 타일·상세·홈·세탁·보관함).
// sandbox 상대 경로를 절대 경로로 바꿔 그리고, 배경 제거본(투명 PNG)은 잘리지 않게
// 여백을 두고 contain으로, 원본은 cover로 채운다. 파일이 없으면 플레이스홀더.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../persistence/image_store.dart';
import 'item_placeholder.dart';

class ItemPhoto extends ConsumerWidget {
  const ItemPhoto({
    required this.imagePath,
    required this.fallback,
    this.cutout = false,
    this.cacheWidth,
    this.cutoutPadding = ClosetimoSpacing.sm,
    this.imageKey,
    this.originalPath,
    super.key,
  });

  /// sandbox 상대 경로(`items/…`). null이면 플레이스홀더.
  final String? imagePath;

  /// 사진이 없거나 읽지 못할 때의 대표 색.
  final Color fallback;

  /// [imagePath]가 배경 제거본인지.
  final bool cutout;

  /// 디코딩 가로 크기(스크롤 성능, SC-004).
  final int? cacheWidth;

  /// 배경 제거본 둘레 여백.
  final double cutoutPadding;

  /// 실제 사진 [Image]에 붙일 key(테스트에서 사진 표시 여부 확인용).
  final Key? imageKey;

  /// [cutout]일 때 배경 제거본 파일이 없으면 대신 그릴 원본 상대 경로.
  final String? originalPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = imagePath;
    if (path == null) return ItemPlaceholder(color: fallback);
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(path),
      builder: (ctx, snap) {
        if (snap.data == null) return ColoredBox(color: fallback);
        final file = File(snap.data!);
        if (!file.existsSync()) {
          // 배경 제거본만 사라졌으면 원본으로 대신 그린다.
          if (cutout && originalPath != null) {
            return ItemPhoto(
              imagePath: originalPath,
              fallback: fallback,
              cacheWidth: cacheWidth,
              imageKey: imageKey,
            );
          }
          return ColoredBox(color: fallback);
        }
        if (!cutout) {
          return Image.file(
            file,
            key: imageKey,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
          );
        }
        final surfaces = Theme.of(ctx).extension<ClosetimoSurfaces>();
        return ColoredBox(
          color: surfaces?.containerLow ?? ClosetimoColors.surfaceContainerLow,
          child: Padding(
            padding: EdgeInsets.all(cutoutPadding),
            child: Image.file(
              file,
              key: imageKey,
              fit: BoxFit.contain,
              cacheWidth: cacheWidth,
            ),
          ),
        );
      },
    );
  }
}
