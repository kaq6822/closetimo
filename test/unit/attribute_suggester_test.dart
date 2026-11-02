// 005 FR-503·504·513~515 — 제안기 단계 결합·실패 내성·AI 응답 검증.

import 'dart:io';

import 'package:closetimo/core/vision/color_extractor.dart';
import 'package:closetimo/core/vision/native_vision.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/suggestions/attribute_suggester.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVision implements NativeVision {
  _FakeVision({
    this.caps = VisionCapabilities.none,
    this.analysis = const NativeAnalysis(),
    this.description,
    this.analyzeError,
    this.describeDelay = Duration.zero,
  });

  final VisionCapabilities caps;
  final NativeAnalysis analysis;
  final OnDeviceDescription? description;
  final Object? analyzeError;
  final Duration describeDelay;
  bool? lastRemoveBackground;
  File? describedFile;

  @override
  Future<VisionCapabilities> capabilities() async => caps;

  @override
  Future<NativeAnalysis> analyze(
    File photo, {
    required bool removeBackground,
  }) async {
    lastRemoveBackground = removeBackground;
    if (analyzeError != null) throw analyzeError!;
    return analysis;
  }

  int prewarmCalls = 0;

  @override
  Future<void> prewarm() async => prewarmCalls++;

  @override
  Future<OnDeviceDescription> describe(
    File photo, {
    Map<String, List<String>> schema = const {},
  }) async {
    describedFile = photo;
    await Future<void>.delayed(describeDelay);
    return description ?? (throw UnsupportedError('no'));
  }
}

class _FakeColors implements ColorExtractor {
  _FakeColors(this.result, {this.fail = false});

  final List<String> result;
  final bool fail;
  Uint8List? lastBytes;

  @override
  Future<List<String>> extract(
    Uint8List bytes,
    Map<String, int> palette,
  ) async {
    if (fail) throw StateError('decode failed');
    lastBytes = bytes;
    return result;
  }
}

