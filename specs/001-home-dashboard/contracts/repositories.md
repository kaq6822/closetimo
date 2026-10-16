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
  Stream<List<Item>> watchAll();                                // 보관 포함 전체(raw). 화면은 watchFiltered 사용
  Stream<List<Item>> watchFiltered({
    ItemFilter filter = const ItemFilter(),                     // 종류·용도·검색어·보관 FR-005·006, #37·#41·#44
    required WardrobeSort sort,                                 // FR-007
  });
  Stream<List<Item>> watchRecentlyWorn({int limit = 2});        // FR-020 (보관 제외, #44)

  Future<Item?> get(int id);                                    // 옷 상세 진입

  Stream<WardrobeStats> watchStats();                           // FR-018, FR-019 (보관 제외, #44)

  // ── 쓰기 ──
  Future<int> create(NewItemDraft draft);                       // FR-001 → FR-004
  Future<void> update(int id, ItemPatch patch);                 // 002. careMode·purposes 포함 전체 교체
  Future<void> delete(int id);                                  // 002
}

class WardrobeStats {
  final int total;
  final int clean;
  final int dirty;
  final Map<HomeBucket, int> perBucket;  // 홈 2x2 카드(FR-019, #37). 모든 버킷 키 보유, 합 = total.
}                                        // others('그 외') = 아우터·상의·하의 외 전체(미분류 포함).

class ItemFilter {                        // lib/data/models/item_filter.dart (영속화 X)
  final Set<Category> categories;        // 비면 전체. 축 안 OR
  final Set<ItemPurpose> purposes;       // 비면 전체. 축 안 OR, 축 간 AND
  final String query;                    // 이름·브랜드·태그(#46), 대소문자 무시
  final ArchiveScope archive;            // #44. active(기본) | archived | all
  final bool readyToWear;                // #43 '입을 수 있음' = status==clean && !inLaundry (축 간 AND)
  final Set<String> tags;                // #46 사용자 태그. 비면 전체. 축 안 OR(하나라도 붙음), 축 간 AND
  factory ItemFilter.category(Category c);        // 개별 종류(옷장 칩)
  factory ItemFilter.homeBucket(HomeBucket b);    // 홈 카드와 같은 범위
  bool matches(Item item);
}

