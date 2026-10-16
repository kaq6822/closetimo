# Data Model: 옷장이모 MVP

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 Isar 컬렉션 스키마(소스 코드의 `lib/data/models/`에 대응)와 엔티티 간 관계, 검증 규칙, 상태 전이를 정의한다. 모든 필드는 spec.md의 Key Entities + FR-001~FR-022에서 도출된다.

**구현 버전 (업데이트)**: 본 문서는 최초 설계 시점의 **Isar 3.x** API를 기준으로
작성된 **설계 기록**이다. 현재 구현의 주 저장소는 **Isar Plus 1.3.7**
(`isar_plus` + `isar_plus_flutter_libs`)이며 iOS는 SwiftPM 경로를 사용한다.
구형 Isar 3 저장소(`closetimo.isar`)는 읽기 전용 legacy 브리지로 남아 있어
첫 실행 시 한 번 `closetimo_plus.isar`로 이전된다(원본은 보존).

따라서 아래의 `@collection`·`@Index`·`Id` 서술은 **현재 스키마 기준으로는
Isar Plus 1.3.x를 따르고, Isar 3.x는 설계 당시 표기**라는 점을 함께 읽어야 한다.
필드·인덱스·전이 규칙 자체는 현재 구현과 동일하며, 저장소 엔진 차이에 따른
스키마 변경은 없다. 이전 정책과 검증 기록은
[003 quickstart](../003-migrate-isar-spm/quickstart.md)를 따른다.

---

## ER 다이어그램 (논리)

```text
┌─────────────────────────────┐        1     N  ┌──────────────────────────┐
│           Item              │◀────────────────│       WearEvent          │
│  (옷 1점)                    │                  │  (착용/세탁 이벤트 로그)  │
│  • id (auto)                │                  │  • id (auto)             │
│  • name                     │                  │  • itemId (FK)           │
│  • brand                    │                  │  • kind: wear | wash    │
│  • category (enum)          │                  │  • occurredAt: DateTime  │
│  • careMethod (enum)        │                  │  • note: String?         │
│  • status: clean | dirty   │                  └──────────────────────────┘
│  • washCycle (int ≥ 1)      │
│  • wearSinceWash (int ≥ 0)  │
│  • totalWears (int ≥ 0)     │
│  • lastWornAt: DateTime?    │
│  • lastWashedAt: DateTime?  │
│  • purchasedAt: DateTime?   │
│  • inLaundry: bool          │  ← spec의 LaundryBasket = items where inLaundry == true
│  • imagePath: String?       │  (앱 sandbox 기준 상대 경로)
│  • fallbackColor: int       │  (Color.value, 이미지 없을 때)
│  • createdAt: DateTime      │
│  • careMode (enum, v2)      │  (wearCycle | manual)
│  • purposes (List, v2)      │  (용도 축, 0개 이상)
│  • archivedAt: DateTime?    │  (보관 시각, null = 활성, #44)
│  • archiveReason (enum)     │  (unspecified | seasonal | noLongerOwned, #44)
└─────────────────────────────┘

┌──────────────────────────────────┐
│      UserPreferences             │   single-row 컬렉션 (id = 0)
│  • notifWash: bool               │
│  • notifWeekly: bool             │
│  • notifUnworn: bool             │
│  • accent: String (sage 기본)    │
│  • lastTab: String? (home...)    │
└──────────────────────────────────┘
```

---

## 1. `Item` 컬렉션

Isar `@collection`. 옷장의 단일 옷.

