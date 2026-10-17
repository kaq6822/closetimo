// #18 — 시각별 홈 인사말.

import 'package:closetimo/core/utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('시각에 따라 아침/오후/저녁 인사를 고른다', () {
    expect(greetingFor(DateTime(2026, 1, 1, 5)), '좋은 아침입니다');
    expect(greetingFor(DateTime(2026, 1, 1, 11, 59)), '좋은 아침입니다');
    expect(greetingFor(DateTime(2026, 1, 1, 12)), '좋은 오후입니다');
    expect(greetingFor(DateTime(2026, 1, 1, 16)), '좋은 오후입니다');
    expect(greetingFor(DateTime(2026, 1, 1, 18)), '좋은 저녁입니다');
    expect(greetingFor(DateTime(2026, 1, 1, 23)), '좋은 저녁입니다');
    expect(greetingFor(DateTime(2026, 1, 1, 2)), '좋은 저녁입니다');
  });
}