enum WardrobeSort { statusCleanFirst, recentlyWorn, mostWorn }
```

### 검증 / 사이드이펙트

- `create`: `draft.name.trim().isEmpty`이면 `ArgumentError`. 검증 통과 시 `imagePath`는 `ImageStore.copy(draft.tempPhoto)` 결과를 저장. 생성 시 `Item` 기본값(`status=clean`, counts=0, `createdAt=now`).
- `create`: draft의 `category`(기본 미분류)·`careMethod`(기본 미지정)·`careMode`·`purposes`를 저장한다. `purposes`는 중복 제거 후 enum 순서로 정규화.
- `update`: `ItemPatch`의 편집 필드 전체(`careMode`·`purposes` 포함, 둘 다 required)를 교체하고 `status = item.derivedStatus`로 재평가한다(#45).
- `create`·`update`의 태그(#46): `draft.tags`(기본 빈 목록)·`patch.tags`를 `normalizeTags`로 정규화해 저장한다.
  `patch.tags == null`이면 기존 태그를 유지하고, 빈 목록이면 모두 제거한다.
- `watchFiltered`: `filter.matches(item)`을 만족하는 옷만 내보낸다. 검색 매칭은 `name.toLowerCase().contains(q) || (brand ?? '').toLowerCase().contains(q) || tags.any((t) => t.toLowerCase().contains(q))` (FR-006, #46).
- `watchStats().perBucket[b]`와 `watchFiltered(filter: ItemFilter.homeBucket(b))`의 결과 수는 항상 같다(#37). 둘 다 보관한 옷을 제외한다(#44).
- `watchStats`·`watchRecentlyWorn`은 보관한 옷(`archivedAt != null`)을 제외한다(#44, data-model.md §1.2a).

---

## 2. `LaundryRepository`

세탁 바구니 토글 및 일괄 세탁 완료.

```dart
abstract interface class LaundryRepository {
  Stream<List<Item>> watchBasket();                  // FR-014 (inLaundry == true)
  Future<void> toggle(int itemId);                   // FR-012 (관리 방식과 무관, #45)
  Future<int> completeWashFor(List<int> itemIds);    // FR-016, 처리된 수 반환
}
```

### 사이드이펙트

- `watchBasket`: `inLaundry == true`이고 보관하지 않은(`archivedAt == null`) 옷(#44).
- `toggle`: `Item.inLaundry`를 반전. 상태 전이 없음(FR-012 명시). 보관한 옷을 담으려는 호출은 무시한다(#44).
- `completeWashFor`:
  0. `inLaundry == true`가 아닌(또는 존재하지 않는) `itemId`는 건너뛰고, 실제 처리한 수를 반환한다(토스트 표시용).
  1. 각 `itemId`의 Item을 `status=clean, wearSinceWash=0, lastWashedAt=now, inLaundry=false`로 갱신(FR-016).
  2. 각 Item에 대해 `WearEvent(kind: wash, occurredAt: now)` 1건 추가(FR-013 타임라인 보강).
  3. 모두 단일 `isar.write`로 묶어 원자성 보장.

---

## 2a. `ArchiveRepository` (#44)

옷 보관·복원. `LaundryRepository`가 `Item.inLaundry`를 다루듯 `Item.archivedAt`·`archiveReason`을 다룬다.
`ItemRepository`와 분리해 기존 구현·테스트 대역에 영향을 주지 않는다.

```dart
abstract interface class ArchiveRepository {
  Stream<List<Item>> watchArchived();                                       // 보관함, archivedAt 내림차순
  Future<void> archive(int itemId, {ArchiveReason reason = ArchiveReason.unspecified});
  Future<void> restore(int itemId);
}
```

### 사이드이펙트

- `archive`: 단일 `isar.write`로 `archivedAt = now`(이미 보관 중이면 유지), `archiveReason = reason`, `inLaundry = false`.
  WearEvent·카운터·`status`·사진은 그대로 둔다. 미존재 `itemId`는 no-op.
- `restore`: `archivedAt = null`, `archiveReason = unspecified`. 기록·카운터·상태 보존, 바구니 자동 재담기 없음. 미존재·활성 옷은 no-op.
- 연관 규칙: `LaundryRepository.watchBasket`은 보관한 옷을 내보내지 않고, `toggle`은 보관한 옷을 바구니에 **담는** 호출을 무시한다.
- 삭제(`ItemRepository.delete`)와의 차이: 삭제는 기록까지 제거하고 되돌릴 수 없으며, 보관은 기록을 유지하고 복원할 수 있다.

## 2b. `TagRepository` (#46)

사용자 태그(`Item.tags`)를 여러 옷에 걸쳐 바꾸는 **쓰기 전용** 인터페이스다. `ItemRepository`와 분리해
기존 구현·테스트 대역에 영향을 주지 않는다. 읽기(태그 목록·사용 수)는 별도 쿼리 없이
`ItemRepository.watchAll()`을 `summarizeTags`(`lib/data/models/item_tags.dart`)로 집계한다
(`tagUsageProvider`).

```dart
abstract interface class TagRepository {
  Future<int> addTag(Set<int> itemIds, String tag);    // 일괄 붙이기. 바뀐 옷 수
  Future<int> removeTag(Set<int> itemIds, String tag); // 일괄 떼기. 바뀐 옷 수
  Future<int> renameTag(String from, String to);       // 전체(보관 포함) 이름 변경 = 같은 이름이 있으면 병합
  Future<int> deleteTag(String tag);                   // 전체(보관 포함)에서 태그만 제거
}

