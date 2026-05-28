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
  Stream<List<WearEvent>> watchForItem(int itemId);                 // FR-013
  Future<void> recordWear(int itemId, {String? note});              // FR-010 → 카운터 갱신 + note 저장
  Future<void> updateEventNote(int eventId, String? note);          // FR-010a (wear 이벤트 한정)
  Future<void> deleteWearEvent(int eventId);                        // FR-010b (사이드이펙트 역적용)
}
```

### `recordWear` 사이드이펙트 (FR-010 → FR-011)

```text
input: itemId, note (단일행, 빈 입력은 null로 정규화, 길이 검증은 UI에서 80자 한도 보장)

txn {
  item = items.get(itemId)
  item.wearSinceWash += 1
  item.totalWears    += 1
  item.lastWornAt     = now
  if item.wearSinceWash >= item.washCycle:
      item.status = dirty                    # FR-011 자동 전이
  items.put(item)
  events.put(WearEvent(itemId, kind: wear, occurredAt: now, note: note))
}
```

UI 흐름: 상세 화면의 "착용 기록하기" 버튼을 누르면 가벼운 바텀시트가 떠 메모 입력란을 노출한다(단일행, 최대 80자, 빈 입력 허용). 시트의 "기록" 액션이 `recordWear(itemId, note: ...)`를 호출하고, 성공 후 `Toast("오늘의 착용이 기록되었어요")` + 직전 화면으로 pop(US3 AC1·AC2). 호출 측에서 `note?.length`가 80자를 넘으면 ArgumentError를 throw해야 한다(UI 가드 회귀 방어).

### `updateEventNote` 사이드이펙트 (FR-010a)

```text
input: eventId, note (null 또는 ≤80자)

txn {
  ev = events.get(eventId)
  assert ev != null
  assert ev.kind == wear                    # wash 이벤트는 본 메서드 적용 대상 외(FR-010a)
  ev.note = note
  events.put(ev)
}
```

`Item`의 카운터·상태·날짜는 변경되지 않는다(메모 본문만 갱신). UI 흐름: 타임라인 wear 항목 long-press → "메모 편집" → 별도 시트 → 저장.

### `deleteWearEvent` 사이드이펙트 (FR-010b)

```text
input: eventId

txn {
  ev = events.get(eventId)
  assert ev != null
  assert ev.kind == wear                    # wash 이벤트 삭제는 본 메서드 범위 외
  itemId = ev.itemId
  events.delete(eventId)

  item = items.get(itemId)
  item.wearSinceWash = max(0, item.wearSinceWash - 1)
  item.totalWears    = max(0, item.totalWears - 1)
  # lastWornAt 재계산: 같은 itemId의 남은 wear 이벤트 중 최신 occurredAt, 없으면 null
  remaining = events
    .where()
    .itemIdEqualTo(itemId)
    .filter().kindEqualTo(wear)
    .sortByOccurredAtDesc()
    .findFirst()
  item.lastWornAt = remaining?.occurredAt

  # dirty → clean 자동 복귀 (FR-011 역방향)
  if item.status == dirty and item.wearSinceWash < item.washCycle:
      item.status = clean

  items.put(item)
}
```

전체 동작은 단일 `isar.writeTxnSync`로 묶어 원자성을 보장한다. UI 흐름: 타임라인 wear 항목 long-press → "기록 삭제" → 확인 다이얼로그 → `deleteWearEvent`. 호출 후 `Toast("착용 기록을 삭제했어요")`. `inLaundry`는 변경하지 않는다(FR-010b, Edge Case "사용자 토글 전까지 유지").

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
