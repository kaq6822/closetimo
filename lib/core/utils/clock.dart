// 테스트에서 시간을 고정하기 위한 Clock 추상화.
// 모든 repository는 `DateTime.now()`를 직접 호출하지 않고 본 인터페이스를 사용한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