class TagUsage { String name; int itemCount /* 보관 포함 */; int activeItemCount /* 보관 제외 */; }
List<TagUsage> summarizeTags(Iterable<Item> items);   // 많이 쓴 순, 같으면 이름순
```

### 정규화 (`normalizeTag` / `normalizeTags`)

- 앞뒤 공백 제거, 연속 공백 1개로, 쉼표 → 공백(쉼표는 입력·라우트 쿼리 구분자), 최대 20자. 빈 값은 버린다.
- 한 옷 안에서 대소문자만 다른 중복은 먼저 나온 표기만 남긴다. 순서는 입력 순서를 유지한다.

### 사이드이펙트

- 모든 메서드는 단일 `isar.write`에서 실제로 태그가 바뀐 옷만 `putAll`한다. 바뀐 옷 수를 돌려준다.
- `addTag`: 정규화 후 빈 태그면 `ArgumentError`. 이미 같은 태그(대소문자 무시)가 있으면 그대로. 미존재 id 무시.
- `renameTag(from, to)`: `from`을 원래 자리에서 `to`로 바꾸고, 이미 `to`가 있던 옷은 하나로 합친다(중복 병합).
  `to`가 비면 `ArgumentError`, `from == to`면 no-op.
- `deleteTag`·`removeTag`·`renameTag`는 **옷·사진·WearEvent를 지우지 않고** 카운터·`status`·`inLaundry`·보관 필드를
  바꾸지 않는다. 관리 상태·바구니·보관은 태그가 아니라 시스템 필드다.

---

## 3. `EventRepository`

착용·세탁 이벤트 기록 및 조회.

```dart
abstract interface class EventRepository {
  Stream<List<WearEvent>> watchForItem(int itemId);                 // FR-013
  Future<int?> recordWear(int itemId, {String? note, DateTime? wornOn}); // FR-010·010d → 생성된 이벤트 id
  Future<WearBatchResult> recordWearBatch(Iterable<int> itemIds,
      {DateTime? wornOn, String? note});                                // FR-008c (#39) 일괄 기록
  Future<void> updateEventNote(int eventId, String? note);          // FR-010a (wear 이벤트 한정)
  Future<void> updateWearDate(int eventId, DateTime wornOn);        // FR-010c (#39) 날짜 수정
  Future<void> deleteWearEvent(int eventId);                        // FR-010b (사이드이펙트 역적용)
  Future<void> deleteWearEvents(Iterable<int> eventIds);            // FR-010e (#39) 실행 취소
}

class WearBatchResult {
  final List<int> eventIds;   // 생성된 wear 이벤트 id(실행 취소용), 입력 순서
  final int skipped;          // 중복 id·보관·미존재로 제외한 수
  int get recorded => eventIds.length;
}
```

### 착용 날짜 규칙 (FR-010d, #39)

`wornOn`은 달력 날짜이며 시각 부분은 무시한다. `null`이면 오늘이다.

```text
occurredAt(wornOn) =
  wornOn이 오늘   → now
  wornOn이 과거   → DateTime(wornOn.y, wornOn.m, wornOn.d, 12)
  wornOn이 미래   → ArgumentError
inCurrentCycle(at, id) = lastWash == null
                         or at > lastWash.occurredAt
                         or (at == lastWash.occurredAt and id > lastWash.id)
```

### `recordWear` 사이드이펙트 (FR-010 → FR-011)

```text
input: itemId, note (단일행, 빈 입력은 null로 정규화, 길이 검증은 UI에서 80자 한도 보장), wornOn (FR-010d)

