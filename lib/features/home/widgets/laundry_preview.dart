// US5 T070 — 홈 세탁 바구니 미리보기 + 전문가 팁.
// FR-021(#47) — 실제 썸네일, 전체 대기 수, 세탁 화면 이동, 빈 바구니 안내를 제공한다.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/item.dart';
import '../../../data/providers/app_providers.dart';

final _laundryTipsProvider = FutureProvider<List<String>>((ref) async {
  final raw = await rootBundle.loadString('assets/tips/laundry_tips.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['tips'] as List).cast<String>();
});

/// 앱 부트 시 한 번만 결정되는 팁 인덱스 시드.
/// rebuild에도 같은 팁이 표시되도록 [Random]을 build 밖으로 격리한다.
final _laundryTipIndexProvider = Provider<int>((ref) {
  return Random().nextInt(1 << 20);
});

class LaundryPreview extends ConsumerWidget {
  const LaundryPreview({super.key});

  /// 미리보기로 보여줄 최대 항목 수(FR-021).
  static const previewLimit = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(laundryRepositoryProvider).watchBasket();
    final tips = ref.watch(_laundryTipsProvider).valueOrNull ?? const [];
    final seed = ref.watch(_laundryTipIndexProvider);
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return StreamBuilder<List<Item>>(
      stream: basket,
      builder: (ctx, snap) {
        final all = snap.data ?? const <Item>[];
        final items = all.take(previewLimit).toList();
        final rest = all.length - items.length;
        return Container(
          padding: const EdgeInsets.all(ClosetimoSpacing.space20),
          decoration: BoxDecoration(
            color: surfaces.containerLow,
            borderRadius: BorderRadius.circular(ClosetimoRadius.xlMinus),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.opacity_rounded,
                    size: 18,
                    color: ClosetimoColors.tertiary,
                  ),
                  const SizedBox(width: ClosetimoSpacing.sm),
                  const Text(
                    '세탁 바구니',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: ClosetimoColors.ink,
                    ),
                  ),
                  if (all.isNotEmpty) ...[
                    const SizedBox(width: ClosetimoSpacing.sm),
                    Text(
                      '${all.length}점 대기',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ClosetimoColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: ClosetimoSpacing.space12),
              if (items.isEmpty)
                const _EmptyBasket()
              else ...[
                for (var i = 0; i < items.length; i++) ...[
                  _Row(item: items[i]),
                  if (i < items.length - 1)
                    const SizedBox(height: ClosetimoSpacing.space12),
                ],
                if (rest > 0) ...[
                  const SizedBox(height: ClosetimoSpacing.space12),
                  Text(
                    '외 $rest점',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: ClosetimoColors.muted,
                    ),
                  ),
                ],
              ],
              // 좁은 화면에서도 제목 줄이 넘치지 않도록 이동 액션은 목록 아래에 둔다.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.goNamed(Routes.laundry),
                  child: const Text('세탁 화면으로 ›'),
                ),
              ),
              if (tips.isNotEmpty) ...[
                const SizedBox(height: ClosetimoSpacing.space18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClosetimoSpacing.space16,
                    vertical: ClosetimoSpacing.space14,
                  ),
                  decoration: BoxDecoration(
                    color: surfaces.container,
                    borderRadius: BorderRadius.circular(ClosetimoRadius.md),
                  ),
                  child: Text(
                    '전문가의 팁: ${tips[seed % tips.length]}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: ClosetimoColors.primary,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 빈 바구니 안내. 대기 항목(썸네일+진행률)과 형태가 달라 오해되지 않게 한다.
class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 18,
          color: ClosetimoColors.muted,
        ),
        SizedBox(width: ClosetimoSpacing.sm),
        Expanded(
          child: Text(
            '바구니가 비어 있어요. 상세에서 "세탁 바구니"를 누르면 여기에 모여요.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: ClosetimoColors.muted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final progress = item.washCycle == 0
        ? 0.0
        : (item.wearSinceWash / item.washCycle).clamp(0.0, 1.0);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ClosetimoRadius.xs),
          child: Container(
            width: 42,
            height: 54,
            color: Color(item.fallbackColor),
            child: _Thumbnail(
              imagePath: item.imagePath,
              fallback: Color(item.fallbackColor),
            ),
          ),
        ),
        const SizedBox(width: ClosetimoSpacing.space12),
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
                  fontSize: 14,
                  color: ClosetimoColors.ink,
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.space6),
              Row(
                children: [
                  Expanded(
                    child: ProgressBar(
                      value: progress,
                      variant: ProgressBarVariant.alert,
                    ),
                  ),
                  const SizedBox(width: ClosetimoSpacing.sm),
                  Text(
                    '${item.wearSinceWash}/${item.washCycle}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: ClosetimoColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 실제 사진 썸네일. 사진이 없거나 파일이 사라졌으면 대표 색상으로 폴백한다.
class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.imagePath, required this.fallback});

  final String? imagePath;
  final Color fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = Container(color: fallback);
    if (imagePath == null) return placeholder;
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<String>(
      future: store.absolutePath(imagePath!),
      builder: (ctx, snap) {
        if (snap.data == null) return placeholder;
        final file = File(snap.data!);
        if (!file.existsSync()) return placeholder;
        return Image.file(
          file,
          key: const ValueKey('laundry-preview-photo'),
          fit: BoxFit.cover,
          cacheWidth: 256,
        );
      },
    );
  }
}
