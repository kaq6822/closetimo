// 이슈 #8 — ImageStore.delete의 best-effort 실패 경로 단위 테스트.
// 002 FR-011: 이미지 삭제 실패해도 DB 삭제 성공으로 간주한다. 즉 delete()는
// 파일이 없거나 삭제가 불가능한 상황에서도 예외를 던지지 않아야 한다.
// 실제 파일 삭제 성공 경로는 isar_item_repository_test.dart가 이미 커버하므로
// 여기서는 무존재/실패 경로에서의 no-throw 계약에 집중한다.

import 'dart:io';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmpDir;
  late ImageStore store;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('closetimo_image_store_test');
    store = ImageStore(overrideRoot: tmpDir);
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('존재하지 않는 경로를 삭제해도 예외를 던지지 않는다', () async {
    await expectLater(store.delete('items/does_not_exist.jpg'), completes);
  });

  test('존재하는 파일은 실제로 삭제된다 (성공 경로 회귀)', () async {
    final target = File(p.join(tmpDir.path, 'ghost.jpg'));
    target.writeAsStringSync('dummy');
    expect(target.existsSync(), isTrue);

    await store.delete('items/ghost.jpg');

    expect(target.existsSync(), isFalse);
  });

  test('삭제 대상이 파일이 아니라 디렉터리여도 예외를 던지지 않는다', () async {
    // File(abs).existsSync()는 경로가 디렉터리이면 false를 반환하므로 이
    // 케이스는 실제로 catch(_) 분기가 아닌 existsSync 가드에서 걸러진다.
    // 그럼에도 delete()가 예상치 못한 엔트리 타입 앞에서 예외 없이 완료됨을
    // 보장해, 권한 조작 없이도 best-effort 계약(FR-011)을 뒷받침한다.
    final dirEntry = Directory(p.join(tmpDir.path, 'dir_entry.jpg'))
      ..createSync();
    addTearDown(() {
      if (dirEntry.existsSync()) dirEntry.deleteSync(recursive: true);
    });

    await expectLater(store.delete('items/dir_entry.jpg'), completes);
    // 디렉터리는 File API 대상이 아니므로 그대로 남아 있어야 한다.
    expect(dirEntry.existsSync(), isTrue);
  });
}