txn {
  item = items.get(itemId)
  if item == null: return null
  at = occurredAt(wornOn)
  ev = WearEvent(itemId, kind: wear, occurredAt: at, note: note)   # id 할당
  if inCurrentCycle(at, ev.id): item.wearSinceWash += 1  # 세탁 이전 날짜면 유지(FR-010d)
  item.totalWears    += 1
  item.lastWornAt     = max(item.lastWornAt, at)
  item.status         = item.derivedStatus  # FR-011 (manual이면 항상 clean, #45)
  items.put(item); events.put(ev)
  return ev.id
}
```

### `recordWearBatch` 사이드이펙트 (FR-008c, #39)

단일 `isar.write`로 `itemIds`를 입력 순서대로 처리한다. 이미 처리한 id(중복)·존재하지 않는 옷·보관한
옷(`archivedAt != null`)은 건너뛰고 `skipped`에 센다. 나머지 각 옷에 `recordWear`와 같은 규칙으로
같은 `occurredAt`·`note`의 wear 이벤트 1건을 만든다. note 검증 실패(ArgumentError)·미래 날짜는
트랜잭션 전에 거부하므로 일부만 저장되는 경우가 없다.

### `updateWearDate` 사이드이펙트 (FR-010c, #39)

```text
txn {
  ev = events.get(eventId); if null: return
  assert ev.kind == wear                    # wash는 StateError
  at = occurredAt(wornOn)
  if 같은 달력 날짜(ev.occurredAt, at): return     # no-op
  wasIn = inCurrentCycle(ev.occurredAt, ev.id)
  ev.occurredAt = at; events.put(ev)
  nowIn = inCurrentCycle(at, ev.id)
  item.wearSinceWash += (nowIn ? 1 : 0) - (wasIn ? 1 : 0)   # 0 미만 불가
  item.lastWornAt = 남은 wear 이벤트 최신 occurredAt
  item.status = item.derivedStatus          # totalWears·inLaundry 유지
}
```

### `deleteWearEvents` 사이드이펙트 (FR-010e, #39)

`eventIds` 각각에 `deleteWearEvent`와 같은 역적용을 **단일** `isar.write`에서 순서대로 수행한다.
없는 id·wash 이벤트 id는 건너뛴다(실행 취소가 이미 지운 기록 때문에 실패하지 않도록). 착용 기록
직후 토스트의 "실행 취소"가 호출한다.

UI 흐름: 상세 화면의 "착용 기록하기" 버튼을 누르면 가벼운 바텀시트가 떠 메모 입력란을 노출한다(단일행, 최대 80자, 빈 입력 허용). 시트는 착용 날짜(오늘·어제·날짜 선택)도 받는다(#39). 시트의 "기록" 액션이 `recordWear(itemId, note: ..., wornOn: ...)`를 호출하고, 성공 후 `Toast("오늘의 착용이 기록되었어요", action: 실행 취소 → deleteWearEvents([id]))`(오늘이 아니면 "어제의 착용"·"M/d의 착용")를 띄운다(US3 AC1·AC2, FR-010e). 호출 측에서 `note?.length`가 80자를 넘으면 ArgumentError를 throw해야 한다(UI 가드 회귀 방어).

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
  # 현재 주기 = 가장 최근 wash 이벤트 이후 wear (같은 occurredAt이면 id가 큰 쪽이 이후).
  # wash 이벤트가 없으면(카운터만 있는 기존 데이터 포함) 전부 현재 주기.
  lastWash = events.where().itemIdEqualTo(itemId).filter().kindEqualTo(wash)의 최신 (occurredAt, id)
  if lastWash == null or (ev.occurredAt, ev.id) > (lastWash.occurredAt, lastWash.id):
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
  item.status = item.derivedStatus

  items.put(item)
}
```

전체 동작은 단일 `isar.write`로 묶어 원자성을 보장한다. UI 흐름: 타임라인 wear 항목 long-press → "기록 삭제" → 확인 다이얼로그 → `deleteWearEvent`. 호출 후 `Toast("착용 기록을 삭제했어요")`. `inLaundry`는 변경하지 않는다(FR-010b, Edge Case "사용자 토글 전까지 유지").

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

## 4a. `BackupRepository` (#40)

사용자 실행형 백업·복원. 계약·예외·원자성 규칙은
[004 contracts/backup-service.md](../../004-backup-restore/contracts/backup-service.md)를 따른다.

```dart
abstract interface class BackupRepository {
  Future<BackupCounts> currentCounts();
  Future<BackupExport> createBackup(Directory outputDir);
  Future<ValidatedBackup> inspect(File archive);      // 검증만, 무변경
  Future<RestoreResult> restore(ValidatedBackup b);   // 전체 교체, 실패 시 무변경
}
```

`ItemRepository.update`는 새 사진으로 교체할 때 이전 `imagePath`가 새 경로와 다르면(복원된 사진
`items/{id}_r{token}.jpg` 등) 이전 파일을 best-effort로 지운다.

---

## 5. 공통 규약

- 모든 `watch*` 메서드는 Isar `watchLazy()` 또는 컬렉션 `watch(fireImmediately: true)`를 변환한 Stream.
- 모든 `Future<void>` 변경 메서드는 실패 시 `Exception`을 throw(UI 레이어가 토스트로 처리).
- 시각 도메인은 `DateTime.now()`를 직접 호출하지 않고 `Clock` Provider를 주입받아 테스트에서 가짜 시계 사용.
- 메서드 시그니처 변경은 본 문서 갱신을 동반해야 한다. PR 리뷰어는 본 문서와 코드 일치성을 확인.

---

**Status**: Repository 계약 확정. UI 계층은 본 인터페이스만 의존.
