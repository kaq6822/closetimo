// US4 T059 — 세탁 바구니 리스트 타일.

import '../../../core/widgets/item_placeholder.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/persistence/image_store.dart';
import '../../../core/widgets/min_touch_target.dart';
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

  void _openDetail(BuildContext context) => context.pushNamed(
    Routes.itemDetail,
    pathParameters: {'id': '${item.id}'},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final progress = item.washCycle == 0
        ? 0.0
        : (item.wearSinceWash / item.washCycle).clamp(0.0, 1.0);
    return Container(
      // #49 — 우측 체크의 48×48 터치 영역 여백만큼 오른쪽 패딩을 줄여 체크 원의
      // 시각 위치를 유지한다.
      padding: const EdgeInsets.fromLTRB(
        ClosetimoSpacing.space14,
        ClosetimoSpacing.space14,
        ClosetimoSpacing.space4,
        ClosetimoSpacing.space14,
      ),
      decoration: BoxDecoration(
        color: selected ? surfaces.bgMintSoft : surfaces.containerLowest,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
        boxShadow: selected ? null : ClosetimoElevation.cardShadow,
      ),
      child: Row(
        children: [
          // #17 — 썸네일만 상세로 가고 라벨도 없던 영역을 썸네일+정보 전체 탭으로 넓히고
          // "<옷 이름> 상세 보기"로 읽게 한다. 우측 체크 탭 영역과는 분리돼 있다.
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              // value는 Android content-desc에서 label보다 먼저 읽혀 옷 이름이
              // 맨 뒤로 밀린다(N-03). 이름이 먼저 오도록 한 label에 담는다.
              label:
                  '${item.name} 상세 보기, '
                  '${item.category.label} · ${item.careMethod.label}, '
                  '착용 ${item.wearSinceWash}/${item.washCycle}',
              excludeSemantics: true,
              onTap: () => _openDetail(context),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openDetail(context),
                child: Row(
                  children: [
                    _Thumb(
                      imagePath: item.imagePath,
                      fallback: Color(item.fallbackColor),
                    ),
                    const SizedBox(width: ClosetimoSpacing.space14),
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
                          const SizedBox(height: ClosetimoSpacing.space4),
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
                              const SizedBox(width: ClosetimoSpacing.space10),
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: ClosetimoSpacing.space2),
          _CheckCircle(
            label: '${item.name} 선택',
            selected: selected,
            onTap: onToggleSelection,
          ),
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
        width: ClosetimoSize.tileThumbnail,
        height: ClosetimoSize.tileThumbnail,
        child: _resolve(ref),
      ),
    );
  }

  Widget _resolve(WidgetRef ref) {
    if (imagePath == null) return ItemPlaceholder(color: fallback);
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
  const _CheckCircle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    // #17 — 원형 체크는 시각 상태만 있어 TalkBack이 이름·체크 여부를 읽지 못했다.
    // #49 — 시각 원(28)은 유지하고 터치 영역을 48×48로 넓힌다. 비선택 상태도
    // 체크 컨트롤로 보이도록 빈 원 윤곽선을 그린다.
    return MinTouchTarget(
      onTap: onTap,
      child: Semantics(
        container: true,
        label: label,
        checked: selected,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            key: const ValueKey('laundryCheckVisual'),
            width: ClosetimoSpacing.space28,
            height: ClosetimoSpacing.space28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? ClosetimoColors.primary
                  : surfaces.containerLowest,
              border: selected
                  ? null
                  : Border.all(
                      color: ClosetimoColors.muted,
                      width: ClosetimoSize.controlOutline,
                    ),
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: ClosetimoColors.onPrimary,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