| 필드 | Dart 타입 | 인덱스 | 제약 | 출처 |
|---|---|---|---|---|
| `id` | `Id` (int auto) | PK | — | Isar 자동 |
| `name` | `String` | — | `name.isNotEmpty` (FR-002) | FR-001 |
| `brand` | `String?` | — | nullable | FR-001 |
| `category` | `Category` (enum, 종류) | `@Index()` | not null, 새 옷 기본 `uncategorized` | FR-001, #41 |
| `careMethod` | `CareMethod` (enum) | — | not null, 새 옷 기본 `unspecified` | FR-001, #45 |
| `status` | `ItemStatus` (enum) | `@Index()` | `clean` 기본 | FR-008/011 |
| `washCycle` | `int` | — | `>= 1` (FR-001). `careMode = manual`이어도 값 보존 | FR-001 |
| `wearSinceWash` | `int` | — | `>= 0` | FR-010 |
| `totalWears` | `int` | — | `>= 0` | FR-010 |
| `lastWornAt` | `DateTime?` | `@Index(type: IndexType.value)` | nullable | FR-010, FR-007(정렬) |
| `lastWashedAt` | `DateTime?` | — | nullable | FR-009 |
| `purchasedAt` | `DateTime?` | — | nullable | FR-001 |
| `inLaundry` | `bool` | `@Index()` | 기본 false | FR-012, FR-014 |
| `imagePath` | `String?` | — | nullable (FR-003 → 플레이스홀더) | FR-001 |
| `fallbackColor` | `int` | — | 기본 0xFFE5E4DC | UI 폴백 |
| `createdAt` | `DateTime` | — | 등록 시각 | FR-004(최신 우선) |
| `careMode` | `CareMode` (enum) | — | 기본 `wearCycle`. 필드가 없던 v1 데이터도 `wearCycle`로 읽힘 | FR-011, #45 |
| `purposes` | `List<ItemPurpose>` | — | 0개 이상, 중복 없음·enum 순서로 정규화 | #41 |
| `archivedAt` | `DateTime?` | — | null = 활성. null이 아니면 보관 상태(보관 여부의 단일 진실 원천) | #44 |
| `archiveReason` | `ArchiveReason` (enum) | — | 기본 `unspecified`. 보관하지 않았거나 사유를 고르지 않으면 `unspecified` (Isar Plus는 nullable enum 미지원) | #44 |

