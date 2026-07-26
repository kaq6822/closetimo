import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final plugin = Directory('packages/isar_flutter_libs');

  test('legacy plugin이 iOS SwiftPM local binary target을 선언한다', () {
    final manifest = File('${plugin.path}/ios/isar_flutter_libs/Package.swift');
    expect(manifest.existsSync(), isTrue);

    final source = manifest.readAsStringSync();
    expect(source, contains('// swift-tools-version: 5.9'));
    expect(source, contains('name: "isar_flutter_libs"'));
    expect(source, contains('name: "isar_legacy_core"'));
    expect(source, contains('path: "isar_legacy.xcframework"'));
    expect(source, contains('.iOS("13.0")'));
    expect(source, isNot(contains('"-all_load"')));
  });

  test('고정한 native binary가 기록된 SHA-256과 일치한다', () async {
    final checksumFile = File('${plugin.path}/BINARY_CHECKSUMS.sha256');
    expect(checksumFile.existsSync(), isTrue);
    final entries = checksumFile.readAsLinesSync().where(
      (line) => line.isNotEmpty && !line.startsWith('#'),
    );

    for (final entry in entries) {
      final separator = entry.indexOf('  ');
      expect(separator, greaterThan(0));
      final expected = entry.substring(0, separator);
      final relativePath = entry.substring(separator + 2);
      final binary = File('${plugin.path}/$relativePath');
      expect(binary.existsSync(), isTrue, reason: relativePath);

      final result = await Process.run('shasum', ['-a', '256', binary.path]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final actual = '${result.stdout}'.split(' ').first;
      expect(actual, expected, reason: relativePath);
    }
  });

  test('legacy 동적 library는 Isar C API 심볼만 외부에 노출한다', () async {
    final binaries = [
      File(
        '${plugin.path}/ios/isar_flutter_libs/isar_legacy.xcframework/'
        'ios-arm64/libisar_legacy.dylib',
      ),
      File(
        '${plugin.path}/ios/isar_flutter_libs/isar_legacy.xcframework/'
        'ios-arm64_x86_64-simulator/libisar_legacy.dylib',
      ),
    ];

    for (final binary in binaries) {
      expect(binary.existsSync(), isTrue, reason: binary.path);
      final result = await Process.run('nm', ['-gU', binary.path]);
      expect(result.exitCode, 0, reason: '${result.stderr}');

      final symbols = '${result.stdout}'
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim().split(RegExp(r'\s+')).last)
          .toList();
      expect(symbols, isNotEmpty, reason: binary.path);
      expect(
        symbols.every((symbol) => symbol.startsWith('_isar_')),
        isTrue,
        reason: binary.path,
      );
    }
  });

  test('Android 앱이 Flutter 3.44 지원 기준인 API 24를 고정한다', () {
    final appGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final rootGradle = File('android/build.gradle.kts').readAsStringSync();

    expect(appGradle, contains('minSdk = 24'));
    expect(rootGradle, isNot(contains('defaultConfig.minSdk')));
  });
}
