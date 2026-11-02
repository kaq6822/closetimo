// 005 — 사진 분석 채널 래퍼(MethodChannelNativeVision): Android·iOS 공통 응답 해석과
// 미지원 플랫폼에서 채널을 부르지 않는 규칙.

import 'dart:io';

import 'package:closetimo/core/vision/native_vision.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('closetimo/vision.test');
  final calls = <MethodCall>[];

  void mock(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('기능 확인·분석·설명 응답을 해석하고 허용 값 목록을 넘긴다', () async {
    mock((call) async {
      switch (call.method) {
        case 'capabilities':
          return {
            'backgroundRemoval': true,
            'classification': true,
            'onDeviceAi': 'notReady',
          };
        case 'analyze':
          return {
            'cutoutPath': '/tmp/c.png',
            'labels': [
              {'identifier': 'jeans', 'confidence': 0.9},
              {'identifier': 'bad'},
            ],
          };
        case 'describe':
          return {
            'category': 'bottom',
            'subType': 'jeans',
            'colors': ['denim'],
            'seasons': <String>[],
            'material': 'denim',
            'pattern': 'none',
          };
      }
      return null;
    });
    final vision = MethodChannelNativeVision(channel: channel, supported: true);

    final caps = await vision.capabilities();
    expect(caps.backgroundRemoval, isTrue);
    expect(caps.onDeviceAi, OnDeviceAiStatus.notReady);

    final analysis = await vision.analyze(
      File('/tmp/p.jpg'),
      removeBackground: true,
    );
    expect(analysis.cutout!.path, '/tmp/c.png');
    expect(analysis.labels.single.identifier, 'jeans');
    expect(calls.last.arguments, {
      'path': '/tmp/p.jpg',
      'removeBackground': true,
    });

    final d = await vision.describe(
      File('/tmp/p.jpg'),
      schema: const {
        'colors': ['denim'],
      },
    );
    expect(d.subType, 'jeans');
    expect(d.pattern, isNull, reason: "'none'은 값 없음");
    expect((calls.last.arguments as Map)['schema'], {
      'colors': ['denim'],
    });
  });

  test('채널이 미지원으로 답하면 UnsupportedError, 오류면 기능 없음', () async {
    mock((call) async {
      if (call.method == 'describe') {
        throw PlatformException(code: 'unsupported', message: 'no nano');
      }
      throw PlatformException(code: 'boom');
    });
    final vision = MethodChannelNativeVision(channel: channel, supported: true);
    await expectLater(
      vision.describe(File('/tmp/p.jpg')),
      throwsA(isA<UnsupportedError>()),
    );
    final caps = await vision.capabilities();
    expect(caps.classification, isFalse);
  });

  test('지원하지 않는 플랫폼은 채널을 부르지 않는다', () async {
    mock((call) async => fail('channel must not be called'));
    final vision = MethodChannelNativeVision(
      channel: channel,
      supported: false,
    );
    expect((await vision.capabilities()).backgroundRemoval, isFalse);
    expect(
      (await vision.analyze(File('/x'), removeBackground: true)).labels,
      isEmpty,
    );
    await vision.prewarm();
    await expectLater(
      vision.describe(File('/x')),
      throwsA(isA<UnsupportedError>()),
    );
    expect(calls, isEmpty);
  });
}
