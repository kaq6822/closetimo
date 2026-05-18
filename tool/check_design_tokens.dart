// T082 — design.md ↔ lib/app/theme/tokens.dart 헥스 코드 일치 검증.
//
// 사용법:
//   dart run tool/check_design_tokens.dart
// 헌법 II(디자인 시스템 일관성)의 자동 가드. CI에서도 실행할 수 있다.

import 'dart:io';

void main(List<String> args) {
  final tokens = File('lib/app/theme/tokens.dart').readAsStringSync();
  final design = File('.specify/memory/design.md').readAsStringSync();

  // design.md에 명시된 핵심 컬러(소문자 hex 6자리).
  const required = {
    '#47645e': 'primary (Sage)',
    '#3c5852': 'primary_dim',
    '#dffef7': 'on-primary',
    '#fafaf5': 'background / surface',
    '#f3f4ee': 'surface-container-low',
    '#ffffff': 'surface-container-lowest',
    '#ecefe7': 'surface-container',
    '#e3e2e2': 'secondary_container (chip bg)',
    '#576342': 'tertiary',
    '#5b6159': 'on_surface_variant',
    '#2e342d': 'on_background',
    '#9f403d': 'error',
    '#aeb4aa': 'outline-variant',
  };

  var failed = 0;
  required.forEach((hex, label) {
    final ok = design.toLowerCase().contains(hex) &&
        _tokenFileContains(tokens, hex);
    if (!ok) {
      stderr.writeln('✗ MISSING $hex ($label)');
      failed++;
    }
  });

  if (failed == 0) {
    stdout.writeln('✓ ${required.length}개 핵심 토큰 모두 design.md ↔ tokens.dart 일치');
    exit(0);
  } else {
    stderr.writeln('$failed개 토큰 불일치 — 헌법 II 위반');
    exit(1);
  }
}

bool _tokenFileContains(String source, String hex) {
  // tokens.dart의 Color 리터럴은 alpha 채널이 0xFF가 기본이지만
  // outlineVariantGhost처럼 일부 토큰은 투명도가 다르다(0x26AEB4AA 등).
  // 따라서 RRGGBB 6자리만 케이스 무시로 검출한다.
  final rgb = hex.substring(1).toUpperCase();
  return source.toUpperCase().contains(rgb);
}
