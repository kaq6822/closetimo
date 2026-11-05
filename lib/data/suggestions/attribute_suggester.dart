// 005 FR-503·504·513~515 — 사진·이름에서 속성 제안을 만든다. 저장하지 않는다.
//
// 순서: (iOS) 배경 제거 + 분류 라벨 → 대표 색상 추출(배경 제거본 우선) →
// (선택) 기기 내 AI. 각 단계는 실패해도 다음 단계로 넘어가며 등록을 막지 않는다(SC-504).

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;

import '../../core/vision/color_extractor.dart';
import '../../core/vision/native_vision.dart';
import '../models/item.dart';
import '../models/item_attributes.dart';

/// 기기 내 AI 응답을 기다리는 최대 시간(FR-515).
/// 맥 실측(텍스트 입력)에서 웜 상태 1.3~10.7초, 첫 호출 15.4초였다. 화면 진입 시 prewarm한다.
const Duration onDeviceAiTimeout = Duration(seconds: 20);

/// 축별 제안 값. 비어 있는 축은 null·빈 목록이다.
@immutable
class AttributeSuggestion {
  const AttributeSuggestion({
    this.category,
    this.subType,
    this.colors = const [],
    this.seasons = const [],
    this.material,
    this.pattern,
  });

  /// 이름 추론 결과를 제안으로 바꾼다(FR-503).
  factory AttributeSuggestion.fromName(String name) {
    final hints = inferFromName(name);
    return AttributeSuggestion(
      category: hints.category,
      subType: hints.subType,
      colors: hints.colors,
      material: hints.material,
      pattern: hints.pattern,
    );
  }

  final Category? category;
  final String? subType;
  final List<String> colors;
  final List<Season> seasons;
  final String? material;
  final String? pattern;

  static const empty = AttributeSuggestion();

  bool get isEmpty =>
      category == null &&
      subType == null &&
      colors.isEmpty &&
      seasons.isEmpty &&
      material == null &&
      pattern == null;

  /// 이 제안을 우선하고 비어 있는 축만 [other]로 채운다. 세부 종류는 최종 종류에
  /// 맞을 때만 남긴다.
  AttributeSuggestion orElse(AttributeSuggestion other) {
    final category = this.category ?? other.category;
    String? sub(String? code) => category == null
        ? code
        : ItemAttributes.normalizeSubType(category, code);
    return AttributeSuggestion(
      category: category,
      subType: sub(subType) ?? sub(other.subType),
      colors: colors.isNotEmpty ? colors : other.colors,
      seasons: seasons.isNotEmpty ? seasons : other.seasons,
      material: material ?? other.material,
      pattern: pattern ?? other.pattern,
    );
  }
}

/// 사진 1장의 분석 결과.
class PhotoAnalysis {
  const PhotoAnalysis({
    this.cutout,
    this.suggestion = AttributeSuggestion.empty,
    this.usedOnDeviceAi = false,
  });

  /// 배경 제거본 임시 파일(iOS 17+, 설정 켜짐). 없으면 null.
  final File? cutout;
  final AttributeSuggestion suggestion;

  /// 기기 내 AI 응답을 실제로 반영했는지(진행 안내·테스트용).
  final bool usedOnDeviceAi;
}

class AttributeSuggester {
  AttributeSuggester({
    required NativeVision vision,
    ColorExtractor colorExtractor = const ColorExtractor(),
    Duration aiTimeout = onDeviceAiTimeout,
  }) : _vision = vision,
       _colors = colorExtractor,
       _aiTimeout = aiTimeout;

  final NativeVision _vision;
  final ColorExtractor _colors;
  final Duration _aiTimeout;

  /// 색상 추출 팔레트(카탈로그 코드 → ARGB).
  static final Map<String, int> palette = {
    for (final c in ItemAttributes.colors) c.code: c.argb,
  };

  Future<VisionCapabilities> capabilities() => _vision.capabilities();

  /// 기기 내 AI를 쓸 예정이면 모델을 미리 깨운다(FR-515 지연 완화). 모델이 준비 중이면
  /// 내려받기를 시작한다(Android Gemini Nano).
  Future<void> prewarm({required bool useOnDeviceAi}) async {
    if (!useOnDeviceAi) return;
    final caps = await _safe(_vision.capabilities, VisionCapabilities.none);
    if (caps.onDeviceAi == OnDeviceAiStatus.available ||
        caps.onDeviceAi == OnDeviceAiStatus.notReady) {
      await _safe(_vision.prewarm, null, label: 'On-device AI prewarm');
    }
  }

  /// 기기 내 AI 응답의 축별 허용 코드(Android 지시문용). 카탈로그가 단일 진실 원천이다.
  static final Map<String, List<String>> describeSchema = {
    'category': [
      for (final c in Category.selectable)
        if (c != Category.uncategorized) c.name,
    ],
    'subType': [for (final s in ItemAttributes.subTypes) s.code],
    'colors': [for (final c in ItemAttributes.colors) c.code],
    'seasons': [for (final s in Season.values) s.name],
    'material': [for (final m in ItemAttributes.materials) m.code],
    'pattern': [for (final p in ItemAttributes.patterns) p.code],
  };

