// US1 T036 — 관리 방법 라디오 그리드. #45 — '미지정'을 추가해 2x2로 배치한다.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../data/models/item.dart';

class CareMethodPicker extends StatelessWidget {
  const CareMethodPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final CareMethod value;
  final ValueChanged<CareMethod> onChanged;

  IconData _iconOf(CareMethod m) => switch (m) {
    CareMethod.dryClean => Icons.circle_outlined,
    CareMethod.machine => Icons.local_laundry_service_outlined,
    CareMethod.handWash => Icons.pan_tool_outlined,
    CareMethod.unspecified => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    Widget tile(CareMethod m) => Expanded(
      child: _CareTile(
        icon: _iconOf(m),
        label: m.label,
        active: value == m,
        bg: surfaces.containerLow,
        activeBg: surfaces.tertiarySoft,
        onTap: () => onChanged(m),
      ),
    );
    // 표시 순서: 미지정을 먼저 두어 "모르면 비워 둬도 된다"를 드러낸다.
    const order = [
      CareMethod.unspecified,
      CareMethod.machine,
      CareMethod.handWash,
      CareMethod.dryClean,
    ];
    return Column(
      children: [
        for (var row = 0; row < order.length; row += 2) ...[
          if (row > 0) const SizedBox(height: ClosetimoSpacing.space10),
          Row(
            children: [
              tile(order[row]),
              const SizedBox(width: ClosetimoSpacing.space10),
              tile(order[row + 1]),
            ],
          ),
        ],
      ],
    );
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.bg,
    required this.activeBg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color bg;
  final Color activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? ClosetimoColors.tertiary : ClosetimoColors.ink;
    // 선택 상태를 색 외에 시맨틱으로도 노출한다.
    return Semantics(
      container: true,
      button: true,
      selected: active,
      child: Material(
        color: active ? activeBg : bg,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClosetimoSpacing.space8,
              vertical: ClosetimoSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: ClosetimoSpacing.space10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
