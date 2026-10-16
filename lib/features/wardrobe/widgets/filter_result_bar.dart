// #46 — 옷장 필터 결과 수와 조건 초기화. 조건(검색어·종류·용도·태그·입을 수 있음)이
// 하나라도 걸려 있을 때 목록 위에 보인다.

import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';

class FilterResultBar extends StatelessWidget {
  const FilterResultBar({
    required this.count,
    required this.onReset,
    super.key,
  });

  /// 조건에 맞는 옷 수.
  final int count;

  /// 모든 조건을 지운다.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClosetimoSpacing.lg,
        0,
        ClosetimoSpacing.sm,
        ClosetimoSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                '결과 $count벌',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ClosetimoColors.ink,
                ),
              ),
            ),
          ),
          TextButton(onPressed: onReset, child: const Text('조건 초기화')),
        ],
      ),
    );
  }
}
