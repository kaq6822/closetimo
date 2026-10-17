// #44 — 보관함. 보관한 옷을 확인하고 기록을 유지한 채 옷장으로 꺼낸다.
// 진입: 설정 > 옷 관리 > 보관함 (contracts/routes.md `/archive`).
// #48 FR-029·030 — 읽기 실패·재시도, 꺼내기 중복 입력 차단·실패 안내.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/persistence/image_store.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/action_guard.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/item_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/providers/app_providers.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen>
    with ActionGuardMixin {
  Future<void> _restore(Item item) => runGuarded(() async {
    await ref.read(archiveRepositoryProvider).restore(item.id);
    if (!mounted) return;
    showClosetimoToast(context, '${item.name}을(를) 옷장으로 꺼냈어요');
  }, failureMessage: '옷장으로 꺼내지 못했어요. 다시 시도해 주세요.');

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(archiveRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(subtitle: '보관함', onBack: () => context.pop()),
            if (actionBusy) const LinearProgressIndicator(),
            Expanded(
              child: StreamStateBuilder<List<Item>>(
                stream: repo.watchArchived,
                streamKey: repo,
                errorMessage: '보관함을 불러오지 못했어요',
                builder: (context, items) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      ClosetimoSpacing.lg,
                      ClosetimoSpacing.md,
                      ClosetimoSpacing.lg,
                      ClosetimoSpacing.space76,
                    ),
                    children: [
                      const Text(
                        '보관한 옷은 옷장·홈 통계·세탁 바구니에서 빠지고\n'
                        '착용·세탁 기록은 그대로 남아요.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: ClosetimoColors.muted,
                        ),
                      ),
                      const SizedBox(height: ClosetimoSpacing.xl),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(
                            top: ClosetimoSpacing.space40,
                          ),
                          child: Center(
                            child: Text(
                              '보관한 옷이 없어요',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: ClosetimoColors.muted,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final item in items) ...[
                          _ArchivedTile(
                            key: ValueKey('archived-${item.id}'),
                            item: item,
                            onRestore: actionBusy ? null : () => _restore(item),
                          ),
                          const SizedBox(height: ClosetimoSpacing.space12),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedTile extends ConsumerWidget {
  const _ArchivedTile({required this.item, required this.onRestore, super.key});

  final Item item;

  /// 다른 꺼내기가 진행 중이면 null(비활성).
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final reason = item.archiveReason == ArchiveReason.unspecified
        ? null
        : item.archiveReason.label;
    final meta = [
      ?reason,
      '${formatFullDate(item.archivedAt!)} 보관',
      '총 착용 ${item.totalWears}회',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(ClosetimoSpacing.space14),
      decoration: BoxDecoration(
        color: surfaces.containerLowest,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              label: '${item.name} 상세 보기, ${item.category.label}, $meta',
              excludeSemantics: true,
              onTap: () => _openDetail(context),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openDetail(context),
                child: Row(
                  children: [
                    _Thumb(item: item),
                    const SizedBox(width: ClosetimoSpacing.space14),
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
                              color: ClosetimoColors.ink,
                            ),
                          ),
                          const SizedBox(height: ClosetimoSpacing.space4),
                          Text(
                            '${item.category.label} · $meta',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: ClosetimoColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: ClosetimoSpacing.space10),
          TextButton(
            onPressed: onRestore,
            child: Semantics(
              label: '${item.name} 옷장으로 꺼내기',
              excludeSemantics: true,
              child: const Text('꺼내기'),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) => context.pushNamed(
    Routes.itemDetail,
    pathParameters: {'id': '${item.id}'},
  );
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Color(item.fallbackColor);
    final path = item.imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ClosetimoRadius.md),
      child: SizedBox(
        width: ClosetimoSize.tileThumbnail,
        height: ClosetimoSize.tileThumbnail,
        child: path == null
            ? ItemPlaceholder(color: fallback)
            : FutureBuilder<String>(
                future: ref.watch(imageStoreProvider).absolutePath(path),
                builder: (ctx, snap) {
                  if (snap.data == null) return Container(color: fallback);
                  final file = File(snap.data!);
                  if (!file.existsSync()) return Container(color: fallback);
                  return Image.file(file, fit: BoxFit.cover, cacheWidth: 256);
                },
              ),
      ),
    );
  }
}
