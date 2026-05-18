// ColorScheme + ThemeExtension 구성. design.md 토큰의 단일 진실 원천.
// ColorScheme.fromSeed를 사용하지 않는다(research.md §4) — Material 3
// 알고리즘이 "The Digital Atelier" 팔레트를 임의로 변경하기 때문이다.

import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// design.md의 surface-container-* 토큰을 ColorScheme의 슬롯 밖에서
/// 노출하기 위한 ThemeExtension.
@immutable
class ClosetimoSurfaces extends ThemeExtension<ClosetimoSurfaces> {
  const ClosetimoSurfaces({
    required this.containerLowest,
    required this.containerLow,
    required this.container,
    required this.containerHigh,
    required this.containerHighest,
    required this.bgMint,
    required this.bgMintSoft,
    required this.bgChip,
    required this.inkSoft,
    required this.tertiarySoft,
  });

  final Color containerLowest;
  final Color containerLow;
  final Color container;
  final Color containerHigh;
  final Color containerHighest;
  final Color bgMint;
  final Color bgMintSoft;
  final Color bgChip;
  final Color inkSoft;
  final Color tertiarySoft;

  static const light = ClosetimoSurfaces(
    containerLowest: ClosetimoColors.surfaceContainerLowest,
    containerLow: ClosetimoColors.surfaceContainerLow,
    container: ClosetimoColors.surfaceContainer,
    containerHigh: ClosetimoColors.surfaceContainerHigh,
    containerHighest: ClosetimoColors.surfaceContainerHighest,
    bgMint: ClosetimoColors.bgMint,
    bgMintSoft: ClosetimoColors.bgMintSoft,
    bgChip: ClosetimoColors.bgChip,
    inkSoft: ClosetimoColors.inkSoft,
    tertiarySoft: ClosetimoColors.tertiarySoft,
  );

  @override
  ClosetimoSurfaces copyWith({
    Color? containerLowest,
    Color? containerLow,
    Color? container,
    Color? containerHigh,
    Color? containerHighest,
    Color? bgMint,
    Color? bgMintSoft,
    Color? bgChip,
    Color? inkSoft,
    Color? tertiarySoft,
  }) {
    return ClosetimoSurfaces(
      containerLowest: containerLowest ?? this.containerLowest,
      containerLow: containerLow ?? this.containerLow,
      container: container ?? this.container,
      containerHigh: containerHigh ?? this.containerHigh,
      containerHighest: containerHighest ?? this.containerHighest,
      bgMint: bgMint ?? this.bgMint,
      bgMintSoft: bgMintSoft ?? this.bgMintSoft,
      bgChip: bgChip ?? this.bgChip,
      inkSoft: inkSoft ?? this.inkSoft,
      tertiarySoft: tertiarySoft ?? this.tertiarySoft,
    );
  }

  @override
  ClosetimoSurfaces lerp(ThemeExtension<ClosetimoSurfaces>? other, double t) {
    if (other is! ClosetimoSurfaces) return this;
    return ClosetimoSurfaces(
      containerLowest:
          Color.lerp(containerLowest, other.containerLowest, t) ?? containerLowest,
      containerLow:
          Color.lerp(containerLow, other.containerLow, t) ?? containerLow,
      container: Color.lerp(container, other.container, t) ?? container,
      containerHigh:
          Color.lerp(containerHigh, other.containerHigh, t) ?? containerHigh,
      containerHighest:
          Color.lerp(containerHighest, other.containerHighest, t) ??
              containerHighest,
      bgMint: Color.lerp(bgMint, other.bgMint, t) ?? bgMint,
      bgMintSoft: Color.lerp(bgMintSoft, other.bgMintSoft, t) ?? bgMintSoft,
      bgChip: Color.lerp(bgChip, other.bgChip, t) ?? bgChip,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t) ?? inkSoft,
      tertiarySoft:
          Color.lerp(tertiarySoft, other.tertiarySoft, t) ?? tertiarySoft,
    );
  }
}

ThemeData buildClosetimoTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ClosetimoColors.primary,
    onPrimary: ClosetimoColors.onPrimary,
    primaryContainer: ClosetimoColors.primarySoft,
    onPrimaryContainer: ClosetimoColors.primary,
    secondary: ClosetimoColors.secondary,
    onSecondary: ClosetimoColors.onPrimary,
    secondaryContainer: ClosetimoColors.secondaryContainer,
    onSecondaryContainer: ClosetimoColors.ink,
    tertiary: ClosetimoColors.tertiary,
    onTertiary: ClosetimoColors.onPrimary,
    tertiaryContainer: ClosetimoColors.bgMint,
    onTertiaryContainer: ClosetimoColors.tertiary,
    error: ClosetimoColors.error,
    onError: ClosetimoColors.onError,
    errorContainer: Color(0xFFF5D9D8),
    onErrorContainer: ClosetimoColors.error,
    surface: ClosetimoColors.surface,
    onSurface: ClosetimoColors.ink,
    onSurfaceVariant: ClosetimoColors.inkSoft,
    outline: Color(0x40AEB4AA),
    outlineVariant: ClosetimoColors.outlineVariantGhost,
    shadow: Colors.black,
    scrim: Color(0x99000000),
    inverseSurface: ClosetimoColors.ink,
    onInverseSurface: ClosetimoColors.surface,
    inversePrimary: ClosetimoColors.bgMint,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ClosetimoColors.surface,
    textTheme: closetimoTextTheme,
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    extensions: const [ClosetimoSurfaces.light],
    // design.md "No-Line" — 모든 Material Divider를 투명 처리.
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      space: 0,
      thickness: 0,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
