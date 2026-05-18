// T079 — DateFormatter 분기 검증.

import 'package:closetimo_app/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final now = DateTime(2026, 5, 19, 12);

  test('오늘', () {
    expect(formatRelative(DateTime(2026, 5, 19, 9), now: now), '오늘');
  });

  test('어제', () {
    expect(formatRelative(DateTime(2026, 5, 18), now: now), '어제');
  });

  test('N일 전 (2~6일)', () {
    expect(formatRelative(DateTime(2026, 5, 17), now: now), '2일 전');
    expect(formatRelative(DateTime(2026, 5, 13), now: now), '6일 전');
  });

  test('M/d (7~30일)', () {
    expect(formatRelative(DateTime(2026, 5, 12), now: now), '5/12');
    expect(formatRelative(DateTime(2026, 4, 25), now: now), '4/25');
  });

  test('yyyy.MM.dd (30일 초과)', () {
    expect(formatRelative(DateTime(2026, 1, 1), now: now), '2026.01.01');
  });

  test('미래 시각은 M/d 폴백', () {
    expect(formatRelative(DateTime(2026, 5, 25), now: now), '5/25');
  });

  test('formatMonthDayOrDash — null 처리', () {
    expect(formatMonthDayOrDash(null), '—');
    expect(formatMonthDayOrDash(DateTime(2026, 10, 14)), '10/14');
  });
}
