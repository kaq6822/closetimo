# Data Model: 옷장이모 MVP

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 Isar 컬렉션 스키마(소스 코드의 `lib/data/models/`에 대응)와 엔티티 간 관계, 검증 규칙, 상태 전이를 정의한다. 모든 필드는 spec.md의 Key Entities + FR-001~FR-022에서 도출된다.

**구현 버전**: Isar **3.x** 안정 라인(`isar ^3.1.0+1`)에 맞춰 작성됨. 본 문서의 `@collection`, `@Index`, `Id` 타입은 3.x API 기준. 후속 4.x(Rust core) 마이그레이션은 별도 spec으로 정의한다.

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
| `category` | `Category` (enum) | `@Index()` | not null | FR-001 |
| `careMethod` | `CareMethod` (enum) | — | not null | FR-001 |
| `status` | `ItemStatus` (enum) | `@Index()` | `clean` 기본 | FR-008/011 |
| `washCycle` | `int` | — | `>= 1` (FR-001) | FR-001 |
| `wearSinceWash` | `int` | — | `>= 0` | FR-010 |
| `totalWears` | `int` | — | `>= 0` | FR-010 |
| `lastWornAt` | `DateTime?` | `@Index(type: IndexType.value)` | nullable | FR-010, FR-007(정렬) |
| `lastWashedAt` | `DateTime?` | — | nullable | FR-009 |
| `purchasedAt` | `DateTime?` | — | nullable | FR-001 |
| `inLaundry` | `bool` | `@Index()` | 기본 false | FR-012, FR-014 |
| `imagePath` | `String?` | — | nullable (FR-003 → 플레이스홀더) | FR-001 |
| `fallbackColor` | `int` | — | 기본 0xFFE5E4DC | UI 폴백 |
| `createdAt` | `DateTime` | — | 등록 시각 | FR-004(최신 우선) |

### 1.1 Enum 정의

```dart
enum Category {
  outer('아우터'),
  top('상의'),
  bottom('하의'),
  onepiece('원피스'),
  shoes('신발'),
  bag('가방'),
  accessory('액세서리'),
  activewear('운동복'),
  etc('기타');
}

enum CareMethod {
  dryClean('드라이클리닝'),
  machine('기계세탁'),
  handWash('핸드워시');
}

enum ItemStatus { clean, dirty }
```

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
- 옷 등록 시: `status = clean`, `wearSinceWash = 0`, `totalWears = 0`, `inLaundry = false`, `createdAt = now`.
- 착용 기록(FR-010): `wearSinceWash++`, `totalWears++`, `lastWornAt = now`. 결과적으로 `wearSinceWash >= washCycle`이면 `status = dirty`로 전환(FR-011).
- 세탁 완료(FR-016): `wearSinceWash = 0`, `status = clean`, `lastWashedAt = now`, `inLaundry = false`.
- `inLaundry` 토글(FR-012)은 `status`를 변경하지 않는다(세탁 완료 처리 시까지 상태 보존).

### 1.3 검증

| 규칙 | 적용 시점 | 위반 처리 |
|---|---|---|
| `name.trim().length > 0` | 옷 등록·수정 폼 (FR-002) | UI에서 저장 버튼 비활성 |
| `washCycle >= 1` | 옷 등록·수정 폼 (FR-001) | 스테퍼 최소값 가드 |
| `category in Category` | 옷 등록·수정 폼 (FR-001) | 칩 선택 강제 |
| `wearSinceWash >= 0` 및 `totalWears >= 0` | Repository 갱신 시 | assert |

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
| `note` | `String?` | — | nullable | (확장 여지) |

```dart
enum EventKind { wear, wash }
```

생성 규칙:
- 착용 기록(FR-010) 호출 시 `kind = wear` 이벤트 1건 생성.
- 세탁 완료(FR-016) 호출 시 처리된 각 옷마다 `kind = wash` 이벤트 1건 생성.
- 옷 삭제(v1 범위 외)는 v1에서 발생하지 않으므로 cascade 삭제 미구현.

### 2.1 쿼리 패턴

- 옷 상세 타임라인: `events.where().itemIdEqualTo(id).sortByOccurredAtDesc().findAll()` (FR-013)
- 홈 "최근 입은 옷"(FR-020): 각 옷별 최신 `wear` 이벤트 → 옷 중복 제거 후 상위 2점.

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

- Isar는 schema migration이 자동(필드 추가/삭제에 강함). 하지만 enum 값 변경은 수동 마이그레이션 필요.
- 첫 출시(v1)는 마이그레이션 없음. 후속 spec에서 스키마 변경 시:
  1. `IsarVersion` 메타데이터를 `UserPreferences.schemaVersion` 필드에 기록.
  2. `main.dart` 부트 시 버전 차이 감지 → migration 함수 실행 → 버전 업데이트.

---

## 6. 시드(seed) 데이터 정책

- 디자인 패키지의 샘플 의류(ZARA 코트, A.P.C. 데님 등)는 사용자 환경에 자동 주입하지 않는다(spec Assumption).
- 단, **개발 빌드**(`--dart-define=SEED_DEMO=true`)에서만 `assets/dev/seed_items.json`을 import하는 진입점을 만든다. 릴리스 빌드는 정의되지 않음.

---

**Status**: 모든 엔티티·관계·전이·시드 정책 확정. 데이터 모델 측 NEEDS CLARIFICATION 없음.
