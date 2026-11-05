// 005 FR-513~515·518 — 기기 내 사진 분석 채널(`closetimo/vision`) 래퍼.
//
// iOS: ios/Runner/ClosetimoVisionChannel.swift
// - 배경 제거: Vision `VNGenerateForegroundInstanceMaskRequest`(iOS 17+)
// - 분류 라벨: Vision `VNClassifyImageRequest`
// - 기기 내 AI: Foundation Models 이미지 입력(iOS 27+, Apple Intelligence). 서버 모델은 쓰지 않는다.
// Android: android/app/src/main/kotlin/com/closetimo/app/ClosetimoVisionChannel.kt
// - 배경 제거·분류 라벨: ML Kit Subject Segmentation·Image Labeling(Play 서비스)
// - 기기 내 AI: Gemini Nano Prompt API(AICore 지원 기기)
// 사진은 기기 밖으로 보내지 않는다. Android ML Kit은 기능 진단 정보를 Google에 보낸다
// (사용자 승인, 헌법 III 예외 2026-11-02). 그 밖의 플랫폼은 채널을 호출하지 않는다.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 기기 내 AI 상태. 설정 노출 여부를 정한다.
enum OnDeviceAiStatus {
  /// 사용 가능(iOS 27+, Apple Intelligence 켜짐, 모델 준비됨).
  available,

  /// Apple Intelligence가 꺼져 있다(사용자가 켜면 쓸 수 있음).
  notEnabled,

  /// 모델을 내려받는 중이다.
  notReady,

  /// 기기·OS·플랫폼이 지원하지 않는다.
  unsupported;

  static OnDeviceAiStatus parse(Object? raw) => switch (raw) {
    'available' => available,
    'notEnabled' => notEnabled,
    'notReady' => notReady,
    _ => unsupported,
  };
}

/// 이 기기에서 쓸 수 있는 분석 기능.
class VisionCapabilities {
  const VisionCapabilities({
    this.backgroundRemoval = false,
    this.classification = false,
    this.onDeviceAi = OnDeviceAiStatus.unsupported,
  });

  static const none = VisionCapabilities();

  final bool backgroundRemoval;
  final bool classification;
  final OnDeviceAiStatus onDeviceAi;
}

/// 분류 라벨 1개.
class VisionLabel {
  const VisionLabel(this.identifier, this.confidence);

  final String identifier;
  final double confidence;
}

/// 네이티브 분석 결과.
class NativeAnalysis {
  const NativeAnalysis({this.cutout, this.labels = const []});

  /// 배경 제거본(투명 PNG) 임시 파일. 피사체가 없거나 요청하지 않았으면 null.
  final File? cutout;
  final List<VisionLabel> labels;
}

/// 기기 내 AI가 돌려준 코드 값(카탈로그 코드로 제한된 구조화 응답). 검증 전 원본이다.
class OnDeviceDescription {
  const OnDeviceDescription({
    this.category,
    this.subType,
    this.colors = const [],
    this.seasons = const [],
    this.material,
    this.pattern,
  });

  factory OnDeviceDescription.fromMap(Map<Object?, Object?> map) {
    String? text(String key) {
      final v = map[key];
      return v is String && v.isNotEmpty && v != 'none' ? v : null;
    }

    List<String> list(String key) => [
      for (final v in (map[key] as List?) ?? const [])
        if (v is String && v.isNotEmpty && v != 'none') v,
    ];

    return OnDeviceDescription(
      category: text('category'),
      subType: text('subType'),
      colors: list('colors'),
      seasons: list('seasons'),
      material: text('material'),
      pattern: text('pattern'),
    );
  }

  final String? category;
  final String? subType;
  final List<String> colors;
  final List<String> seasons;
  final String? material;
  final String? pattern;
}

/// 사진 분석 채널. 테스트는 fake를 주입한다.
abstract interface class NativeVision {
  Future<VisionCapabilities> capabilities();

  /// [photo]를 분석한다. [removeBackground]가 false면 배경 제거를 건너뛴다.
  Future<NativeAnalysis> analyze(File photo, {required bool removeBackground});

  /// 기기 내 AI로 [photo]를 설명한다. 미지원이면 [UnsupportedError].
  /// [schema]는 축별 허용 코드 목록이다(Android가 지시문에 쓰고, iOS는 스키마가 내장돼 있다).
  Future<OnDeviceDescription> describe(
    File photo, {
    Map<String, List<String>> schema = const {},
  });

  /// 기기 내 AI 모델을 미리 깨운다(첫 호출 지연 완화). 미지원이면 아무것도 하지 않는다.
  Future<void> prewarm();
}

/// 실제 플랫폼 채널 구현.
class MethodChannelNativeVision implements NativeVision {
  MethodChannelNativeVision({MethodChannel? channel, bool? supported})
    : _channel = channel ?? const MethodChannel('closetimo/vision'),
      _supported =
          supported ?? (!kIsWeb && (Platform.isIOS || Platform.isAndroid));

  final MethodChannel _channel;

  /// 네이티브 채널이 있는 플랫폼(iOS·Android)인지.
  final bool _supported;
  VisionCapabilities? _cached;

  @override
  Future<VisionCapabilities> capabilities() async {
    if (!_supported) return VisionCapabilities.none;
    final cached = _cached;
    // 모델 준비 상태는 바뀔 수 있으므로 available이 아닐 때는 다시 묻는다.
    if (cached != null && cached.onDeviceAi == OnDeviceAiStatus.available) {
      return cached;
    }
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'capabilities',
      );
      final result = VisionCapabilities(
        backgroundRemoval: raw?['backgroundRemoval'] == true,
        classification: raw?['classification'] == true,
        onDeviceAi: OnDeviceAiStatus.parse(raw?['onDeviceAi']),
      );
      return _cached = result;
    } on PlatformException catch (e) {
      debugPrint('Vision capabilities failed: ${e.code} ${e.message}');
      return VisionCapabilities.none;
    } on MissingPluginException {
      return VisionCapabilities.none;
    }
  }

  @override
  Future<NativeAnalysis> analyze(
    File photo, {
    required bool removeBackground,
  }) async {
    if (!_supported) return const NativeAnalysis();
    final raw = await _channel.invokeMapMethod<String, Object?>('analyze', {
      'path': photo.path,
      'removeBackground': removeBackground,
    });
    final cutoutPath = raw?['cutoutPath'];
    return NativeAnalysis(
      cutout: cutoutPath is String ? File(cutoutPath) : null,
      labels: [
        for (final l in (raw?['labels'] as List?) ?? const [])
          if (l is Map && l['identifier'] is String && l['confidence'] is num)
            VisionLabel(
              l['identifier'] as String,
              (l['confidence'] as num).toDouble(),
            ),
      ],
    );
  }

  @override
  Future<void> prewarm() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('prewarm');
    } on PlatformException catch (e) {
      debugPrint('Vision prewarm failed: ${e.code}');
    } on MissingPluginException {
      // 채널이 없는 환경(테스트 등)은 무시한다.
    }
  }

  @override
  Future<OnDeviceDescription> describe(
    File photo, {
    Map<String, List<String>> schema = const {},
  }) async {
    if (!_supported) {
      throw UnsupportedError('On-device AI is not available on this platform');
    }
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>('describe', {
        'path': photo.path,
        'schema': schema,
      });
      return OnDeviceDescription.fromMap(raw ?? const {});
    } on PlatformException catch (e) {
      if (e.code == 'unsupported') {
        throw UnsupportedError('On-device AI unavailable: ${e.message}');
      }
      rethrow;
    }
  }
}
