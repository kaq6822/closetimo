// design.md §3 타이포그래피 시스템을 Flutter TextTheme으로 매핑.
// Manrope(라틴 표제·본문) + Inter(라벨/메타) + Pretendard(한글 폴백).
// 실제 .ttf/.otf 파일은 assets/fonts/README.md 가이드에 따라 다운로드되며,
// 파일 부재 시 시스템 폰트로 자동 폴백된다.

import 'package:flutter/material.dart';

import 'tokens.dart';

/// 폰트 family 상수.
abstract final class ClosetimoFonts {
  static const manrope = 'Manrope';
  static const inter = 'Inter';
  static const pretendard = 'Pretendard';

  /// 모든 텍스트의 한글 폴백 체인.
  static const fallback = <String>[pretendard, manrope, inter];
}

/// design.md의 타이포 스케일을 Material 3 TextTheme 슬롯에 매핑.
/// 매핑 규칙:
///   • displayLarge   ← Manrope display-lg (56px / -2% letter-spacing)
///   • displayMedium  ← Manrope display-md (40)
///   • displaySmall   ← Manrope display-sm (32)
///   • headlineSmall  ← Manrope headline-sm (24)
///   • titleLarge     ← Manrope 18 (h2)
///   • bodyLarge      ← Manrope body-lg (16)
///   • bodyMedium     ← Manrope 14
///   • labelMedium    ← Inter label-md (12) — 메타데이터
///   • labelSmall     ← Inter 10 (라벨 라인)
const TextTheme closetimoTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 56,
    height: 1.05,
    letterSpacing: -1.12, // -2%
    fontWeight: FontWeight.w700,
    color: ClosetimoColors.ink,
  ),
  displayMedium: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 40,
    height: 1.1,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w700,
    color: ClosetimoColors.ink,
  ),
  displaySmall: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 32,
    height: 1.15,
    letterSpacing: -0.64,
    fontWeight: FontWeight.w700,
    color: ClosetimoColors.ink,
  ),
  headlineSmall: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: ClosetimoColors.ink,
  ),
  titleLarge: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: ClosetimoColors.ink,
  ),
  bodyLarge: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: ClosetimoColors.ink,
  ),
  bodyMedium: TextStyle(
    fontFamily: ClosetimoFonts.manrope,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: ClosetimoColors.ink,
  ),
  labelMedium: TextStyle(
    fontFamily: ClosetimoFonts.inter,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: ClosetimoColors.muted,
  ),
  labelSmall: TextStyle(
    fontFamily: ClosetimoFonts.inter,
    fontFamilyFallback: ClosetimoFonts.fallback,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
    color: ClosetimoColors.muted,
  ),
);