> **property 순서 규칙**: Isar Plus는 필드 선언 순서로 property index를 부여한다.
> 새 필드는 항상 클래스 **끝**에 추가해 기존 필드 위치를 바꾸지 않는다(`careMode`·`purposes`는 v2에서, `archivedAt`·`archiveReason`은 #44에서 끝에 추가).

### 1.1 Enum 정의

Isar Plus는 enum을 **ordinal(index)** 로 저장한다. 값의 순서를 바꾸거나 중간에 삽입·삭제하지
않고 **끝에만 추가**한다. index는 `test/unit/item_classification_test.dart`가 고정 검증한다.

```dart
enum Category {            // 종류
  outer,        // 0 아우터
  top,          // 1 상의
  bottom,       // 2 하의
  onepiece,     // 3 원피스
  shoes,        // 4 신발
  bag,          // 5 가방
  accessory,    // 6 액세서리
  activewear,   // 7 운동복 — legacy, 선택 불가(v2 마이그레이션 대상)
  etc,          // 8 기타
  uncategorized // 9 미분류 (v2)
}

enum ItemPurpose { sport }                                  // 용도: 운동 (v2)
enum CareMethod { dryClean, machine, handWash, unspecified } // 미지정 = 3 (v2)
enum CareMode { wearCycle, manual }                          // v2
enum ItemStatus { clean, dirty }
enum ArchiveReason { unspecified, seasonal, noLongerOwned }  // #44

// 저장하지 않는 집계 전용 값(홈 2x2 카드)
enum HomeBucket { outer, top, bottom, others }
```

### 1.1a 분류 용어 (#41 · #37)

| 용어 | 정의 | 코드 |
|---|---|---|
| **종류** | 옷을 찾는 기본 축. 옷 1점은 종류 1개를 가진다. | `Item.category` |
| **미분류** | 아직 종류를 정하지 않은 상태. 새 옷의 기본값이며 아우터 등으로 집계되지 않는다. | `Category.uncategorized` |
| **기타** (개별) | 다른 종류에 속하지 않는다고 사용자가 정한 종류. 옷장 `기타` 칩은 이 값**만** 보여준다. | `Category.etc` |
| **그 외** (합산) | 홈 4번째 카드. 아우터·상의·하의를 **제외한 모든 종류**(원피스·신발·가방·액세서리·기타·미분류, legacy 운동복)의 합. | `HomeBucket.others` |
| **용도** | 종류와 독립된 선택 축(0개 이상). 운동은 종류가 아니라 용도다. | `Item.purposes`, `ItemPurpose` |
| **운동복** (legacy) | v1까지의 종류 값. 새로 선택할 수 없고 v2 마이그레이션이 `미분류 + 용도 운동`으로 옮긴다. | `Category.activewear` |

화면별 포함 범위:

| 화면 | 사용하는 분류 | 범위 |
|---|---|---|
| 등록·수정 폼 | 종류 칩(`Category.selectable`: 미분류·아우터·상의·하의·원피스·신발·가방·액세서리·기타) + 용도 칩 | 종류 1개(기본 미분류), 용도 0개 이상 |
| 옷장 필터 | `ItemFilter` | 종류 칩 = 개별 종류 1개. 홈 '그 외'로 진입하면 합산 칩 `그 외 전체`가 선택됨. 용도 칩은 종류와 AND |
| 옷장 검색 | `ItemFilter.query` | 이름·브랜드(FR-006). 종류·용도 조건과 AND |
| 홈 카드 | `HomeBucket` | 아우터·상의·하의·그 외. 네 카드 합 = 전체 수. 카드 탭 → `ItemFilter.homeBucket(b)`로 같은 범위 |

### 1.1b 필터 계약 `ItemFilter` (영속화하지 않음)

- 필드: `categories: Set<Category>`, `purposes: Set<ItemPurpose>`, `query: String`,
  `archive: ArchiveScope`(#44, `active | archived | all`, **기본 `active`**).
- 보관 축이 기본값(`active`)이므로 별도 지정이 없는 옷장 목록·검색·홈 카드 이동은 보관한 옷을 포함하지 않는다.
- **같은 축 안은 OR, 축 사이는 AND**. 빈 집합은 해당 축을 제한하지 않는다(전체).
- `ItemFilter.homeBucket(b)` = `categories: b.categories`. 홈 집계(`Category.homeBucket`)와 같은
  정의를 공유하므로 카드 수와 이동 목록 수가 항상 같다.
- 후속 속성(색상·계절 등, #46)·사용 가능 상태(#43)는 이 객체에 축을 추가해 확장한다(보관 #44는 `archive` 축으로 추가됨).

### 1.2 상태 전이

```text
                                                    wearSinceWash + 1 >= washCycle
                                                  ┌──────────────────────────────┐
                                                  ▼                              │
clean ─────"착용 기록(FR-010)"─────► clean ─────"착용 기록"─────► dirty ─────────┘
  ▲                                                                              │
  └──"세탁 완료 처리(FR-016): wearSinceWash := 0, lastWashedAt := now"────────────┘
```

추가 규칙:
- 옷 등록 시: `status = clean`, `wearSinceWash = 0`, `totalWears = 0`, `inLaundry = false`, `createdAt = now`. 폼 기본값은 `category = uncategorized`, `careMethod = unspecified`, `careMode = wearCycle`, `washCycle = 5`, `purposes = []`.
- **상태 계산(FR-011, #45)**: `derivedStatus = (careMode == wearCycle && wearSinceWash >= washCycle) ? dirty : clean` (`ItemCareRules` 확장). `clean`은 "횟수 기준 관리 권장 없음"이며 실제 청결을 뜻하지 않는다.
- 착용 기록(FR-010): `wearSinceWash++`, `totalWears++`, `lastWornAt = now`. `careMode == wearCycle`이고 `wearSinceWash >= washCycle`이면 `status = dirty`로 전환(FR-011). `careMode == manual`이면 카운터만 늘고 상태는 바뀌지 않는다. 사용자가 시트에서 입력한 메모(`note`, ≤80자, nullable)는 함께 생성되는 wear 이벤트에만 저장되고 `Item`에는 반영되지 않는다.
- 세탁 완료(FR-016): `wearSinceWash = 0`, `status = clean`, `lastWashedAt = now`, `inLaundry = false`. 관리 방식과 무관하다.
- 착용 기록 삭제(FR-010b): 단일 트랜잭션으로 wear 이벤트 1건 삭제 + `totalWears = max(0, prev-1)`, `wearSinceWash`는 삭제된 이벤트가 현재 세탁 주기에 속할 때만 `max(0, prev-1)`(세탁 전 기록이면 유지). 현재 세탁 주기는 해당 옷의 가장 최근 `wash` 이벤트 이후에 기록된 wear 이벤트로 정의한다. 같은 `occurredAt`이면 `id`가 큰(나중에 저장된) 이벤트를 이후로 본다. `wash` 이벤트가 없으면(세탁 이력이 없거나 이벤트 없이 카운터만 있는 기존 데이터 포함) 모든 wear 이벤트를 현재 주기로 간주한다. 세탁 완료의 사후 취소는 본 릴리스 범위 외이므로 "유효한 최근 세탁"은 저장된 가장 최근 `wash` 이벤트다. `lastWornAt`은 남은 wear 이벤트의 최신 `occurredAt`(없으면 `null`)로 재계산. 결과 `wearSinceWash < washCycle`이고 직전 `status == dirty`였다면 `status = clean`으로 자동 복귀. `inLaundry`는 변경하지 않는다. `derivedStatus` 기준이므로 manual 옷은 dirty가 되지 않아 이 복귀 규칙과 충돌하지 않는다.
- 수정(002 FR-004): `careMode`·`washCycle` 변경 후 `status = derivedStatus`로 재평가한다. manual로 바꾸면 dirty였던 옷도 clean이 되고, 다시 wearCycle로 켜면 보존된 `washCycle`·`wearSinceWash`로 재평가된다. 카운터는 바꾸지 않는다.
- `inLaundry` 토글(FR-012)은 `status`를 변경하지 않는다(세탁 완료 처리 시까지 상태 보존). **관리 방식과 무관하게 모든 옷을 수동으로 담을 수 있다**(#45).
- 관리 방법(`careMethod`)은 기록·필터용 정보다. 실제 세탁 조건은 옷의 케어 라벨을 따르며 앱은 이 값으로 세탁 조건을 추정하지 않는다. 폼은 이 안내를 표시한다.

### 1.2a 보관 (#44)

옷을 지우지 않고 활성 옷장에서 빼는 상태다. 삭제(002)는 옷·사진·착용/세탁 기록을 모두 제거하지만
보관은 **기록을 모두 유지**한다.

| 사유 | 의미 | 기대 행동 |
|---|---|---|
| `seasonal` (계절 보관) | 계절이 지나 잠시 넣어 둔 옷 | 계절이 바뀌면 복원 |
| `noLongerOwned` (더 이상 갖고 있지 않음) | 처분·양도·분실 등 | 기록 보존용. 필요하면 복원 가능 |
| `unspecified` (사유 없음) | 사유를 고르지 않은 보관 | 사유 선택은 선택 사항 |

통계·화면 정책(사유와 무관하게 동일):

| 대상 | 보관한 옷 |
|---|---|
| 옷장 목록·검색(`ItemFilter` 기본) | 제외 |
| 홈 통계(전체·깨끗·관리 필요)·2x2 카드(`watchStats`) | 제외 |
| 홈 최근 입은 옷(`watchRecentlyWorn`) | 제외 |
| 세탁 바구니(`watchBasket`)·홈 바구니 미리보기 | 제외. 보관 시 `inLaundry = false`, 보관 중에는 담기 불가 |
| 보관함 화면(`ArchiveRepository.watchArchived`) | 최근 보관 순으로 표시 |
| 옷 상세 | 진입 가능. 착용 기록·바구니 버튼 대신 보관 안내와 복원 버튼 표시 |
| 해당 옷의 `WearEvent`·카운터(`totalWears` 등)·`status`·사진 | 변경 없음(보존) |

상태 전이:
- 보관(`archive`): `archivedAt = now`(이미 보관 중이면 유지), `archiveReason = 선택값`, `inLaundry = false`. 다른 필드는 바꾸지 않는다.
- 복원(`restore`): `archivedAt = null`, `archiveReason = unspecified`. 카운터·상태·기록은 보관 전 그대로이며 바구니에는 다시 담지 않는다.

### 1.3 검증

| 규칙 | 적용 시점 | 위반 처리 |
|---|---|---|
| `name.trim().length > 0` | 옷 등록·수정 폼 (FR-002) | UI에서 저장 버튼 비활성 |
| `washCycle >= 1` | 옷 등록·수정 폼 (FR-001) | 스테퍼 최소값 가드 |
| `category in Category.selectable` | 옷 등록·수정 폼 (FR-001) | 칩 선택(기본 미분류). legacy `activewear`는 선택 불가 |
| `wearSinceWash >= 0` 및 `totalWears >= 0` | Repository 갱신 시 | assert (`deleteWearEvent`는 `max(0, x-1)`로 클램프) |
| `note == null \|\| note.length <= 80` | 착용 기록·메모 편집 시(FR-010·FR-010a) | UI에서 80자 한도 입력 차단 + Repository에서 `ArgumentError` |
| `note?.trim().isEmpty == true → note = null` | 시트 확정 시 정규화 (Edge Case) | 빈 문자열은 `null`로 변환 후 저장 |

---

## 2. `WearEvent` 컬렉션

Isar `@collection`. 옷의 착용·세탁 이벤트 시간순 로그(상세 타임라인 FR-013, 홈 "최근 입은 옷" FR-020).

> **명명 메모**: 컬렉션 이름은 `WearEvent`이지만 `kind` 필드로 `wear`와 `wash`를 모두 보관하는 통합 이벤트 로그다. spec.md Key Entities의 "WearEvent (착용·세탁 이벤트)"와 1:1 매칭된다.

| 필드 | Dart 타입 | 인덱스 | 제약 | 출처 |
|---|---|---|---|---|
| `id` | `Id` | PK | — | Isar 자동 |
| `itemId` | `int` | `@Index()` | FK → `Item.id` | FR-013 |
| `kind` | `EventKind` (enum) | `@Index()` | wear \| wash | FR-013 |
| `occurredAt` | `DateTime` | `@Index(type: IndexType.value)` | not null | FR-013, FR-020 |
| `note` | `String?` | — | nullable, 단일행 ≤80자, 빈 입력은 `null`로 정규화 | FR-010 (wear에서만 입력) |

```dart
enum EventKind { wear, wash }
```

생성 규칙:
- 착용 기록(FR-010) 호출 시 `kind = wear` 이벤트 1건 생성, `note`는 시트 입력값(빈 입력은 `null`).
- 세탁 완료(FR-016) 호출 시 처리된 각 옷마다 `kind = wash` 이벤트 1건 생성. `wash` 이벤트는 본 릴리스에서 사용자 메모 입력을 받지 않으므로 `note = null` 고정.
- 옷 삭제(v1 범위 외)는 v1에서 발생하지 않으므로 cascade 삭제 미구현.

사후 변경 규칙(FR-010a / FR-010b, `kind = wear`에 한정):
- 메모 편집: `EventRepository.updateEventNote(eventId, note)`로 `note` 본문만 갱신. `kind = wash` 이벤트에 대한 호출은 거부(assert).
- 이벤트 삭제: `EventRepository.deleteWearEvent(eventId)`는 이벤트 row 제거 + `Item` 카운터·`lastWornAt`·`status` 사이드이펙트 역적용을 단일 트랜잭션으로 수행한다. `kind = wash` 이벤트 삭제는 본 릴리스 범위 외(스키마는 허용하지만 UI에서 노출하지 않음).

### 2.1 쿼리 패턴

- 옷 상세 타임라인: `events.where().itemIdEqualTo(id).sortByOccurredAtDesc().findAll()` (FR-013)
- 홈 "최근 입은 옷"(FR-020): 각 옷별 최신 `wear` 이벤트 → 옷 중복 제거 후 상위 2점.
- `deleteWearEvent` 후 `lastWornAt` 재계산(FR-010b): `events.where().itemIdEqualTo(itemId).filter().kindEqualTo(EventKind.wear).sortByOccurredAtDesc().findFirst()`의 `occurredAt`(없으면 `null`).

---

## 3. `UserPreferences` 컬렉션

Isar `@collection`. 단일 행 컬렉션 (id 고정 0).

| 필드 | Dart 타입 | 기본값 | 출처 |
|---|---|---|---|
| `id` | `Id` (고정 = 0) | 0 | 컨벤션 |
| `notifWash` | `bool` | `true` | FR-022, US5 |
| `notifWeekly` | `bool` | `true` | FR-022, US5 |
| `notifUnworn` | `bool` | `false` | FR-022, US5 |
| `accent` | `String` | `'sage'` | tweaks(설계 패키지) |
| `lastTab` | `String?` | `null` → 첫 실행 시 `home` | FR-022 |

규칙: 앱 부트 시 `prefs.get(0) ?? UserPreferences.defaults()` 패턴으로 항상 한 행을 보장.

---

## 4. `LaundryBasket` 비-엔티티화 결정

spec.md의 Key Entity "Laundry Basket"은 **별도 컬렉션이 아닌 `Item.inLaundry: bool` 속성으로 표현**한다.

근거:
- 바구니의 모든 연산(추가·제외·일괄 세탁 완료·미리보기·진행률 계산)이 Item 속성으로 충분.
- 별도 컬렉션은 JOIN 시 N+1 쿼리 위험과 동기화 비용을 만든다.
- Isar 인덱스 `@Index() inLaundry`로 `items.where().inLaundryEqualTo(true)` 쿼리가 O(log N).

후속에서 바구니가 다중(예: "여행용 세탁", "드라이클리닝 보내기") 분기되면 별도 `LaundryBag` 컬렉션 + N:M 관계로 전환한다.

---

## 5. 마이그레이션 정책

- 저장소 형식 버전은 `StorageMetadata.storageVersion`(singleton)에 기록한다. 현재 값은
  `StorageMetadata.currentStorageVersion = 2`.
- 부트 시 `StorageMigrator.migrateIfNeeded`(`lib/data/migrations/storage_migrator.dart`)가
  (1) legacy Isar 3 이전(003) 또는 (2) 기존 저장소의 버전 업그레이드를 **단일 트랜잭션**으로 수행한다.
  실패하면 아무것도 바뀌지 않고 다음 실행에서 재시도한다. 결과 source: `fresh | legacyV3 | upgraded | alreadyMigrated`.
- enum은 ordinal 저장이므로 값 추가는 끝에만 하고, 의미를 바꾸는 변경은 아래처럼 데이터를 옮긴다.

### v1 → v2 (#41 · #45)

| 대상 | 규칙 |
|---|---|
| `category == activewear` | `category = uncategorized`, `purposes += [sport]`. 상의/하의로 **추정하지 않는다**. |
| 그 외 종류 | 변경 없음 |
| `careMode` (신규) | 필드가 없는 v1 레코드는 기본값 `wearCycle`로 읽혀 기존 횟수 기반 동작을 유지한다. 별도 쓰기 없음 |
| `purposes` (신규) | 없으면 빈 목록으로 읽힌다 |
| `careMethod` | 기존 index 그대로(새 값 `unspecified`=3은 끝에 추가) |
| 카운터·`status`·`inLaundry`·날짜 | 변경 없음 |

### 보관 필드 추가 (#44, 저장소 버전 변경 없음)

`archivedAt`·`archiveReason`은 클래스 끝에 추가한 **추가식 필드**이고 기존 값의 의미를 바꾸지 않으므로
`StorageMetadata.currentStorageVersion`은 2를 유지하고 업그레이드 단계도 없다. 필드가 없는 구 데이터(v1·v2)는
`archivedAt = null`(활성), `archiveReason = unspecified`로 읽힌다. 회귀 테스트는 `test/unit/storage_migrator_test.dart`
(v1 고정본을 현재 스키마로 읽기)에 있다.

legacy Isar 3 이전 경로도 같은 규칙을 적용해 곧바로 v2로 기록한다. 회귀 테스트는
`test/unit/storage_migrator_test.dart`(v1 스키마 고정본 `test/support/storage_v1_item_fixture.dart`로
구 디스크 데이터를 재현)에 있다.

## 6. 시드(seed) 데이터 정책

- 디자인 패키지의 샘플 의류(ZARA 코트, A.P.C. 데님 등)는 사용자 환경에 자동 주입하지 않는다(spec Assumption).
- 단, **개발 빌드**(`--dart-define=SEED_DEMO=true`)에서만 `assets/dev/seed_items.json`을 import하는 진입점을 만든다. 릴리스 빌드는 정의되지 않음.

---

**Status**: 모든 엔티티·관계·전이·시드 정책 확정. 2026-10-16 #37·#41·#45로 분류 용어·관리 방식·v2 마이그레이션 추가, #44로 보관 상태 추가.
