// 디자인 토큰 가드 로직(T082 확장).
//
// 두 가지 검사를 수행한다.
//   1. 색상 토큰 일치 — design.md의 핵심 헥스 코드가 tokens.dart에 존재하는가.
//   2. 하드코딩 간격 — lib/ 아래 위젯이 숫자 리터럴로 간격을 지정하지 않았는가.
//
// 실행 진입점은 `tool/check_design_tokens.dart`이고, 이 파일은 테스트에서
// 직접 호출할 수 있도록 순수 함수만 노출한다(파일 시스템 접근 없음).

/// 색상 토큰 검사 실패 1건.
class TokenColorViolation {
  const TokenColorViolation({required this.hex, required this.label});

  /// design.md에 명시된 소문자 6자리 헥스 코드 (예: `#47645e`).
  final String hex;

  /// 토큰의 역할 이름(보고용).
  final String label;

  @override
  String toString() => '$hex ($label)';
}

/// 하드코딩 검사 실패 1건.
class HardcodeViolation {
  const HardcodeViolation({
    required this.path,
    required this.line,
    required this.snippet,
    required this.reason,
  });

  /// 위반이 발생한 소스 파일 경로.
  final String path;

  /// 1-based 줄 번호.
  final int line;

  /// 해당 줄의 원본 텍스트.
  final String snippet;

  /// 위반 사유(보고용).
  final String reason;

  @override
  String toString() => '$path:$line $reason\n    $snippet';
}

/// design.md가 직접 지목한 핵심 컬러. 값은 소문자 6자리 헥스.
const Map<String, String> requiredDesignColors = {
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

/// tokens.dart 소스가 [hex]의 RGB 6자리를 포함하는지 검사한다.
///
/// tokens.dart의 Color 리터럴은 alpha가 0xFF가 기본이지만
/// outlineVariantGhost처럼 일부 토큰은 투명도가 다르다(0x26AEB4AA 등).
/// 따라서 RRGGBB 6자리만 케이스 무시로 검출한다.
bool tokenFileContainsColor(String tokenSource, String hex) {
  final rgb = hex.substring(1).toUpperCase();
  return tokenSource.toUpperCase().contains(rgb);
}

/// 색상 토큰 일치 검사. design.md에 있고 tokens.dart에도 있는 색상만 통과한다.
List<TokenColorViolation> checkDesignColors({
  required String tokenSource,
  required String designSource,
}) {
  final lowerDesign = designSource.toLowerCase();
  final violations = <TokenColorViolation>[];
  for (final entry in requiredDesignColors.entries) {
    final hex = entry.key;
    if (!lowerDesign.contains(hex) ||
        !tokenFileContainsColor(tokenSource, hex)) {
      violations.add(TokenColorViolation(hex: hex, label: entry.value));
    }
  }
  return violations;
}

/// 간격 이름자는 위젯 간격과 최소 높이에 한정한다.
final RegExp _spacingNamedPattern = RegExp(
  r'\b(mainAxisSpacing|crossAxisSpacing|spacing|runSpacing|minHeight)\s*:\s*'
  r'(-?\d+(?:\.\d+)?)(?=\s*[,)]|\s*$)',
);
final RegExp _constructorPattern = RegExp(
  r'\b(EdgeInsets(?:Directional)?\.(?:fromLTRB|fromSTEB|symmetric|only|all)|SizedBox)\s*\(',
);
final RegExp _numberLiteral = RegExp(r'^-?\d+(?:\.\d+)?$');

/// 한 줄 코드 조각도 같은 검사 경로를 사용한다.
List<String> findHardcodedSpacingInLine(String line) =>
    findHardcodedSpacingInLines([line]).map((v) => v.reason).toList();

/// 생성자의 정확한 괄호 범위를 찾아 이름자·다중 행 인자를 검사한다.
///
/// 문자열과 주석은 길이를 보존하며 지워 원본 줄 번호를 유지한다.
/// 키보드 inset 등 계산식은 숫자 리터럴이 아니므로 검사하지 않는다.
List<HardcodeViolation> findHardcodedSpacingInLines(List<String> lines) {
  final source = lines.join('\n');
  final code = _maskNonCode(source);
  final violations = <HardcodeViolation>[];
  final offsets = <int>{};
  void report(int offset, String value, String context) {
    if (num.parse(value) == 0 || !offsets.add(offset)) return;
    final line = '\n'.allMatches(source.substring(0, offset)).length + 1;
    violations.add(
      HardcodeViolation(
        path: '',
        line: line,
        snippet: lines[line - 1].trim(),
        reason: '하드코딩 간격 리터럴 $value ($context) — ClosetimoSpacing 토큰을 사용하세요',
      ),
    );
  }

  for (final match in _constructorPattern.allMatches(code)) {
    final start = match.end;
    var depth = 0;
    var argumentStart = start;
    for (var i = start; i < code.length; i++) {
      final ch = code[i];
      if (ch == ')' && depth == 0 || ch == ',' && depth == 0) {
        final argument = code.substring(argumentStart, i);
        final named = RegExp(r'^\s*(\w+)\s*:').firstMatch(argument);
        final name = named?.group(1);
        final valueStart = argumentStart + (named?.end ?? 0);
        final value = code.substring(valueStart, i).trim();
        final isInsets = match.group(1)!.startsWith('EdgeInsets');
        if ((isInsets || name == 'width' || name == 'height') &&
            _numberLiteral.hasMatch(value)) {
          report(
            valueStart + code.substring(valueStart, i).indexOf(value),
            value,
            match.group(1)!,
          );
        }
        argumentStart = i + 1;
        if (ch == ')') break;
      } else if (ch == '(' || ch == '[' || ch == '{') {
        depth++;
      } else if (ch == ')' || ch == ']' || ch == '}') {
        depth--;
      }
    }
  }
  for (final match in _spacingNamedPattern.allMatches(code)) {
    final value = match.group(2)!;
    report(
      match.start + match.group(0)!.lastIndexOf(value),
      value,
      match.group(1)!,
    );
  }
  violations.sort((a, b) => a.line.compareTo(b.line));
  return violations;
}

/// 주석·문자열 안의 생성자 예시를 실제 코드로 오인하지 않는다.
String _maskNonCode(String source) {
  final pattern = RegExp(
    r'''//[^\n]*|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"''',
  );
  return source.replaceAllMapped(
    pattern,
    (m) => m.group(0)!.replaceAll(RegExp(r'[^\n]'), ' '),
  );
}

/// 소스 여러 줄에 대한 하드코딩 검사 결과. [path]는 위반 보고용 경로다.
List<HardcodeViolation> checkHardcodedSpacing({
  required String path,
  required List<String> lines,
}) {
  return [
    for (final v in findHardcodedSpacingInLines(lines))
      HardcodeViolation(
        path: path,
        line: v.line,
        snippet: v.snippet,
        reason: v.reason,
      ),
  ];
}
