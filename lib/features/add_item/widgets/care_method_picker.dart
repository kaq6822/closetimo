// US1 T036 — 세탁 방법 3분할(DRY CLEAN / MACHINE / HAND WASH) 라디오 그리드.

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
      };

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Row(
      children: [
        for (var i = 0; i < CareMethod.values.length; i++) ...[
          if (i > 0) const SizedBox(width: ClosetimoSpacing.sm + 2),
          Expanded(
            child: _CareTile(
              icon: _iconOf(CareMethod.values[i]),
              label: CareMethod.values[i].code,
              active: value == CareMethod.values[i],
              bg: surfaces.containerLow,
              activeBg: surfaces.tertiarySoft,
              onTap: () => onChanged(CareMethod.values[i]),
            ),
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
    return Material(
      color: active ? activeBg : bg,
      borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: ClosetimoSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: ClosetimoSpacing.sm + 2),
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
    );
  }
}
