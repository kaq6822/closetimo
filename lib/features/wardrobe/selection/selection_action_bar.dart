// #43 — 다중 선택 하단 바(spec FR-008b).
//
// 선택 수·필터 조건·모두 선택·선택 초기화·종료를 공통으로 보여주고, 선택 대상
// 액션은 [SelectionAction] 목록으로 주입받는다. 다중 착용 기록(#39)·일괄 편집(#46)은
// 이 위젯에 액션만 추가해 재사용한다.
// #48 FR-030 — 액션 하나가 끝날 때까지 다른 액션을 막고 "처리 중"을 보인다.
// 액션에는 시트 입력 시간이 포함되므로 애니메이션 진행 막대 대신 정적 문구를 쓴다.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/action_guard.dart';
import '../../../core/widgets/soft_button.dart';

/// 선택 바에 노출하는 선택 대상 액션 1개.
class SelectionAction {
  const SelectionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;

  /// 선택이 0개이면 바가 자동으로 비활성화하므로 여기서 따로 처리하지 않는다.
  /// Future를 돌려주면 끝날 때까지 바의 다른 액션을 막는다(#48).
  final FutureOr<void> Function() onPressed;
}

class SelectionActionBar extends StatefulWidget {
  const SelectionActionBar({
    required this.count,
    required this.filterSummary,
    required this.onSelectAll,
    required this.onClear,
    required this.onExit,
    this.actions = const [],
    super.key,
  });

  /// 선택된 옷 수.
  final int count;

  /// 현재 목록의 필터 조건 요약(예: "상의 · 입을 수 있음"). 선택이 어떤 범위에서
  /// 이뤄졌는지 확인시키기 위해 항상 표시한다.
  final String filterSummary;

  final VoidCallback onSelectAll;

  /// 선택만 비운다(모드 유지).
  final VoidCallback onClear;

  /// 선택 모드를 끝낸다.
  final VoidCallback onExit;

  final List<SelectionAction> actions;

  @override
  State<SelectionActionBar> createState() => _SelectionActionBarState();
}

class _SelectionActionBarState extends State<SelectionActionBar>
    with ActionGuardMixin {
  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final actions = widget.actions;
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    const muted = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 12,
      color: ClosetimoColors.muted,
    );
    return Material(
      color: surfaces.containerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClosetimoSpacing.lg,
          ClosetimoSpacing.sm,
          ClosetimoSpacing.sm,
          ClosetimoSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      actionBusy ? '$count개 처리 중…' : '$count개 선택',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onSelectAll,
                  child: const Text('모두 선택'),
                ),
                TextButton(
                  onPressed: count == 0 ? null : widget.onClear,
                  child: const Text('선택 초기화'),
                ),
                IconButton(
                  tooltip: '선택 종료',
                  onPressed: widget.onExit,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              '필터: ${widget.filterSummary}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: ClosetimoSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(right: ClosetimoSpacing.space14),
                child: Wrap(
                  spacing: ClosetimoSpacing.sm,
                  runSpacing: ClosetimoSpacing.sm,
                  children: [
                    for (final a in actions)
                      SoftButton(
                        label: a.label,
                        leading: Icon(
                          a.icon,
                          size: 18,
                          color: ClosetimoColors.ink,
                        ),
                        onPressed: count == 0 || actionBusy
                            ? null
                            : () => runGuarded(
                                () async => await a.onPressed(),
                                failureMessage: '작업을 완료하지 못했어요. 다시 시도해 주세요.',
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
