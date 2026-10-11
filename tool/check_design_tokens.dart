// T082 — 디자인 토큰 가드.
//
// 검사 항목:
//   1. design.md의 핵심 컬러가 tokens.dart에 일치하는가 (색상 토큰)
//   2. lib/ 아래 위젯이 숫자 리터럴로 간격을 지정하지 않았는가 (하드코딩 간격)
//
// 사용법:
//   dart run tool/check_design_tokens.dart
// 헌법 II(디자인 시스템 일관성)의 자동 가드. CI에서도 실행할 수 있다.
// 검사 로직 자체는 `tool/design_token_check.dart`에 있고, 단위 테스트가
// 정상 사례와 위반 사례를 모두 검증한다.

import 'dart:io';

import 'design_token_check.dart';

const _tokensPath = 'lib/app/theme/tokens.dart';
const _designPath = '.specify/memory/design.md';

/// 하드코딩 검사에서 제외할 경로(토큰 정의 자체와 생성 파일).
const _excludedPrefixes = [
  'lib/app/theme/tokens.dart',
  '.g.dart',
  '.freezed.dart',
];

void main(List<String> args) {
  final tokens = File(_tokensPath).readAsStringSync();
  final design = File(_designPath).readAsStringSync();

  var failed = 0;

  // ── 1. 색상 토큰 일치 ──
  final colorViolations = checkDesignColors(
    tokenSource: tokens,
    designSource: design,
  );
  for (final v in colorViolations) {
    stderr.writeln('✗ MISSING ${v.hex} (${v.label})');
  }
  if (colorViolations.isEmpty) {
    stdout.writeln(
      '✓ ${requiredDesignColors.length}개 핵심 색상 토큰 모두 '
      'design.md ↔ tokens.dart 일치',
    );
  } else {
    failed += colorViolations.length;
    stderr.writeln('${colorViolations.length}개 색상 토큰 불일치 — 헌법 II 위반');
  }

  // ── 2. 하드코딩 간격 ──
  final hardcodeViolations = _scanLib();
  for (final v in hardcodeViolations) {
    stderr.writeln('✗ $v');
  }
  if (hardcodeViolations.isEmpty) {
    stdout.writeln('✓ lib/ 하드코딩 간격 0건');
  } else {
    failed += hardcodeViolations.length;
    stderr.writeln(
      '${hardcodeViolations.length}건 하드코딩 간격 — 헌법 II 위반 '
      '(ClosetimoSpacing 토큰을 사용하세요)',
    );
  }

  if (failed == 0) {
    exit(0);
  }
  exit(1);
}

/// lib/ 아래 Dart 소스에서 하드코딩 간격을 수집한다.
List<HardcodeViolation> _scanLib() {
  final violations = <HardcodeViolation>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (_excludedPrefixes.any(entity.path.contains)) continue;
    violations.addAll(
      checkHardcodedSpacing(path: entity.path, lines: entity.readAsLinesSync()),
    );
  }
  violations.sort((a, b) => a.path.compareTo(b.path));
  return violations;
}
