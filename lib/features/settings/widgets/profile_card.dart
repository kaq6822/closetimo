// US5 T072 — 설정 프로필 카드.

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.monthsTogether, super.key});

  final int monthsTogether;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClosetimoColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ClosetimoColors.bgMint,
            ),
            alignment: Alignment.center,
            child: const Text(
              '큐',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ClosetimoColors.primary,
              ),
            ),
          ),
          const SizedBox(width: ClosetimoSpacing.md - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '큐레이터님',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ClosetimoColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthsTogether <= 0
                      ? '오늘부터 함께해요'
                      : '$monthsTogether개월 함께한 큐레이터',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: ClosetimoColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
