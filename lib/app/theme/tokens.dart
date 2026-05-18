// design.md "The Digital Atelier"의 토큰을 Dart 상수로 미러링한다.
// 헌법 II(디자인 시스템 일관성)에 의해 본 파일 외에서 헥스 컬러/원시 간격
// 리터럴을 사용하는 것은 금지된다.

import 'package:flutter/painting.dart';

/// 색상 토큰. design.md §2 "신선함의 팔레트" + §4 "톤 레이어링" 매핑.
abstract final class ClosetimoColors {
  // ── Sage primary 라인 ──
  static const primary = Color(0xFF47645E); // 세이지 액센트
  static const primaryDim = Color(0xFF3C5852); // 그라디언트 endpoint
  static const onPrimary = Color(0xFFDFFEF7);
  static const primarySoft = Color(0x1A47645E); // 10% opacity

  // ── 표면 (surface) 톤 레이어 ──
  static const surface = Color(0xFFFAFAF5); // background
  static const surfaceBright = Color(0xFFFAFAF5);
  static const surfaceContainerLow = Color(0xFFF3F4EE);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFECEFE7);
  static const surfaceContainerHigh = Color(0xFFE3E7DD);
  static const surfaceContainerHighest = Color(0xFFDADFD3);

  // ── 보조 (secondary) ──
  static const secondary = Color(0xFF5E5F5F);
  static const secondaryContainer = Color(0xFFE3E2E2);

  // ── Tertiary (freshness/clean tips) ──
  static const tertiary = Color(0xFF576342);
  static const tertiarySoft = Color(0x1A576342); // 10% opacity
  static const bgMint = Color(0xFFCAE9E2);
  static const bgMintSoft = Color(0xFFE5F4C9);

  // ── 텍스트 (ink) ──
  static const ink = Color(0xFF2E342D); // on-background
  static const inkSoft = Color(0xFF5B6159); // on-surface-variant
  static const muted = Color(0xFF5B6159);

  // ── Error / 파괴적 액션 ──
  static const error = Color(0xFF9F403D);
  static const onError = Color(0xFFFFFFFF);

  // ── 보더 폴백 (고대비 모드용) ──
  /// design.md §4 "고스트 보더 폴백": outline-variant 15% opacity.
  static const outlineVariantGhost = Color(0x26AEB4AA);

  // ── 알약 / 칩 배경 ──
  static const bgChip = Color(0xFFE3E2E2);
}

/// 간격(spacing) 토큰. design.md §7 — 1.4rem 베이스라인(=22.4px ≈ 4 grid).
/// scale 1 = 4px, 단위는 모두 logical px.
abstract final class ClosetimoSpacing {
  static const double xs = 4; // scale 1
  static const double sm = 8; // scale 2
  static const double md = 16; // scale 3 (카드 내부 패딩 표준)
  static const double lg = 22.4; // scale 4 (베이스라인 1.4rem)
  static const double xl = 24; // 리스트 아이템 간 수직 간격
  static const double xxl = 32; // 섹션 간 수직 간격
  static const double huge = 44; // scale 8 (≈2.75rem 주요 섹션 호흡)
}

/// 라운딩(corner radius) 토큰. design.md §5 "둥글기".
abstract final class ClosetimoRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16; // 의류 칩
  static const double xl = 24; // 옷 카드 (1.5rem)
  static const double xxl = 28;

  /// 알약 모양 — 매우 큰 값으로 충분히 둥글게.
  static const double full = 999;
}

/// 입체감(elevation) 토큰. design.md §4 "톤 레이어링".
abstract final class ClosetimoElevation {
  /// 의류 상세 모달 등 떠 있어야 할 카드.
  static const ambientShadow = [
    BoxShadow(
      color: Color(0x0F2E342D), // rgba(46,52,45,0.06)
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  static const cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
}
