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
///
/// 두 계층으로 구성한다.
///  1. `space<N>` 원시 그리드 — design.md의 4-grid(2px 단위)를 그대로 노출한다.
///     위젯에서 하드코딩된 숫자 간격을 기계적으로 배제하려면 **값이 아니라
///     토큰 참조**를 강제해야 하므로, 검사 도구(`tool/check_design_tokens.dart`)가
///     이 목록을 허용 값 집합으로 쓴다.
///  2. 의미 단계 별칭 — design.md가 직접 지목한 값에 이름을 붙인다.
///
/// 단위는 모두 logical px다.
abstract final class ClosetimoSpacing {
  // ── 4-grid 원시 스텝 ──
  static const double space2 = 2; // scale 0.5 (아이콘·텍스트 광학 정렬)
  static const double space4 = 4; // scale 1
  static const double space5 = 5; // 상태 라벨의 세로 패딩
  static const double space28 = 28; // 세탁 주기 숫자 영역 너비
  static const double space34 = 34; // 세탁 주기 조절 버튼 치수
  static const double space6 = 6; // scale 1.5 (컴포넌트 최소 치수)
  static const double space8 = 8; // scale 2
  static const double space10 = 10; // scale 2.5 (칩·라벨 좌우 패딩)
  static const double space12 = 12; // scale 3 (그리드 카드 간격)
  static const double space14 = 14; // scale 3.5 (카드 내부 행 간격)
  static const double space16 = 16; // scale 4
  static const double space18 = 18; // scale 4.5 (입력 필드 좌우 패딩)
  static const double space20 = 20; // scale 5 (카드 패딩)
  static const double space22 = 22; // scale 5.5 (타임라인 행 간격)
  static const double space24 = 24; // scale 6
  static const double space26 = 26; // scale 6.5 (폼 필드 간격)
  static const double space32 = 32; // scale 8
  static const double space40 = 40; // scale 10 (빈 상태 상단 여백)
  static const double space42 = 42; // scale 10.5 (타임라인 라인 오프셋)
  static const double space44 = 44; // scale 11 (≈2.75rem)
  static const double space52 = 52; // scale 13 (SoftButton 최소 높이)
  static const double space56 = 56; // scale 14 (PrimaryButton 최소 높이)
  static const double space60 = 60; // scale 15 (빈 상태 세로 여백)
  static const double space76 = 76; // scale 19 (하단 탭바 회피 여백)
  static const double space120 = 120; // scale 30 (고정 하단 CTA 여백)

  // ── 의미 단계 별칭 (design.md §7 매핑) ──
  static const double xs = space4; // scale 1
  static const double sm = space8; // scale 2
  static const double md = space16; // scale 3 (카드 내부 패딩 표준, spacing-3 1rem)
  static const double lg = 22.4; // scale 4 (베이스라인 1.4rem)
  static const double xl = space24; // 리스트 아이템 간 수직 간격
  static const double xxl = space32; // 섹션 간 수직 간격
  static const double huge = space44; // scale 8 (≈2.75rem 주요 섹션 호흡)
}

/// 컴포넌트 고정 치수 토큰. 간격 스케일과 별개지만 design.md 밖의 임의 숫자를
/// 막기 위해 같은 원칙(토큰 참조)으로 관리한다.
abstract final class ClosetimoSize {
  /// 세탁 목록 타일의 정사각 사진 크기.
  static const double tileThumbnail = 62;

  /// #49 — 탭 가능한 컨트롤의 최소 터치 영역(Material·Android 권장 48dp).
  /// 시각 크기가 이보다 작은 컨트롤은 `MinTouchTarget`으로 감싸 영역만 넓힌다.
  static const double minTouchTarget = 48;

  /// #49 — 비선택 체크 컨트롤의 윤곽선·선택된 세탁 방법 타일의 테두리 두께.
  static const double controlOutline = 2;
}

/// 라운딩(corner radius) 토큰. design.md §5 "둥글기".
abstract final class ClosetimoRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16; // 의류 칩
  static const double lgPlus = 18; // 필터 카드 등 중간 라운딩
  static const double xlMinus = 20; // 홈 섹션 카드
  static const double xl = 24; // 옷 카드 (1.5rem)
  static const double xxl = 28;
  static const double hairline = 2; // 타임라인 세로 라인 등 헤어라인 요소

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
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 2), blurRadius: 8),
  ];
}
