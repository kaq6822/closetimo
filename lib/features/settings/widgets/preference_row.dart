// US5 T073 — 설정 항목 행 (토글 또는 텍스트 값).

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';

class PreferenceRow extends StatelessWidget {
  const PreferenceRow({
    required this.label,
    this.toggleValue,
    this.onToggle,
    this.textValue,
    super.key,
  });

  final String label;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final String? textValue;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    // #17 — 스위치 행은 라벨과 스위치를 한 노드로 합쳐 TalkBack이
    // "세탁 알림, 스위치, 켜짐"처럼 함께 읽게 하고, 스위치뿐 아니라 행 전체
    // 탭으로도 토글한다(표준 설정 UX).
    final toggleable = toggleValue != null && onToggle != null;
    return MergeSemantics(
      child: Material(
        color: surfaces.containerLowest,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: toggleable ? () => onToggle!(!toggleValue!) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: ClosetimoSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: ClosetimoColors.ink,
                    ),
                  ),
                ),
                if (toggleable)
                  Switch.adaptive(
                    value: toggleValue!,
                    onChanged: onToggle,
                    activeThumbColor: ClosetimoColors.onPrimary,
                    activeTrackColor: ClosetimoColors.primary,
                  )
                else if (textValue != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        textValue!,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: ClosetimoColors.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: ClosetimoColors.muted,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