void main() {
  late Directory tmp;
  late File photo;
  late File cutout;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('closetimo_suggest');
    photo = File('${tmp.path}/p.jpg')..writeAsBytesSync([1, 1, 1]);
    cutout = File('${tmp.path}/c.png')..writeAsBytesSync([2, 2, 2]);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  const iosCaps = VisionCapabilities(
    backgroundRemoval: true,
    classification: true,
    onDeviceAi: OnDeviceAiStatus.available,
  );

  test('Android(미지원)는 원본 사진 색상만 제안한다', () async {
    final colors = _FakeColors(['black']);
    final vision = _FakeVision();
    final result = await AttributeSuggester(
      vision: vision,
      colorExtractor: colors,
    ).analyzePhoto(photo, removeBackground: true, useOnDeviceAi: true);
    expect(result.cutout, isNull);
    expect(result.suggestion.colors, ['black']);
    expect(result.suggestion.category, isNull);
    expect(vision.lastRemoveBackground, isNull, reason: '채널을 부르지 않는다');
    expect(colors.lastBytes, [1, 1, 1]);
  });

  test('iOS: 배경 제거본으로 색을 뽑고 신뢰도 높은 라벨로 종류를 제안한다', () async {
    final colors = _FakeColors(['white', 'red']);
    final vision = _FakeVision(
      caps: iosCaps,
      analysis: NativeAnalysis(
        cutout: cutout,
        labels: const [
          VisionLabel('clothing', 0.95),
          VisionLabel('shoes', 0.9),
          VisionLabel('sneaker', 0.9),
          VisionLabel('jeans', 0.4),
        ],
      ),
    );
    final result = await AttributeSuggester(
      vision: vision,
      colorExtractor: colors,
    ).analyzePhoto(photo, removeBackground: true, useOnDeviceAi: false);
    expect(vision.lastRemoveBackground, isTrue);
    expect(result.cutout!.path, cutout.path);
    expect(colors.lastBytes, [2, 2, 2], reason: '배경 제거본에서 추출');
    expect(result.suggestion.category, Category.shoes);
    expect(result.suggestion.subType, 'sneakers');
    expect(result.usedOnDeviceAi, isFalse);
  });

  test('설정에서 배경 제거를 끄면 요청하지 않는다', () async {
    final vision = _FakeVision(caps: iosCaps);
    await AttributeSuggester(
      vision: vision,
      colorExtractor: _FakeColors(const []),
    ).analyzePhoto(photo, removeBackground: false, useOnDeviceAi: false);
    expect(vision.lastRemoveBackground, isFalse);
  });

  test('네이티브·색상 단계가 실패해도 예외 없이 빈 제안(SC-504)', () async {
    final result = await AttributeSuggester(
      vision: _FakeVision(
        caps: iosCaps,
        analyzeError: PlatformException(code: 'vision'),
      ),
      colorExtractor: _FakeColors(const [], fail: true),
    ).analyzePhoto(photo, removeBackground: true, useOnDeviceAi: false);
    expect(result.cutout, isNull);
    expect(result.suggestion.isEmpty, isTrue);
  });

  test('기기 내 AI 응답을 우선하고 빈 축은 앞 단계로 채운다', () async {
    final vision = _FakeVision(
      caps: iosCaps,
      analysis: NativeAnalysis(cutout: cutout),
      description: const OnDeviceDescription(
        category: 'top',
        subType: 'knit',
        colors: ['ivory', 'neon'],
        seasons: ['winter', 'autumn', 'monsoon'],
        material: 'wool',
        pattern: 'none',
      ),
    );
    final result = await AttributeSuggester(
      vision: vision,
      colorExtractor: _FakeColors(['beige']),
    ).analyzePhoto(photo, removeBackground: true, useOnDeviceAi: true);
    expect(vision.describedFile!.path, cutout.path);
    expect(result.usedOnDeviceAi, isTrue);
    final s = result.suggestion;
    expect(s.category, Category.top);
    expect(s.subType, 'knit');
    expect(s.colors, ['ivory']);
    expect(s.seasons, [Season.autumn, Season.winter]);
    expect(s.material, 'wool');
    expect(s.pattern, isNull);
  });

  test('설정이 꺼져 있거나 AI가 준비되지 않으면 부르지 않는다', () async {
    final off = _FakeVision(
      caps: iosCaps,
      description: const OnDeviceDescription(category: 'top'),
    );
    await AttributeSuggester(
      vision: off,
      colorExtractor: _FakeColors(const []),
    ).analyzePhoto(photo, removeBackground: true, useOnDeviceAi: false);
    expect(off.describedFile, isNull);

    final notReady = _FakeVision(
      caps: const VisionCapabilities(
        classification: true,
        onDeviceAi: OnDeviceAiStatus.notReady,
      ),
      description: const OnDeviceDescription(category: 'top'),
    );
    await AttributeSuggester(
      vision: notReady,
      colorExtractor: _FakeColors(const []),
    ).analyzePhoto(photo, removeBackground: true, useOnDeviceAi: true);
    expect(notReady.describedFile, isNull);
  });

  test('AI가 시간 안에 답하지 않으면 버리고 기존 제안을 쓴다', () async {
    final result = await AttributeSuggester(
      vision: _FakeVision(
        caps: iosCaps,
        description: const OnDeviceDescription(category: 'outer'),
        describeDelay: const Duration(milliseconds: 200),
      ),
      colorExtractor: _FakeColors(['navy']),
      aiTimeout: const Duration(milliseconds: 20),
    ).analyzePhoto(photo, removeBackground: false, useOnDeviceAi: true);
    expect(result.usedOnDeviceAi, isFalse);
    expect(result.suggestion.category, isNull);
    expect(result.suggestion.colors, ['navy']);
  });

  test('prewarm은 설정이 켜져 있고 AI가 사용 가능할 때만 부른다', () async {
    final ready = _FakeVision(caps: iosCaps);
    final suggester = AttributeSuggester(vision: ready);
    await suggester.prewarm(useOnDeviceAi: false);
    expect(ready.prewarmCalls, 0);
    await suggester.prewarm(useOnDeviceAi: true);
    expect(ready.prewarmCalls, 1);

    final android = _FakeVision();
    await AttributeSuggester(vision: android).prewarm(useOnDeviceAi: true);
    expect(android.prewarmCalls, 0);
  });

  group('AI 응답 검증', () {
    test('종류가 틀려도 세부 종류가 맞으면 세부 종류의 종류를 쓴다', () {
      final s = AttributeSuggester.fromDescription(
        const OnDeviceDescription(category: 'shoes', subType: 'jeans'),
      );
      expect(s.category, Category.shoes);
      expect(s.subType, isNull);

      final t = AttributeSuggester.fromDescription(
        const OnDeviceDescription(subType: 'padding'),
      );
      expect(t.category, Category.outer);
      expect(t.subType, 'padding');
    });

    test('미분류·알 수 없는 종류는 버린다', () {
      expect(
        AttributeSuggester.fromDescription(
          const OnDeviceDescription(category: 'uncategorized'),
        ).category,
        isNull,
      );
      expect(
        AttributeSuggester.fromDescription(
          const OnDeviceDescription(category: 'spaceship'),
        ).isEmpty,
        isTrue,
      );
    });

    test('채널 응답 맵에서 none·빈 값은 없음으로 읽는다', () {
      final d = OnDeviceDescription.fromMap({
        'category': 'top',
        'subType': 'none',
        'colors': ['black', '', 3],
        'material': '',
      });
      expect(d.category, 'top');
      expect(d.subType, isNull);
      expect(d.colors, ['black']);
      expect(d.material, isNull);
    });
  });

  test('이름 제안과 결합할 때 이름이 우선한다', () {
    final fromName = AttributeSuggestion.fromName('네이비 울 코트');
    final merged = fromName.orElse(
      const AttributeSuggestion(
        category: Category.top,
        subType: 'knit',
        colors: ['black'],
        pattern: 'stripe',
      ),
    );
    expect(merged.category, Category.outer);
    expect(merged.subType, 'coat');
    expect(merged.colors, ['navy']);
    expect(merged.pattern, 'stripe');
  });
}
