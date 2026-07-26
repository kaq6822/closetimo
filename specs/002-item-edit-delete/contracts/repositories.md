# Contract: Repository Interfaces (002 delta)

**Date**: 2026-07-04 **Feature**: 002-item-edit-delete

001-home-dashboard/contracts/repositories.md를 상속한다. 본 문서는 `ItemRepository`에
추가되는 `update`·`delete`와 `ImageStore`에 추가되는 `delete`만 정의한다. 다른 repository는 변경 없음.

---

## 1. `ItemRepository` (추가 시그니처)

```dart
abstract interface class ItemRepository {
  // ... 001의 기존 메서드(watchAll, watchFiltered, watchRecentlyWorn,
  //     watchStats, get, create) 유지 ...

  // ── 쓰기 (002 추가) ──
  /// FR-001~006. 명칭 검증 실패 시 [ArgumentError]. `id` 미존재 시 no-op.
  /// 저장 후 status를 wearSinceWash/washCycle 기준으로 재평가한다(FR-004).
  Future<void> update(int id, ItemPatch patch);

  /// FR-008~012. 대상 Item + 연관 WearEvent 전량을 단일 트랜잭션으로 제거.
  /// sandbox 이미지 파일은 best-effort 삭제. `id` 미존재 시 no-op.
  Future<void> delete(int id);
}
```

### `update` 사이드이펙트 (FR-002 → FR-005)

```text
input: id, patch(ItemPatch)

precondition: patch.name.trim().isNotEmpty  (아니면 ArgumentError)

txn {
  item = items.get(id)
  if item == null: return                  # 미존재 no-op
  item.name       = patch.name.trim()
  item.brand      = patch.brand?.trim().isEmpty ? null : patch.brand.trim()
  item.category   = patch.category
  item.careMethod = patch.careMethod
  item.washCycle  = patch.washCycle <= 0 ? 1 : patch.washCycle
  item.purchasedAt= patch.purchasedAt

  # 사진 의도 (data-model.md §3)
  if patch.newPhoto != null:
      item.imagePath = imageStore.copyTo(patch.newPhoto, '$id')  # 교체
  else if patch.removePhoto:
      oldPath = item.imagePath
      item.imagePath = null                # 파일 삭제는 txn 밖 best-effort
  # else: imagePath 유지

  # status 재평가 (FR-004)
  item.status = item.wearSinceWash >= item.washCycle
      ? ItemStatus.dirty : ItemStatus.clean

  items.put(item)
}
# txn 밖: removePhoto였다면 imageStore.delete(oldPath) best-effort
```

**보존 필드**: `wearSinceWash`, `totalWears`, `lastWornAt`, `lastWashedAt`, `inLaundry`,
`createdAt`, `fallbackColor`는 update가 변경하지 않는다.

### `delete` 사이드이펙트 (FR-010 → FR-011)

```text
input: id

txn {
  item = items.get(id)
  if item == null: return                  # 미존재 no-op
  imagePath = item.imagePath               # txn 밖 파일 삭제용으로 보관

  # 연관 WearEvent 전량 제거 (kind 무관) — orphan 방지(SC-004)
  eventIds = wearEvents.filter().itemIdEqualTo(id).idProperty().findAll()
  wearEvents.deleteAll(eventIds)

  items.delete(id)
}
# txn 밖: imagePath != null이면 imageStore.delete(imagePath) best-effort
```

전체 DB 변경은 단일 `isar.writeTxn`으로 원자성 보장. 이미지 파일 삭제 실패는 무시한다(FR-011).

---

## 2. `ImageStore` (추가 메서드)

```dart
class ImageStore {
  // ... copyTo, absolutePath 유지 ...

  /// 상대 경로(`items/{id}.jpg`)의 sandbox 파일을 삭제한다.
  /// 파일이 없거나 삭제 실패 시 예외를 던지지 않고 조용히 무시한다(best-effort).
  Future<void> delete(String relativePath);
}
```

---

## 3. 공통 규약 (001 §5 상속)

- UI(features/*)는 repository 인터페이스만 호출한다. Isar API 직접 사용 금지.
- 시각 도메인은 `Clock` provider 주입(update는 시각을 기록하지 않으므로 clock 미사용, delete도 동일).
- 메서드 시그니처 변경은 본 문서 갱신을 동반한다.

---

**Status**: `ItemRepository.update/delete` + `ImageStore.delete` 계약 확정.
