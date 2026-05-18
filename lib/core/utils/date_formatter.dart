// research.md §9 날짜 포맷 규칙.
// • "오늘" / "어제" / "N일 전"  — 7일 이내
// • "M/d"                          — 8~30일
// • "yyyy.MM.dd"                   — 30일 초과 또는 정확 날짜 표기

import 'package:intl/intl.dart';

String formatRelative(DateTime when, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(when.year, when.month, when.day);
  final delta = today.difference(target).inDays;

  if (delta < 0) return formatMonthDay(when); // 미래 시각
  if (delta == 0) return '오늘';
  if (delta == 1) return '어제';
  if (delta < 7) return '$delta일 전';
  if (delta <= 30) return formatMonthDay(when);
  return formatFullDate(when);
}

final _monthDay = DateFormat('M/d');
final _fullDate = DateFormat('yyyy.MM.dd');

String formatMonthDay(DateTime when) => _monthDay.format(when);

String formatFullDate(DateTime when) => _fullDate.format(when);

/// "—" 폴백 처리. nullable DateTime을 표시할 때 사용한다.
String formatMonthDayOrDash(DateTime? when) =>
    when == null ? '—' : formatMonthDay(when);
