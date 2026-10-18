// research.md §6 — 사용자가 선택한 사진을 앱 sandbox로 복사하여
// 갤러리 원본 삭제와 무관하게 옷 표시를 안정시킨다.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStore {
  ImageStore({Directory? overrideRoot}) : _overrideRoot = overrideRoot;

  final Directory? _overrideRoot;

  Future<Directory> _rootDir() async {
    if (_overrideRoot != null) return _overrideRoot;
    final docs = await getApplicationDocumentsDirectory();
    final items = Directory(p.join(docs.path, 'items'));
    if (!items.existsSync()) {
      items.createSync(recursive: true);
    }
    return items;
  }

  /// 소스 파일을 `documents/items/{itemId}.jpg`로 복사한다.
  /// 반환값은 Item 엔티티에 저장될 상대 경로(`items/{itemId}.jpg`).
  Future<String> copyTo(File source, String itemId) async {
    final root = await _rootDir();
    final target = File(p.join(root.path, '$itemId.jpg'));
    await source.copy(target.path);
    return p.join('items', '$itemId.jpg');
  }

  /// #40 복원 — 바이트를 `documents/items/{fileName}`에 쓰고 상대 경로
  /// (`items/{fileName}`)를 돌려준다. 임시 파일에 쓴 뒤 rename하므로 중간에
  /// 실패해도 반쪽 파일이 대상 이름으로 남지 않는다. 실패 시
  /// [FileSystemException]을 그대로 던진다(공간 부족 분류는 호출자가 한다).
  Future<String> writeBytes(String fileName, List<int> bytes) async {
    final root = await _rootDir();
    final target = File(p.join(root.path, fileName));
    final partial = File('${target.path}.part');
    try {
      await partial.writeAsBytes(bytes, flush: true);
      await partial.rename(target.path);
    } catch (_) {
      if (partial.existsSync()) await partial.delete();
      rethrow;
    }
    return p.join('items', fileName);
  }

  /// 상대 경로 → sandbox 절대 경로 변환.
  Future<String> absolutePath(String relativePath) async {
    if (_overrideRoot != null) {
      // 테스트 오버라이드 루트는 `items/` 접두를 제거한 하위로 매핑한다.
      final name = p.basename(relativePath);
      return p.join(_overrideRoot.path, name);
    }
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, relativePath);
  }

  /// 002 FR-011 — 상대 경로(`items/{id}.jpg`)의 sandbox 파일을 삭제한다.
  /// 파일이 없거나 삭제에 실패해도 예외를 던지지 않는다(best-effort).
  Future<void> delete(String relativePath) async {
    try {
      final abs = await absolutePath(relativePath);
      final file = File(abs);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {
      // best-effort: 파일 삭제 실패는 무시한다.
    }
  }
}

final imageStoreProvider = Provider<ImageStore>((ref) => ImageStore());
