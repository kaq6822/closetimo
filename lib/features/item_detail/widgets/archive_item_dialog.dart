// #44 — 옷 보관 확인 다이얼로그. 삭제(기록까지 제거)와 구분되도록 "기록은
// 남는다"는 점과 보관함에서 다시 꺼낼 수 있다는 점을 안내하고, 사유를 선택적으로 받는다.

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../data/models/item.dart';

class ArchiveItemDialog {
  const ArchiveItemDialog._();

  /// 사용자가 고를 수 있는 사유(표시 순서).
  static const reasons = [ArchiveReason.seasonal, ArchiveReason.noLongerOwned];

  /// 보관을 확정하면 선택한 사유(고르지 않았으면 [ArchiveReason.unspecified]),
  /// 취소하면 null을 반환한다.
  static Future<ArchiveReason?> show(BuildContext context) {
    return showDialog<ArchiveReason>(
      context: context,
      builder: (ctx) => const _ArchiveItemDialog(),
    );
  }
}

class _ArchiveItemDialog extends StatefulWidget {
  const _ArchiveItemDialog();

  @override
  State<_ArchiveItemDialog> createState() => _ArchiveItemDialogState();
}

class _ArchiveItemDialogState extends State<_ArchiveItemDialog> {
  ArchiveReason _reason = ArchiveReason.unspecified;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이 옷을 보관할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좁은 화면에서 단어 중간 줄바꿈을 피하도록 수동 개행.
          const Text(
            '옷장·홈 통계·세탁 바구니에서 빠지고\n'
            '사진과 착용·세탁 기록은 그대로 남아요.\n'
            '보관함에서 언제든 다시 꺼낼 수 있어요.',
          ),
          const SizedBox(height: ClosetimoSpacing.md),
          const Text(
            '보관 사유(선택)',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: ClosetimoColors.muted,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.sm),
          Wrap(
            spacing: ClosetimoSpacing.sm,
            runSpacing: ClosetimoSpacing.sm,
            children: [
              for (final r in ArchiveItemDialog.reasons)
                ChipFilter(
                  label: r.label,
                  active: _reason == r,
                  // 같은 칩을 다시 누르면 선택 해제(사유 없음).
                  onTap: () => setState(
                    () =>
                        _reason = _reason == r ? ArchiveReason.unspecified : r,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reason),
          child: const Text('보관'),
        ),
      ],
    );
  }
}
