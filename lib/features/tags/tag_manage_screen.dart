// #46 — 태그 관리. 태그 이름 변경(같은 이름이 있으면 병합)과 삭제.
// 진입: 설정 > 옷 관리 > 태그 관리 (contracts/routes.md `/tags`).
// 태그를 지우거나 합쳐도 옷과 착용·세탁 기록은 그대로 남는다.
// #48 FR-029·030 — 읽기 실패·재시도, 변경 중 중복 입력 차단·실패 안내.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/action_guard.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item_tags.dart';
import '../../data/providers/app_providers.dart';

class TagManageScreen extends ConsumerStatefulWidget {
  const TagManageScreen({super.key});

  @override
  ConsumerState<TagManageScreen> createState() => _TagManageScreenState();
}

class _TagManageScreenState extends ConsumerState<TagManageScreen>
    with ActionGuardMixin {
  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    TagUsage usage,
    List<TagUsage> all,
  ) async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: usage.name),
    );
    if (raw == null || !context.mounted) return;
    final target = normalizeTag(raw);
    if (target == null || target == usage.name) return;
    // 같은 이름(대소문자 무시)의 다른 태그가 있으면 병합임을 확인받는다.
    final existing = all
        .where(
          (u) =>
              u.name != usage.name &&
              u.name.toLowerCase() == target.toLowerCase(),
        )
        .firstOrNull;
    if (existing != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('태그를 합칠까요?'),
          content: Text(
            "'${usage.name}'(${usage.itemCount}벌)을 "
            "'${existing.name}'(${existing.itemCount}벌)에 합쳐요. "
            '두 태그가 모두 붙은 옷은 하나로 정리돼요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('합치기'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    final to = existing?.name ?? target;
    final ok = await runGuarded(
      () => ref.read(tagRepositoryProvider).renameTag(usage.name, to),
      failureMessage: '태그를 바꾸지 못했어요. 다시 시도해 주세요.',
    );
    if (!ok || !context.mounted) return;
    showClosetimoToast(
      context,
      existing != null ? "'$to' 태그로 합쳤어요" : "'$to'(으)로 이름을 바꿨어요",
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TagUsage usage,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("'${usage.name}' 태그를 지울까요?"),
        content: Text('${usage.itemCount}벌에서 태그만 떼어요. 옷과 착용 기록은 그대로 남아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final done = await runGuarded(
      () => ref.read(tagRepositoryProvider).deleteTag(usage.name),
      failureMessage: '태그를 지우지 못했어요. 다시 시도해 주세요.',
    );
    if (!done || !context.mounted) return;
    showClosetimoToast(context, "'${usage.name}' 태그를 지웠어요");
  }

  @override
  Widget build(BuildContext context) {
    final usages = ref.watch(tagUsageProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(subtitle: '태그 관리', onBack: () => context.pop()),
            if (actionBusy) const LinearProgressIndicator(),
            Expanded(
              child: usages.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) {
                  debugPrint('Failed to load tag usages: $e');
                  return AsyncErrorView(
                    message: '태그를 불러오지 못했어요',
                    onRetry: () => ref.invalidate(tagUsageProvider),
                  );
                },
                data: (all) => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    ClosetimoSpacing.lg,
                    ClosetimoSpacing.md,
                    ClosetimoSpacing.lg,
                    ClosetimoSpacing.space76,
                  ),
                  children: [
                    const Text(
                      '이름을 바꾸면 태그가 붙은 모든 옷에 반영돼요. 이미 있는 이름으로 '
                      '바꾸면 두 태그를 합쳐요. 태그를 지워도 옷과 착용 기록은 남아요.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: ClosetimoColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    if (all.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: ClosetimoSpacing.space40),
                        child: Center(
                          child: Text(
                            '아직 만든 태그가 없어요.\n'
                            '옷 수정 화면이나 옷장 다중 선택에서 붙일 수 있어요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: ClosetimoColors.muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final u in all) ...[
                        _TagRow(
                          key: ValueKey('tag-${u.name}'),
                          usage: u,
                          onRename: actionBusy
                              ? null
                              : () => _rename(context, ref, u, all),
                          onDelete: actionBusy
                              ? null
                              : () => _delete(context, ref, u),
                        ),
                        const SizedBox(height: ClosetimoSpacing.sm),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.usage,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final TagUsage usage;

  /// 다른 변경이 진행 중이면 null(비활성).
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Material(
      color: surfaces.containerLow,
      borderRadius: BorderRadius.circular(ClosetimoRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(
          left: ClosetimoSpacing.space18,
          right: ClosetimoSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                usage.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: ClosetimoColors.ink,
                ),
              ),
            ),
            Text(
              '${usage.itemCount}벌',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: ClosetimoColors.muted,
              ),
            ),
            IconButton(
              tooltip: "'${usage.name}' 이름 변경",
              onPressed: onRename,
              icon: const Icon(Icons.edit_outlined, color: ClosetimoColors.ink),
            ),
            IconButton(
              tooltip: "'${usage.name}' 삭제",
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: ClosetimoColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('태그 이름 변경'),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        maxLength: maxTagLength,
        decoration: const InputDecoration(hintText: '새 이름'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _ctl,
          builder: (context, value, _) => TextButton(
            onPressed: normalizeTag(value.text) == null
                ? null
                : () => Navigator.pop(context, _ctl.text),
            child: const Text('변경'),
          ),
        ),
      ],
    );
  }
}
