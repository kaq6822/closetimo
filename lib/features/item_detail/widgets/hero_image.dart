// US3 T053 — 상세 화면 hero 이미지 + 좌하단 브랜드 라벨.
// FR-009a(#47) — 사진이 없으면 3:4 빈 영역 대신 짧은 헤더를, 사진이 있으면
// 화면 높이의 일정 비율 이내로 제한해 주요 액션이 첫 화면에 들어오게 한다.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/widgets/item_placeholder.dart';
import '../../../data/models/item.dart';

class HeroImage extends ConsumerWidget {
  const HeroImage({required this.item, super.key});

  final Item item;

  /// 사진 영역이 차지할 수 있는 최대 화면 높이 비율(FR-009a).
  static const maxScreenHeightFraction = 0.45;

  /// 좁은 화면에서도 보장하는 최소 사진 높이 비율.
  static const minScreenHeightFraction = 0.3;

  /// 사진 아래 첫 화면에 남겨 둘 높이(상단바·이름 2줄·칩·"착용 기록하기").
  static const reservedBelowHeight = 380.0;

  /// 화면 높이 기준 사진 최대 높이. 정상 화면은 45%, 좁은 화면은 주요 액션이
  /// 들어올 만큼 줄이되 최소 30%는 유지한다.
  static double maxHeightFor(double screenHeight) => math.max(
    screenHeight * minScreenHeightFraction,
    math.min(
      screenHeight * maxScreenHeightFraction,
      screenHeight - reservedBelowHeight,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.imagePath == null) return _CompactHeader(item: item);
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ClosetimoRadius.xxl),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              // 3:4 비율을 기본으로 하되 화면 높이 제한을 넘으면 cover로 크롭한다.
              final height = math.min(
                constraints.maxWidth * 4 / 3,
                maxHeightFor(screenHeight),
              );
              return SizedBox(
                width: constraints.maxWidth,
                height: height,
                child: _Image(
                  imagePath: item.imagePath,
                  fallback: Color(item.fallbackColor),
                  container: surfaces.container,
                ),
              );
            },
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

/// 사진 없는 옷의 짧은 헤더. 대표 색상 스와치와 브랜드만 보여주고
/// 이름·상태·기록 액션이 바로 아래에 오도록 세로 공간을 거의 쓰지 않는다.
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final hasBrand = item.brand != null && item.brand!.isNotEmpty;
    return Row(
      children: [
        Container(
          key: const ValueKey('detail-compact-swatch'),
          width: ClosetimoSize.tileThumbnail,
          height: ClosetimoSize.tileThumbnail,
          decoration: BoxDecoration(
            color: Color(item.fallbackColor),
            borderRadius: BorderRadius.circular(ClosetimoRadius.lgPlus),
          ),
          child: const Icon(
            Icons.checkroom_rounded,
            color: ClosetimoColors.muted,
          ),
        ),
        const SizedBox(width: ClosetimoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasBrand)
                Text(
                  item.brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: ClosetimoColors.primary,
                  ),
                ),
              const Text(
                '사진 없음 · 수정하기에서 추가할 수 있어요',
                maxLines: 2,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: ClosetimoColors.muted,
                ),
              ),
            ],
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
      return ItemPlaceholder(color: fallback);
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
