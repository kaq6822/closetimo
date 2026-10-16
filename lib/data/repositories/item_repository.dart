// contracts/repositories.md §1 — UI/feature 코드는 본 인터페이스만 의존한다.

import '../models/item.dart';
import '../models/item_filter.dart';
import '../models/item_patch.dart';
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

  /// 홈 2x2 카드(아우터·상의·하의·그 외) 집계(FR-019, #37). 모든
  /// [HomeBucket] 키를 가지며 값의 합은 [total]과 같다. 카드 탭 이동은
  /// [ItemFilter.homeBucket]으로 같은 범위를 조회한다.
  final Map<HomeBucket, int> perBucket;
}

abstract interface class ItemRepository {
  // ── 읽기 ──
  /// 보관 여부와 무관한 전체 옷(최신 등록 우선). 화면에는 보관 축을 적용하는
  /// [watchFiltered]를 쓴다(#44).
  Stream<List<Item>> watchAll();

  /// FR-005~007, #37·#41. [filter] 조건([ItemFilter.matches])을 만족하는 옷을
  /// [sort] 순서로 내보낸다.
  Stream<List<Item>> watchFiltered({
    ItemFilter filter = const ItemFilter(),
    required WardrobeSort sort,
  });

  /// FR-020. 보관한 옷은 제외한다(#44).
  Stream<List<Item>> watchRecentlyWorn({int limit});

  /// FR-018·019. 보관한 옷은 제외한 활성 옷만 집계한다(#44).
  Stream<WardrobeStats> watchStats();

  Future<Item?> get(int id);

  // ── 쓰기 ──
  /// FR-001~004. 명칭 검증 실패 시 [ArgumentError]를 던진다.
  Future<int> create(NewItemDraft draft);

  /// 002 FR-001~006. 편집 가능 필드를 갱신하고 status를 재평가한다(FR-004).
  /// 명칭이 비어 있으면 [ArgumentError], `id` 미존재 시 no-op.
  Future<void> update(int id, ItemPatch patch);

  /// 002 FR-008~012. 대상 Item + 연관 WearEvent 전량을 단일 트랜잭션으로
  /// 제거하고 sandbox 이미지 파일을 best-effort 삭제한다. `id` 미존재 시 no-op.
  Future<void> delete(int id);
}
