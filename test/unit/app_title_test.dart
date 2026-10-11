// 앱 이름 로케일 규칙(한국어 "옷장이모", 그 외 "Closetimo")을 검증한다.

import 'dart:ui';

import 'package:closetimo/app/app_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('한국어 로케일은 옷장이모', () {
    expect(appTitleFor(const Locale('ko')), '옷장이모');
    expect(appTitleFor(const Locale('ko', 'KR')), '옷장이모');
  });

  test('그 외 로케일은 Closetimo', () {
    expect(appTitleFor(const Locale('en', 'US')), 'Closetimo');
    expect(appTitleFor(const Locale('ja', 'JP')), 'Closetimo');
    expect(appTitleFor(const Locale('und')), 'Closetimo');
  });
}
