# Data Model: 로컬 데이터 엔진 장기 호환성

## 1. 새 저장소

새 저장소 이름은 `closetimo_plus`이며 기존 `closetimo` 저장소와 같은 application support directory에 둔다.

### Item

기존 필드명, 기본값과 enum 순서를 그대로 유지한다.

- `id`: 기존 ID를 보존하는 정수 식별자
- `name`, `brand`, `imagePath`
- `category`, `careMethod`, `status`
- `washCycle`, `wearSinceWash`, `totalWears`
- `inLaundry`
- `lastWornAt`, `lastWashedAt`, `purchasedAt`, `createdAt`
- `fallbackColor`

### WearEvent

- `id`: 기존 ID를 보존하는 정수 식별자
- `itemId`: `Item.id` 참조
- `kind`: `wear` 또는 `wash`; 기존 enum ordinal 유지
- `occurredAt`
- `note`

### UserPreferences

- `id`: singleton ID `0`
- `notifWash`, `notifWeekly`, `notifUnworn`
- `accent`
- `firstLaunchedAt`
- `lastTab`

### StorageMetadata

- `id`: singleton ID `0`
- `storageVersion`: 현재 값 `1`
- `migratedAt`: 이전 완료 시각
- `legacyItemCount`
- `legacyEventCount`
- `source`: `legacy-v3` 또는 `fresh`

`StorageMetadata`는 Item, WearEvent, UserPreferences와 같은 write transaction에서 마지막으로 기록한다.

## 2. Legacy 읽기 모델

`packages/closetimo_legacy_isar` 내부에서만 사용한다.

- `LegacyItem`: Isar 3 `Item` collection과 동일한 collection명·필드·enum ordinal
- `LegacyWearEvent`: Isar 3 `WearEvent` collection과 동일한 구조
- `LegacyUserPreferences`: Isar 3 `UserPreferences` collection과 동일한 구조
- `LegacySnapshot`: 세 collection을 Dart 값 목록으로 묶어 새 저장소 계층에 전달

Legacy 모델은 앱의 repository와 UI에서 import하지 않는다.

## 3. 상태 전이

```text
새 저장소 metadata 존재
  └─> 정상 open

새 저장소 metadata 없음 + legacy 파일 없음
  └─> 빈 새 저장소 transaction
      └─> source=fresh metadata 기록

새 저장소 metadata 없음 + legacy 파일 존재
  └─> legacy 읽기 전용 open
      └─> 전체 snapshot 생성
          └─> 새 저장소 단일 transaction
              ├─> Item ID 보존 기록
              ├─> WearEvent ID 보존 기록
              ├─> UserPreferences 기록
              └─> source=legacy-v3 metadata 기록
```

transaction 실패 시 metadata가 없으므로 다음 실행에서 같은 절차를 재시도한다. legacy 파일은 모든 상태에서 삭제하지 않는다.

## 4. 검증 규칙

- `legacyItemCount`와 새 Item 수가 같아야 한다.
- `legacyEventCount`와 새 WearEvent 수가 같아야 한다.
- 모든 `WearEvent.itemId`는 존재하는 Item ID를 가리켜야 한다.
- singleton 설정이 없던 legacy 저장소는 기존 앱과 동일한 기본 설정을 생성한다.
- 이미지 경로 문자열은 변경하지 않으며 파일 부재는 저장소 이전 실패로 취급하지 않는다.
