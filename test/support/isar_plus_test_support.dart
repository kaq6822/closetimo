import 'dart:io';

import 'package:isar_plus/isar_plus.dart';

const _version = '1.3.7';
const _archiveUrl =
    'https://github.com/ahmtydn/isar_plus/releases/download/'
    'v$_version/isar_plus_core.xcframework.zip';

bool _initialized = false;

/// macOS Flutter test 프로세스에서 Isar Plus native core를 준비한다.
///
/// `flutter test`는 테스트 파일별로 별도 프로세스를 병렬 실행하므로,
/// 공용 캐시 디렉토리의 다운로드·압축 해제·링크 단계가 프로세스 간에
/// 경합하면 손상된 아카이브/절반만 쓰인 dylib을 읽어 setUpAll이 간헐
/// 실패한다. 준비 구간 전체를 파일 잠금으로 직렬화하고, 산출물은 임시
/// 경로에 만든 뒤 원자적 rename으로만 최종 경로에 노출한다.
Future<void> initializeIsarPlusForTests() async {
  if (_initialized) return;
  if (!Platform.isMacOS) {
    throw UnsupportedError('Isar Plus test setup currently requires macOS');
  }

  final root = Directory(
    '${Directory.systemTemp.path}/closetimo_isar_plus_$_version',
  )..createSync(recursive: true);
  final dylib = File('${root.path}/libisar_plus.dylib');

  // 잠금은 비동기 API를 사용한다. lockSync는 이소레이트 스레드를 통째로
  // 막아 테스트 타임아웃 타이머까지 멈추므로(리뷰 지적), 대기가 IO 스레드로
  // 넘어가는 async lock으로 타임아웃이 정상 동작하게 한다.
  final lockHandle = File(
    '${root.path}/.setup.lock',
  ).openSync(mode: FileMode.write);
  try {
    await lockHandle.lock(FileLock.blockingExclusive);
    if (!dylib.existsSync()) {
      await _buildDylib(root, dylib);
    }
  } finally {
    await lockHandle.unlock();
    lockHandle.closeSync();
  }

  await Isar.initialize(dylib.path);
  _initialized = true;
}

Future<void> _buildDylib(Directory root, File dylib) async {
  final archive = File('${root.path}/isar_plus_core.xcframework.zip');
  if (!archive.existsSync()) {
    final partial = File('${archive.path}.$pid.part');
    // 다운로드가 stall되면 락을 쥔 채 전체 테스트가 멈추므로 타임아웃을 건다.
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30);
    try {
      final request = await client.getUrl(Uri.parse(_archiveUrl));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'Failed to download Isar Plus core: ${response.statusCode}',
        );
      }
      await response.pipe(partial.openWrite());
    } finally {
      client.close();
    }
    partial.renameSync(archive.path);
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
  final partialDylib = '${dylib.path}.$pid.part';
  final clang = await Process.run('clang', [
    '-dynamiclib',
    '-Wl,-force_load,$staticLibrary',
    '-o',
    partialDylib,
    '-framework',
    'CoreFoundation',
    '-framework',
    'Security',
  ]);
  if (clang.exitCode != 0) {
    throw StateError('Failed to link Isar Plus core: ${clang.stderr}');
  }
  File(partialDylib).renameSync(dylib.path);
}
