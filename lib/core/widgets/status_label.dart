// FR-008 — 옷 타일 좌상단 "깨끗함" / "세탁 필요" 라벨.

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum StatusLabelVariant { clean, dirty }

class StatusLabel extends StatelessWidget {
  const StatusLabel({required this.variant, super.key});

  final StatusLabelVariant variant;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final isClean = variant == StatusLabelVariant.clean;
    final bg = isClean ? surfaces.tertiarySoft : surfaces.containerHighest;
    final fg = isClean ? ClosetimoColors.tertiary : ClosetimoColors.inkSoft;
    final icon = isClean ? Icons.check_rounded : Icons.opacity_rounded;
    final text = isClean ? '깨끗함' : '세탁 필요';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClosetimoRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
