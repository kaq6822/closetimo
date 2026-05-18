// 토널 진행 바. variant alert는 세탁 임박을 시각적으로 표시.

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum ProgressBarVariant { normal, alert }

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.value,
    this.variant = ProgressBarVariant.normal,
    super.key,
  });

  final double value;
  final ProgressBarVariant variant;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final clamped = value.clamp(0.0, 1.0);
    final foreground = variant == ProgressBarVariant.alert
        ? ClosetimoColors.tertiary
        : ClosetimoColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ClosetimoRadius.full),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: surfaces.containerHigh),
            FractionallySizedBox(
              widthFactor: clamped,
              child: Container(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
