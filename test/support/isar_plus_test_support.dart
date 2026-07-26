import 'dart:io';

import 'package:isar_plus/isar_plus.dart';

const _version = '1.3.7';
const _archiveUrl =
    'https://github.com/ahmtydn/isar_plus/releases/download/'
    'v$_version/isar_plus_core.xcframework.zip';

bool _initialized = false;

/// macOS Flutter test 프로세스에서 Isar Plus native core를 준비한다.
Future<void> initializeIsarPlusForTests() async {
  if (_initialized) return;
  if (!Platform.isMacOS) {
    throw UnsupportedError('Isar Plus test setup currently requires macOS');
  }

  final root = Directory(
    '${Directory.systemTemp.path}/closetimo_isar_plus_$_version',
  )..createSync(recursive: true);
  final dylib = File('${root.path}/libisar_plus.dylib');
  if (!dylib.existsSync()) {
    final archive = File('${root.path}/isar_plus_core.xcframework.zip');
    if (!archive.existsSync()) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(_archiveUrl));
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw StateError(
            'Failed to download Isar Plus core: ${response.statusCode}',
          );
        }
        await response.pipe(archive.openWrite());
      } finally {
        client.close();
      }
    }

    final unzip = await Process.run('unzip', [
      '-oq',
      archive.path,
      '-d',
      root.path,
    ]);
    if (unzip.exitCode != 0) {
      throw StateError('Failed to extract Isar Plus core: ${unzip.stderr}');
    }
    final staticLibrary =
        '${root.path}/isar_plus_core.xcframework/'
        'macos-arm64_x86_64/libisar_plus.a';
    final clang = await Process.run('clang', [
      '-dynamiclib',
      '-Wl,-force_load,$staticLibrary',
      '-o',
      dylib.path,
      '-framework',
      'CoreFoundation',
      '-framework',
      'Security',
    ]);
    if (clang.exitCode != 0) {
      throw StateError('Failed to link Isar Plus core: ${clang.stderr}');
    }
  }

  await Isar.initialize(dylib.path);
  _initialized = true;
}
