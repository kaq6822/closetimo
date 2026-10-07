// T077 — 디자인 토큰 검사기 회귀 테스트.
//
// `tool/check_design_tokens.dart`가 두 가지를 검사한다.
//   1. design.md ↔ tokens.dart 색상 토큰 일치
//   2. lib/ 위젯의 하드코딩 간격
// 검사 로직이 "정상 사례를 통과"시키는지와 "위반 사례를 실제로 잡는지"를
// 양쪽 다 검증한다(위반 검사가 조용히 통과하는 상태를 남기지 않는다).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/design_token_check.dart';

void main() {
  group('색상 토큰 검사', () {
    // design.md와 tokens.dart의 실제 내용을 최소 경로로 재현한 픽스처.
    const fixtureHexes = [
      '#47645e',
      '#3c5852',
      '#dffef7',
      '#fafaf5',
      '#f3f4ee',
      '#ffffff',
      '#ecefe7',
      '#e3e2e2',
      '#576342',
      '#5b6159',
      '#2e342d',
      '#9f403d',
      '#aeb4aa',
    ];

    String buildSource(List<String> hexes) => hexes
        .map((h) => '  static const color = Color(0xFF${h.substring(1)});')
        .join('\n');

    test('design.md와 tokens.dart가 모두 충족하면 위반 0건', () {
      final violations = checkDesignColors(
        tokenSource: buildSource(fixtureHexes),
        designSource: fixtureHexes.join(' '),
      );
      expect(violations, isEmpty);
    });

    test('tokens.dart에 없는 색상은 위반으로 보고된다', () {
      final withoutPrimary = fixtureHexes.where((h) => h != '#47645e').toList();
      final violations = checkDesignColors(
        tokenSource: buildSource(withoutPrimary),
        designSource: fixtureHexes.join(' '),
      );
      expect(violations, hasLength(1));
      expect(violations.single.hex, '#47645e');
      expect(violations.single.label, contains('primary'));
    });

    test('design.md에 없는 색상은 위반으로 보고된다', () {
      final violations = checkDesignColors(
        tokenSource: buildSource(fixtureHexes),
        designSource: fixtureHexes.where((h) => h != '#9f403d').join(' '),
      );
      expect(violations.map((v) => v.hex), contains('#9f403d'));
    });

    test('투명도가 붙은 토큰도 RGB 6자리로 검출된다', () {
      // outlineVariantGhost = Color(0x26AEB4AA)처럼 alpha가 다르다.
      expect(tokenFileContainsColor('Color(0x26AEB4AA)', '#aeb4aa'), isTrue);
    });

    test('실제 design.md ↔ tokens.dart가 현재 기준을 통과한다', () {
      final design = File('.specify/memory/design.md').readAsStringSync();
      final tokens = File('lib/app/theme/tokens.dart').readAsStringSync();
      expect(
        checkDesignColors(tokenSource: tokens, designSource: design),
        isEmpty,
      );
    });
  });

  group('하드코딩 간격 검사 — 정상 사례', () {
    test('Spacing 토큰을 쓰면 위반이 없다', () {
      const lines = [
        'padding: const EdgeInsets.all(ClosetimoSpacing.md),',
        'padding: const EdgeInsets.only(left: ClosetimoSpacing.xs),',
        'const SizedBox(height: ClosetimoSpacing.lg),',
        'const SizedBox(width: ClosetimoSpacing.sm),',
        'mainAxisSpacing: ClosetimoSpacing.space12,',
        'crossAxisSpacing: ClosetimoSpacing.space12,',
        'spacing: ClosetimoSpacing.sm,',
        'runSpacing: ClosetimoSpacing.sm,',
        'minHeight: ClosetimoSpacing.space56,',
      ];
      expect(lines.expand(findHardcodedSpacingInLine), isEmpty);
    });

    test('다중 행으로 나뉜 토큰 참조는 위반이 없다', () {
      const lines = [
        'padding: const EdgeInsets.fromLTRB(',
        '  ClosetimoSpacing.md,',
        '  ClosetimoSpacing.space14,',
        '  ClosetimoSpacing.md,',
        '  ClosetimoSpacing.space14,',
        '),',
      ];
      expect(findHardcodedSpacingInLines(lines), isEmpty);
    });

    test('계산값(키보드 inset)은 하드코딩이 아니다', () {
      const lines = [
        'padding: EdgeInsets.only(bottom: viewInsets),',
        'padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),',
      ];
      expect(lines.expand(findHardcodedSpacingInLine), isEmpty);
    });

    test('주석 안의 숫자는 검사 대상이 아니다', () {
      const lines = ['// 간격은 16을 사용했다', '/// 이전에는 EdgeInsets.all(20)이었다'];
      expect(lines.expand(findHardcodedSpacingInLine), isEmpty);
    });

    test('간격 문맥이 아닌 숫자는 오탐으로 잡지 않는다', () {
      // TextStyle.height(행간격 비율)와 데이터 레이어 맵 키는 간격이 아니다.
      const lines = [
        '  height: 1.5,',
        '        Category.top: 0,',
        '  fontSize: 13,',
        '  letterSpacing: 0.5,',
      ];
      expect(lines.expand(findHardcodedSpacingInLine), isEmpty);
    });
  });

  group('하드코딩 간격 검사 — 위반 사례', () {
    test('EdgeInsets 숫자 리터럴을 잡는다', () {
      final reasons = findHardcodedSpacingInLine(
        'padding: const EdgeInsets.all(20),',
      );
      expect(reasons, hasLength(1));
      expect(reasons.single, contains('20'));
      expect(reasons.single, contains('ClosetimoSpacing'));
    });

    test('EdgeInsets.fromLTRB의 모든 인자를 검사한다', () {
      final reasons = findHardcodedSpacingInLine(
        'padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),',
      );
      // 16 두 개 + 14 두 개
      expect(reasons, hasLength(4));
      expect(reasons.where((r) => r.contains('16')), hasLength(2));
      expect(reasons.where((r) => r.contains('14')), hasLength(2));
    });

    test('다중 행 EdgeInsets 인자를 검사한다', () {
      const lines = [
        'padding: const EdgeInsets.fromLTRB(',
        '  ClosetimoSpacing.md,',
        '  14,',
        '  ClosetimoSpacing.md,',
        '  ClosetimoSpacing.space14,',
        '),',
      ];
      // 다중 행 인자는 줄 단위가 아니라 블록 단위로 검사해야 잡힌다.
      final violations = findHardcodedSpacingInLines(lines);
      expect(violations, hasLength(1));
      expect(violations.single.reason, contains('14'));
      // 위반이 보고된 줄이 실제 숫자 리터럴이 있는 줄이어야 한다(3번째 줄).
      expect(violations.single.line, 3);
    });

    test('SizedBox height/width 숫자 리터럴을 잡는다', () {
      expect(
        findHardcodedSpacingInLine('const SizedBox(height: 10),'),
        hasLength(1),
      );
      expect(
        findHardcodedSpacingInLine('const SizedBox(width: 4),'),
        hasLength(1),
      );
    });

    test('간격 이름자의 숫자 리터럴을 잡는다', () {
      expect(findHardcodedSpacingInLine('mainAxisSpacing: 12,'), hasLength(1));
      expect(
        findHardcodedSpacingInLine(
          'constraints: const BoxConstraints(minHeight: 56),',
        ),
        hasLength(1),
      );
    });

    test('위반 보고에 파일 경로와 줄 번호가 포함된다', () {
      final violations = checkHardcodedSpacing(
        path: 'lib/example.dart',
        lines: ['// 정상', 'padding: const EdgeInsets.all(20),'],
      );
      expect(violations, hasLength(1));
      expect(violations.single.path, 'lib/example.dart');
      expect(violations.single.line, 2);
      expect(violations.single.toString(), contains('lib/example.dart:2'));
    });

    test('한 줄의 여러 위반을 모두 보고한다', () {
      final violations = checkHardcodedSpacing(
        path: 'lib/example.dart',
        lines: [
          'child: SizedBox(width: 62, height: 62, child: _resolve(ref)),',
        ],
      );
      expect(violations, hasLength(2));
    });
  });

  group('누락된 간격 회귀', () {
    test('이름자 EdgeInsets와 다중 행 SizedBox를 검출한다', () {
      final violations = checkHardcodedSpacing(
        path: 'probe.dart',
        lines: [
          'padding: EdgeInsets.symmetric(vertical: 40),',
          'padding: EdgeInsets.only(left: 4, bottom: 10),',
          'child: SizedBox(',
          '  height: 16,',
          '  width: 20,',
          '),',
        ],
      );
      expect(violations.map((v) => v.line), [1, 2, 2, 4, 5]);
    });

    test('바깥 호출과 중첩 위젯의 간격도 검출한다', () {
      final violations = findHardcodedSpacingInLines([
        'Container(padding: EdgeInsets.all(8), child: SizedBox(',
        '  width: 12, child: Text("SizedBox(height: 40)"),',
        ')),',
      ]);
      expect(violations.map((v) => v.line), [1, 2]);
    });

    test('주석·문자열·계산값은 검사하지 않는다', () {
      expect(
        findHardcodedSpacingInLines([
          '/* EdgeInsets.only(left: 40) */',
          'final label = "SizedBox(height: 40)";',
          'EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),',
          'SizedBox(height: ClosetimoSpacing.sm, child: Text("hello")),',
          'EdgeInsets.only(left: 0),',
        ]),
        isEmpty,
      );
    });
  });

  group('실제 lib/ 소스', () {
    late List<String> libFiles;

    setUpAll(() {
      libFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          .where((f) => !f.path.endsWith('.freezed.dart'))
          .where((f) => f.path != 'lib/app/theme/tokens.dart')
          .map((f) => f.path)
          .toList();
    });

    test('검사 대상 파일이 실제로 발견된다', () {
      // 가드가 빈 목록을 통과시키는 사고를 막는다.
      expect(libFiles.length, greaterThan(20));
    });

    test('lib/ 아래에 하드코딩 간격이 없다', () {
      final violations = <HardcodeViolation>[];
      for (final path in libFiles) {
        violations.addAll(
          checkHardcodedSpacing(
            path: path,
            lines: File(path).readAsLinesSync(),
          ),
        );
      }
      expect(
        violations.map((v) => '${v.path}:${v.line} ${v.snippet}').toList(),
        isEmpty,
        reason: '하드코딩 간격은 ClosetimoSpacing 토큰으로 교체해야 한다.',
      );
    });
  });
}
