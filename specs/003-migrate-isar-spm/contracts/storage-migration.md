# Storage Migration Contract

## 목적

앱 시작 시 legacy Isar 3 저장소를 새 저장소로 안전하게 이전하고 이후 repository에 준비된 새 저장소만 제공한다.

## `StorageMigrator`

```text
migrateIfNeeded(newStore, directory, clock) -> MigrationResult
```

### 사전 조건

- 새 저장소는 `closetimo_plus` 이름으로 열려 있다.
- legacy 저장소는 `closetimo` 이름을 사용한다.
- 호출 시 앱 repository는 아직 생성되지 않았다.

### 결과

- `ready`: 새 저장소가 사용 가능하다.
- `source`: `fresh`, `legacyV3`, `alreadyMigrated` 중 하나다.
- `itemCount`, `eventCount`: 검증된 새 저장소 레코드 수다.

### 보장

1. 완료 표식이 있으면 legacy 저장소를 열지 않는다.
2. 완료 표식이 없고 legacy 파일이 있으면 모든 legacy 레코드를 읽는다.
3. 데이터와 완료 표식은 하나의 새 저장소 transaction으로 기록한다.
4. ID, enum 의미, nullable 값과 관계를 보존한다.
5. 실패 시 legacy 파일을 수정하거나 삭제하지 않는다.
6. 같은 입력으로 다시 호출해도 레코드를 중복 생성하지 않는다.
7. 실패 로그와 예외 메시지는 영문으로 기록한다.

## `LegacyStoreReader`

```text
readSnapshot(directory) -> LegacySnapshot?
```

- legacy 파일이 없으면 `null`을 반환한다.
- legacy 저장소는 읽기 목적으로만 열고 snapshot 생성 후 닫는다.
- snapshot은 native Isar 객체를 외부로 노출하지 않는 Dart 값이다.

## 저장소 제공 계약

`isarProvider`는 `migrateIfNeeded`가 성공한 뒤에만 새 Isar Plus 인스턴스를 `AsyncValue.data`로 제공한다. 실패하면 인스턴스를 닫고 `AsyncValue.error`로 전달하여 repository가 부분 초기화 상태를 관찰하지 못하게 한다.
