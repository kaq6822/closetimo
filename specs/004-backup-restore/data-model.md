# Data Model: 백업 파일 형식 (formatVersion 1)

백업은 zip 아카이브 하나다. 파일 이름 예: `closetimo-backup-20261017-0930.zip`.
Isar 스키마의 단일 진실 원천은 [001 data-model.md](../001-home-dashboard/data-model.md)이며, 본 문서는 그 모델을
**파일로 옮기는 형식**만 정의한다. 매핑 코드는 `lib/data/backup/backup_codec.dart` 한 곳에 있다.

## 1. 아카이브 구조

```text
closetimo-backup-YYYYMMDD-HHmm.zip
├── backup.json          # 메타 + 옷·기록·설정 (UTF-8 JSON)
└── images/
    ├── 12.jpg           # Item.id = 12의 사진
    └── 15.jpg
```

- 사진은 **아카이브 내부 상대 참조**(`images/{itemId}.jpg`)로만 연결한다. 기기 sandbox 경로(`items/12.jpg`)나
  절대 경로는 기록하지 않는다.
- zip 각 엔트리의 CRC32를 복원 시 다시 계산해 비교한다(손상 감지).
- `backup.json`, `images/` 밖의 엔트리는 무시한다(전방 호환 여지). 단, `images/` 아래 참조되지 않은 엔트리도 무시한다.

## 2. `backup.json`

```jsonc
{
  "format": "closetimo-backup",      // 고정 식별자. 다르면 손상/타 파일로 거부
  "formatVersion": 1,                // 정수. 앱 지원 최대값보다 크면 거부
  "createdAt": "2026-10-17T00:30:00.000Z", // 백업 생성 시각(ISO-8601, UTC)
  "items": [ /* §2.1 */ ],
  "wearEvents": [ /* §2.2 */ ],
  "preferences": { /* §2.3 */ }       // 설정 행이 없었으면 null
}
```

공통 규칙:

- `DateTime`은 UTC 순간의 ISO-8601 문자열(`toUtc().toIso8601String()`, `Z` 접미), 없으면 `null`. 복원 시 기기 로컬 시각으로
  바꾼다. 로컬 시각 문자열은 다른 시간대 기기에서 모든 날짜가 어긋나므로 쓰지 않는다.
- **enum은 ordinal이 아니라 이름(`name`) 문자열**로 저장한다. 저장 순서 변경·추가에 견고하고, 알 수 없는 이름은
  손상으로 간주한다.
- 모든 키는 필수다(값이 `null`일 수 있는 필드도 키는 있어야 한다). 누락·타입 불일치는 손상으로 간주한다.
- 복원 시 값 정규화: `tags`는 앱 입력 규칙(`normalizeTags`: 공백 정리·20자·대소문자 중복 제거)을 다시 적용하고,
  보관한 옷(`archivedAt != null`)의 `inLaundry`는 `false`로 해제한다(보관한 옷은 바구니에 담을 수 없음, #44).
  `fallbackColor`가 32비트 ARGB 범위(0~0xFFFFFFFF) 밖이면 손상으로 간주한다.

### 2.1 `items[]` (Item 전 필드)

| 키 | 타입 | 비고 |
|---|---|---|
| `id` | int | 원본 id 그대로. 기록의 `itemId`가 이 값을 참조. 중복 금지 |
| `name` | string | 비어 있으면 손상 |
| `brand` | string? | |
| `category` | enum name | `Category` |
| `careMethod` | enum name | `CareMethod` |
| `status` | enum name | `ItemStatus` |
| `washCycle` | int | ≥ 1 |
| `wearSinceWash` | int | ≥ 0 |
| `totalWears` | int | ≥ 0 |
| `lastWornAt` | datetime? | |
| `lastWashedAt` | datetime? | |
| `purchasedAt` | datetime? | |
| `inLaundry` | bool | |
| `image` | string? | **`imagePath` 대신** 아카이브 상대 참조 `images/{id}.jpg`. 없으면 null |
| `fallbackColor` | int | ARGB |
| `createdAt` | datetime | |
| `careMode` | enum name | `CareMode` |
| `purposes` | enum name[] | `ItemPurpose` |
| `archivedAt` | datetime? | |
| `archiveReason` | enum name | `ArchiveReason` |
| `tags` | string[] | 사용자 태그(#46). 정규화는 `item_tags.dart` 규칙 |

### 2.2 `wearEvents[]` (WearEvent 전 필드)

| 키 | 타입 | 비고 |
|---|---|---|
| `id` | int | 중복 금지 |
| `itemId` | int | `items[].id` 중 하나여야 한다(참조 무결성). 아니면 손상 |
| `kind` | enum name | `EventKind` |
| `occurredAt` | datetime | |
| `note` | string? | |

### 2.3 `preferences` (UserPreferences 전 필드, `id` 제외 — 항상 singleton 0)

| 키 | 타입 |
|---|---|
| `notifWash` | bool |
| `notifWeekly` | bool |
| `notifUnworn` | bool |
| `accent` | string |
| `lastTab` | string? |
| `firstLaunchedAt` | datetime? |

## 3. 복원 시 sandbox 매핑

- 사진은 `items/{itemId}_r{token}.jpg`로 쓴다(`token`은 복원마다 새로 만든 난수). 기존 `items/{id}.jpg`와 이름이
  겹치지 않아 커밋 전까지 기존 파일을 건드리지 않는다. `Item.imagePath`는 이 새 상대 경로로 채운다.
- 이후 옷 사진을 교체하면 `ItemRepository.update`가 새 사진을 `items/{id}.jpg`에 쓰고, 경로가 바뀐 이전 파일을
  best-effort로 지운다.

## 4. 버전 정책

- `formatVersion`은 **백업 형식**의 버전이며 Isar 저장소 버전(`StorageMetadata.storageVersion`)과 독립이다.
- 다음 경우 `formatVersion`을 올린다: `backup.json`에 키를 추가·삭제, 값 의미 변경, enum에 값 추가
  (구 앱이 모르는 이름을 받으면 손상으로 오판하므로).
- 앱은 `1..currentFormatVersion` 범위를 읽는다. 더 높은 버전은 "앱 업데이트 필요"로 거부한다. 더 낮은 버전은
  해당 버전 디코더가 현재 모델 기본값으로 채운다(예: 새 필드가 없는 v1 → 모델 기본값).
- 필드 목록 가드 테스트(`test/unit/backup_codec_test.dart`)가 Isar 생성 스키마의 속성 목록과 codec의 필드 목록을
  비교한다. 모델에 필드가 추가되면 테스트가 실패하므로 codec·본 문서·`formatVersion`을 함께 갱신한다.

| formatVersion | 변경 | 출처 |
|---|---|---|
| 1 | 최초 형식(Item·WearEvent·UserPreferences, 저장소 v2 + 보관 필드 + 태그). 배포 전이라 #46 `tags`는 버전을 올리지 않고 v1에 포함 | #40, #46 |
