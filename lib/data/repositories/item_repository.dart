// contracts/repositories.md §1 — UI/feature 코드는 본 인터페이스만 의존한다.

import '../models/item.dart';
import '../../features/add_item/new_item_draft.dart';

enum WardrobeSort { statusCleanFirst, recentlyWorn, mostWorn }

class WardrobeStats {
  const WardrobeStats({
    required this.total,
    required this.clean,
    required this.dirty,
    required this.perBucket,
  });

  final int total;
  final int clean;
  final int dirty;

  /// 홈 2x2 카드(아우터·상의·하의·기타) 매핑. 그 외 카테고리는
  /// `Category.etc` 키에 합산된다(FR-019, [CategoryLabel.homeBucket]).
  final Map<Category, int> perBucket;
}

abstract interface class ItemRepository {
  // ── 읽기 ──
  Stream<List<Item>> watchAll();

  Stream<List<Item>> watchFiltered({
    Category? category,
    String query,
    required WardrobeSort sort,
  });

  Stream<List<Item>> watchRecentlyWorn({int limit});

  Stream<WardrobeStats> watchStats();

  Future<Item?> get(int id);

  // ── 쓰기 ──
  /// FR-001~004. 명칭 검증 실패 시 [ArgumentError]를 던진다.
  Future<int> create(NewItemDraft draft);
}
