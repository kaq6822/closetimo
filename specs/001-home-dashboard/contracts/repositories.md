# Contract: Repository Interfaces

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 데이터 접근 계층의 공개 인터페이스를 정의한다. UI(features/*)는 본 인터페이스만 호출해야 하며, Isar API를 직접 사용해서는 안 된다. 모든 구현은 `lib/data/repositories/`에 위치하고 Riverpod provider로 노출된다.

각 메서드는 spec.md의 FR-NNN과 1:1 매핑된다.

---

## 1. `ItemRepository`

옷의 CRUD 및 옷장 탐색 쿼리.

```dart
abstract interface class ItemRepository {
  // ── 읽기(Watch는 Riverpod stream으로 변환) ──
  Stream<List<Item>> watchAll();                                // FR-005 기반
  Stream<List<Item>> watchByCategory(Category? c);              // FR-005
  Stream<List<Item>> watchFiltered({
    Category? category,
    String? query,                                              // 이름·브랜드 검색 FR-006
    WardrobeSort sort,                                          // FR-007
  });
  Stream<List<Item>> watchRecentlyWorn({int limit = 2});        // FR-020

  Future<Item?> get(int id);                                    // 옷 상세 진입

  Stream<WardrobeStats> watchStats();                           // FR-018, FR-019

  // ── 쓰기 ──
  Future<int> create(NewItemDraft draft);                       // FR-001 → FR-004
  Future<void> update(int id, ItemPatch patch);                 // (수정 화면용; v1 spec엔 명시 없음)
}

class WardrobeStats {
  final int total;
  final int clean;
  final int dirty;
  final Map<Category, int> perCategory;  // 홈 2x2 카드(FR-019). "기타"는 신발/가방/액세서리/원피스/운동복 합산.
}

enum WardrobeSort { statusCleanFirst, recentlyWorn, mostWorn }
```

### 검증 / 사이드이펙트

- `create`: `draft.name.trim().isEmpty`이면 `ArgumentError`. 검증 통과 시 `imagePath`는 `ImageStore.copy(draft.tempPhoto)` 결과를 저장. 생성 시 `Item` 기본값(`status=clean`, counts=0, `createdAt=now`).
- `watchFiltered`의 검색 매칭: `(name ?? '').toLowerCase().contains(q.toLowerCase()) || (brand ?? '').toLowerCase().contains(q.toLowerCase())` (FR-006).

---

## 2. `LaundryRepository`

세탁 바구니 토글 및 일괄 세탁 완료.

```dart
abstract interface class LaundryRepository {
  Stream<List<Item>> watchBasket();                  // FR-014 (inLaundry == true)
  Future<void> toggle(int itemId);                   // FR-012
  Future<void> completeWashFor(List<int> itemIds);   // FR-016
}
```

### 사이드이펙트

- `toggle`: `Item.inLaundry`를 반전. 상태 전이 없음(FR-012 명시).
- `completeWashFor`:
  1. 각 `itemId`의 Item을 `status=clean, wearSinceWash=0, lastWashedAt=now, inLaundry=false`로 갱신(FR-016).
  2. 각 Item에 대해 `WearEvent(kind: wash, occurredAt: now)` 1건 추가(FR-013 타임라인 보강).
  3. 모두 단일 `isar.writeTxnSync`로 묶어 원자성 보장.

---

## 3. `EventRepository`

착용·세탁 이벤트 기록 및 조회.

```dart
abstract interface class EventRepository {
  Stream<List<WearEvent>> watchForItem(int itemId);  // FR-013
  Future<void> recordWear(int itemId);               // FR-010 → 카운터 갱신 포함
}
```

### `recordWear` 사이드이펙트 (FR-010 → FR-011)

```text
txn {
  item = items.get(itemId)
  item.wearSinceWash += 1
  item.totalWears    += 1
  item.lastWornAt     = now
  if item.wearSinceWash >= item.washCycle:
      item.status = dirty                    # FR-011 자동 전이
  items.put(item)
  events.put(WearEvent(itemId, kind: wear, occurredAt: now))
}
```

호출 후 UI에서 `Toast("오늘의 착용이 기록되었어요")` + 직전 화면으로 pop(US3 AC1).

---

## 4. `PreferencesRepository`

설정 토글 / 마지막 탭 / 액센트.

```dart
abstract interface class PreferencesRepository {
  Stream<UserPreferences> watch();
  Future<void> setNotifWash(bool v);
  Future<void> setNotifWeekly(bool v);
  Future<void> setNotifUnworn(bool v);
  Future<void> setAccent(String accentKey);
  Future<void> setLastTab(String tab);                // FR-022
}
```

행이 없을 경우 부트 시 기본값으로 생성(`UserPreferences.defaults()`).

---

## 5. 공통 규약

- 모든 `watch*` 메서드는 Isar `watchLazy()` 또는 컬렉션 `watch(fireImmediately: true)`를 변환한 Stream.
- 모든 `Future<void>` 변경 메서드는 실패 시 `Exception`을 throw(UI 레이어가 토스트로 처리).
- 시각 도메인은 `DateTime.now()`를 직접 호출하지 않고 `Clock` Provider를 주입받아 테스트에서 가짜 시계 사용.
- 메서드 시그니처 변경은 본 문서 갱신을 동반해야 한다. PR 리뷰어는 본 문서와 코드 일치성을 확인.

---

**Status**: Repository 계약 확정. UI 계층은 본 인터페이스만 의존.
