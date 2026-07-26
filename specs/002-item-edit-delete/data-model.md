# Data Model: 옷 정보 수정 & 삭제 (delta)

**Feature**: 002-item-edit-delete | **Date**: 2026-07-04

001-home-dashboard/data-model.md의 스키마를 그대로 상속한다. 본 feature는 **Isar 컬렉션
스키마를 변경하지 않는다** — 필드 추가·삭제·인덱스 변경이 없으므로 마이그레이션 불필요.

## 1. `Item` (무변경)

001 §1과 동일한 16개 필드. 본 feature의 영향:

- **수정(update)**: `name`, `brand`, `category`, `careMethod`, `washCycle`, `purchasedAt`,
  `imagePath`, `fallbackColor`(사진 제거 시 유지) 값만 변경한다. 파생 필드(`wearSinceWash`,
  `totalWears`, `lastWornAt`, `lastWashedAt`, `inLaundry`, `createdAt`)는 update가 건드리지 않는다.
- **`status` 재평가**: update 저장 시 `status = wearSinceWash >= washCycle ? dirty : clean`.
- **삭제(delete)**: row 자체를 제거.

### 상태 전이 (002 추가분)

| 트리거 | 조건 | 결과 |
|---|---|---|
| `update` 저장 | `wearSinceWash >= washCycle` | `status → dirty` |
| `update` 저장 | `wearSinceWash < washCycle` | `status → clean` |
| `delete` | (항상) | Item row 제거 + 연관 WearEvent 전량 제거 |

## 2. `WearEvent` (무변경)

001 §2와 동일. 본 feature의 영향:

- **삭제 cascade**: `Item` 삭제 시 같은 `itemId`를 가진 모든 `WearEvent`(kind=wear·wash 무관)를
  함께 제거한다. 001의 `deleteWearEvent`(단건, wear 한정, 사이드이펙트 역적용)와는 별개 경로다 —
  Item 자체가 사라지므로 카운터 역적용은 무의미하고, 전량 삭제만 수행한다.

## 3. `ItemPatch` (신규 — 영속화 대상 아님)

수정 폼이 `ItemRepository.update`에 전달하는 in-memory 값 객체. Isar 컬렉션이 **아니다**.

```dart
@freezed
class ItemPatch with _$ItemPatch {
  const factory ItemPatch({
    required String name,          // trim 후 비어 있으면 update가 ArgumentError
    String? brand,                 // 빈 문자열은 null로 정규화
    required Category category,
    required CareMethod careMethod,
    required int washCycle,        // <=0이면 1로 가드
    DateTime? purchasedAt,
    File? newPhoto,                // 새로 선택한 사진(있으면 sandbox 교체)
    @Default(false) bool removePhoto,  // true면 기존 사진 제거 → imagePath=null
  }) = _ItemPatch;
}
```

### 사진 의도 해석 (update 구현)

| `newPhoto` | `removePhoto` | 동작 |
|---|---|---|
| `!= null` | (무시) | sandbox에 복사·교체 후 `imagePath` 갱신 |
| `null` | `true` | 기존 파일 삭제 + `imagePath = null` |
| `null` | `false` | `imagePath` 유지(변경 없음) |

## 4. 검증 규칙 (update)

| 필드 | 규칙 | 위반 시 |
|---|---|---|
| `name` | `trim().isNotEmpty` | `ArgumentError` (create와 동일) |
| `washCycle` | `>= 1` (`<=0`이면 1로 클램프) | 클램프 |
| `brand` | `trim().isEmpty`이면 `null` | 정규화 |
| `id` | 존재하는 Item | 미존재 시 no-op(조용히 무시) |

---

**Status**: 스키마 무변경 확인. `ItemPatch`는 `lib/data/models/item_patch.dart`에 freezed로 생성.
