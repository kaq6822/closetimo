// 옷장이모(Closetimo) entry point.
//
// Phase 2 T029(앱 부트스트랩)에서 ProviderScope + MaterialApp.router + Isar
// 초기화를 채운다. 현재는 Phase 1 빌드 검증을 위한 최소 스텁이다.

import 'package:flutter/material.dart';

void main() {
  runApp(const _PhaseOnePlaceholder());
}

class _PhaseOnePlaceholder extends StatelessWidget {
  const _PhaseOnePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '옷장이모',
      home: Scaffold(
        body: Center(
          child: Text('Phase 1 setup complete'),
        ),
      ),
    );
  }
}
