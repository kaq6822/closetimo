// 005 — iOS 기기 내 AI 응답 스키마(Swift)와 Dart 카탈로그 코드가 같은지 지킨다.
// 카탈로그에 코드를 추가하면 ios/Runner/ClosetimoVisionChannel.swift도 함께 고쳐야 한다.

import 'dart:io';

import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/item_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

final _swift = File(
  'ios/Runner/ClosetimoVisionChannel.swift',
).readAsStringSync();

/// `@Guide(description: "<description 시작>…", .anyOf([...]))`의 문자열 목록.
Set<String> _anyOf(String descriptionStart) {
  final at = _swift.indexOf(
    RegExp('description:\\s*"${RegExp.escape(descriptionStart)}'),
  );
  expect(at, isNonNegative, reason: descriptionStart);
  final open = _swift.indexOf('.anyOf([', at);
  final close = _swift.indexOf('])', open);
  return RegExp(
    r'"([a-z_]+)"',
  ).allMatches(_swift.substring(open, close)).map((m) => m.group(1)!).toSet();
}

/// `enum <name> { case a, b, … }`의 case 목록.
Set<String> _enumCases(String name) {
  final at = _swift.indexOf('enum $name {');
  expect(at, isNonNegative, reason: name);
  final body = _swift.substring(at, _swift.indexOf('}', at));
  return RegExp(r'\b([a-z]+)\b')
      .allMatches(body.substring(body.indexOf('case') + 4))
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  test('세부 종류', () {
    expect(_anyOf('Specific garment type'), {
      ...ItemAttributes.subTypes.map((s) => s.code),
      'none',
    });
  });

  test('종류(미분류·legacy 운동복 제외)', () {
    expect(_anyOf('Main category'), {
      for (final c in Category.selectable)
        if (c != Category.uncategorized) c.name,
    });
  });

  test('색상', () {
    expect(
      _enumCases('GarmentColor'),
      ItemAttributes.colors.map((c) => c.code).toSet(),
    );
  });

  test('계절', () {
    expect(
      _enumCases('GarmentSeason'),
      Season.values.map((s) => s.name).toSet(),
    );
  });

  test('소재·패턴', () {
    expect(_anyOf('Main material'), {
      ...ItemAttributes.materials.map((m) => m.code),
      'none',
    });
    expect(_anyOf('Surface pattern'), {
      ...ItemAttributes.patterns.map((p) => p.code),
      'none',
    });
  });

  test('분류 라벨 매핑 대상은 Dart가 판정한다(Swift는 라벨만 넘긴다)', () {
    expect(_swift.contains('VNClassifyImageRequest'), isTrue);
    expect(visionLabelHints, isNotEmpty);
  });
}
