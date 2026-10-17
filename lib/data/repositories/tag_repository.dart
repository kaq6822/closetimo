// contracts/repositories.md §2b — 사용자 태그 일괄 편집(#46).
//
// 태그는 `Item.tags`에만 저장되므로 읽기는 `ItemRepository.watchAll()`을
// `summarizeTags`(item_tags.dart)로 집계해 얻는다. 이 인터페이스는 여러 옷에 걸친
// 쓰기만 단일 트랜잭션으로 수행한다. 어떤 메서드도 옷·사진·착용/세탁 기록을
// 지우거나 카운터·상태·바구니·보관 필드를 바꾸지 않는다.

abstract interface class TagRepository {
  /// [itemIds]의 옷에 [tag]를 붙인다. 이미 같은 태그(대소문자 무시)가 있으면
  /// 그대로 둔다. 바뀐 옷 수를 돌려준다. 정규화 후 빈 태그면 [ArgumentError].
  /// 존재하지 않는 id는 무시한다.
  Future<int> addTag(Set<int> itemIds, String tag);

  /// [itemIds]의 옷에서 [tag]를 뗀다(대소문자 무시). 바뀐 옷 수를 돌려준다.
  Future<int> removeTag(Set<int> itemIds, String tag);

  /// [addTag]를 여러 태그에 대해 **한 트랜잭션**으로 적용한다. 일부만 저장되지 않으며,
  /// 하나라도 정규화 후 비면 아무것도 쓰지 않고 [ArgumentError]. 바뀐 **옷** 수를
  /// 돌려준다(옷 하나가 여러 태그로 바뀌어도 1).
  Future<int> addTags(Set<int> itemIds, Iterable<String> tags);

  /// [removeTag]를 여러 태그에 대해 한 트랜잭션으로 적용한다. 바뀐 옷 수를 돌려준다.
  Future<int> removeTags(Set<int> itemIds, Iterable<String> tags);

  /// 모든 옷(보관 포함)에서 [from](대소문자 무시)을 [to]로 바꾼다. 이미 [to]가 붙은 옷은
  /// 중복 없이 하나로 합친다(중복 병합). 바뀐 옷 수를 돌려준다.
  /// [to]가 정규화 후 비면 [ArgumentError].
  Future<int> renameTag(String from, String to);

  /// 모든 옷(보관 포함)에서 [tag](대소문자 무시)를 뗀다. 옷과 착용 기록은 남는다.
  /// 바뀐 옷 수를 돌려준다.
  Future<int> deleteTag(String tag);
}