  /// [photo]를 분석한다. 실패한 단계는 건너뛰고 얻은 제안만 돌려준다.
  Future<PhotoAnalysis> analyzePhoto(
    File photo, {
    required bool removeBackground,
    required bool useOnDeviceAi,
  }) async {
    final caps = await _safe(_vision.capabilities, VisionCapabilities.none);

    // 1) 배경 제거 + 분류 라벨(iOS).
    var native = const NativeAnalysis();
    if (caps.classification || caps.backgroundRemoval) {
      native = await _safe(
        () => _vision.analyze(
          photo,
          removeBackground: removeBackground && caps.backgroundRemoval,
        ),
        const NativeAnalysis(),
        label: 'Vision analyze',
      );
    }
    final cutout = native.cutout != null && native.cutout!.existsSync()
        ? native.cutout
        : null;
    final source = cutout ?? photo;

    // 2) 대표 색상(배경 제거본이 있으면 그것으로).
    final colors = await _safe(
      () async => _colors.extract(await source.readAsBytes(), palette),
      const <String>[],
      label: 'Color extraction',
    );
    var suggestion = AttributeSuggestion(
      colors: colors,
    ).orElse(_fromLabels(native.labels));

    // 3) 기기 내 AI(선택). 응답이 있으면 우선하되 비어 있는 축은 앞 단계로 채운다.
    var usedAi = false;
    if (useOnDeviceAi && caps.onDeviceAi == OnDeviceAiStatus.available) {
      final ai = await _safe<OnDeviceDescription?>(
        () => _vision
            .describe(source, schema: describeSchema)
            .timeout(_aiTimeout),
        null,
        label: 'On-device AI',
      );
      if (ai != null) {
        final fromAi = fromDescription(ai);
        usedAi = !fromAi.isEmpty;
        suggestion = fromAi.orElse(suggestion);
      }
    }
    return PhotoAnalysis(
      cutout: cutout,
      suggestion: suggestion,
      usedOnDeviceAi: usedAi,
    );
  }

  /// 분류 라벨에서 종류·세부 종류 힌트를 고른다(FR-514). 신뢰도가 가장 높은 매핑 라벨을 쓴다.
  static AttributeSuggestion _fromLabels(List<VisionLabel> labels) {
    VisionLabel? best;
    for (final l in labels) {
      if (l.confidence < visionHintMinConfidence) continue;
      if (!visionLabelHints.containsKey(l.identifier)) continue;
      // 세부 종류가 있는 라벨을 같은 신뢰도의 일반 라벨(shoes 등)보다 우선한다.
      final better =
          best == null ||
          l.confidence > best.confidence ||
          (l.confidence == best.confidence &&
              visionLabelHints[l.identifier]!.$2 != null &&
              visionLabelHints[best.identifier]!.$2 == null);
      if (better) best = l;
    }
    // 소재 라벨(Android ML Kit: denim·wool·leather·cotton)은 종류와 따로 고른다.
    VisionLabel? material;
    for (final l in labels) {
      if (l.confidence < visionHintMinConfidence) continue;
      if (!visionMaterialHints.containsKey(l.identifier)) continue;
      if (material == null || l.confidence > material.confidence) material = l;
    }
    final materialCode = material == null
        ? null
        : visionMaterialHints[material.identifier];
    if (best == null) return AttributeSuggestion(material: materialCode);
    final (category, subType) = visionLabelHints[best.identifier]!;
    return AttributeSuggestion(
      category: category,
      subType: subType,
      material: materialCode,
    );
  }

  /// 기기 내 AI가 자주 헷갈리는 종류 쌍. 충돌하면 세부 종류를 따른다.
  static const _topOuter = {Category.top, Category.outer};

  /// 기기 내 AI 응답을 카탈로그로 검증한다. 알 수 없는 값은 버린다.
  @visibleForTesting
  static AttributeSuggestion fromDescription(OnDeviceDescription d) {
    Category? category;
    for (final c in Category.selectable) {
      if (c.name == d.category && c != Category.uncategorized) category = c;
    }
    // 종류가 없으면 세부 종류의 종류를 쓴다. 상의·아우터는 모델이 자주 헷갈리므로(카디건을 상의로 답함,
    // T019 실측) 둘 사이 충돌은 더 구체적인 세부 종류를 따른다. 그 밖의 충돌은 종류를 믿고 세부 종류를 버린다.
    final subDef = ItemAttributes.subType(d.subType);
    if (subDef != null &&
        (category == null ||
            category == subDef.category ||
            _topOuter.containsAll({category, subDef.category}))) {
      category = subDef.category;
    }
    return AttributeSuggestion(
      category: category,
      subType: category == null
          ? null
          : ItemAttributes.normalizeSubType(category, d.subType),
      colors: ItemAttributes.normalizeColors(d.colors),
      seasons: ItemAttributes.normalizeSeasons([
        for (final name in d.seasons)
          for (final s in Season.values)
            if (s.name == name) s,
      ]),
      material: ItemAttributes.normalizeMaterial(d.material),
      pattern: ItemAttributes.normalizePattern(d.pattern),
    );
  }

  static Future<T> _safe<T>(
    Future<T> Function() run,
    T fallback, {
    String? label,
  }) async {
    try {
      return await run();
    } catch (e) {
      if (label != null) debugPrint('$label failed: $e');
      return fallback;
    }
  }
}
