// 홈 인사말 — 시각(시)에 따라 아침/오후/저녁 문구를 고른다(#18).
// 시간은 호출 측에서 `Clock`으로 주입받은 값을 넘긴다.

/// [now]의 시각에 맞는 인사말. 05~11시 아침, 12~17시 오후, 그 외 저녁.
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return '좋은 아침입니다';
  if (h >= 12 && h < 18) return '좋은 오후입니다';
  return '좋은 저녁입니다';
}
