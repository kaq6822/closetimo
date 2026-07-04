# Research: 옷 정보 수정 & 삭제 (delta)

**Feature**: 002-item-edit-delete | **Date**: 2026-07-04

001-home-dashboard research.md의 결정을 그대로 상속한다. 본 문서는 수정·삭제 흐름에서
새로 내린 결정만 기록한다.

## 1. 수정 화면: 등록 화면 재사용 vs 신설

- **Decision**: 기존 `AddItemScreen`을 `editId` 파라미터로 등록/수정 겸용 화면으로 확장한다.
  `editId == null`이면 등록(현행), 그 외에는 수정 모드.
- **Rationale**: 입력 필드·검증 규칙·디자인이 등록과 100% 동일하다. 별도 화면을 만들면
  폼 위젯(`_FieldInput`, `WashCycleStepper`, `CategoryPicker`, `CareMethodPicker`,
  `PhotoPickerCard`)을 통째로 복제하게 되어 헌법 II(일관성)·유지보수성에 불리하다.
- **Alternatives**:
  - **`EditItemScreen` 신설**: 폼 중복. 이후 필드 추가 시 두 곳을 동기화해야 함 — 기각.
  - **인라인 상세 편집**: 상세 화면 정보 밀도가 높아 편집 필드를 겹치면 노이즈 — 기각.

## 2. 수정 폼 상태 & 사진 의도 표현

- **Decision**: `NewItemDraft`에 `Item`으로부터 초기값을 만드는 `NewItemDraft.fromItem(Item)`
  팩토리를 추가한다. 사진은 화면 로컬 상태(`_existingImagePath`, `_photoCleared`)로 3가지
  의도를 구분한다: (a) 유지 — 새 파일 없음 & 미제거, (b) 교체 — `tempPhoto != null`,
  (c) 제거 — `_photoCleared == true`. repository에는 `ItemPatch`로 이 의도를 전달한다.
- **Rationale**: `NewItemDraft`는 이미 freezed 불변 모델이라 `fromItem`만 추가하면 재사용 가능.
  사진 의도를 3-way로 명시하지 않으면 "유지"와 "제거"를 구분할 수 없다(둘 다 `tempPhoto == null`).
- **Alternatives**: `imagePath`를 draft에 직접 넣는 방안은 `File?`(신규 선택)과 `String?`(기존 경로)의
  타입 혼재를 초래 — 화면 로컬 플래그로 분리하는 편이 명확.

## 3. `ItemPatch` DTO

- **Decision**: 영속화하지 않는 in-memory 값 객체(freezed)로 정의한다. 필드 — name, brand,
  category, careMethod, washCycle, purchasedAt, `File? newPhoto`, `bool removePhoto`.
  `newPhoto`와 `removePhoto`는 상호 배타(둘 다 세팅 시 `newPhoto` 우선).
- **Rationale**: repository 인터페이스를 UI 위젯(File)과 분리하면서도 사진 의도를 한 객체로 전달.
  `NewItemDraft`를 그대로 넘기지 않는 이유는 create/update의 관심사(생성 기본값 vs 부분 갱신)를
  섞지 않기 위함. contracts/repositories.md §1에 시그니처를 확정한다.

## 4. 세탁 주기 변경 시 상태 재평가

- **Decision**: `update` 트랜잭션 끝에서 `item.status = item.wearSinceWash >= item.washCycle
  ? ItemStatus.dirty : ItemStatus.clean`으로 재계산한다.
- **Rationale**: 001에서 `status`는 이미 `wearSinceWash`/`washCycle`의 순수 함수 불변식이다
  (recordWear는 임계 도달 시 dirty, completeWashFor는 wearSinceWash=0+clean, deleteWearEvent는
  임계 미달 시 clean 복귀). 수정으로 `washCycle`이 바뀌면 이 불변식을 즉시 다시 맞춰야
  옷장 라벨(FR-008)과 정합한다. 재평가를 생략하면 "주기를 낮췄는데 여전히 clean"인 직관 위반 발생.

## 5. 삭제 cascade & 이미지 파일

- **Decision**: `delete(int id)`는 단일 `isar.writeTxn`에서 (1) `wearEvents.filter().itemIdEqualTo(id)`로
  연관 이벤트 id를 모아 `wearEvents.deleteAll(ids)`, (2) `items.delete(id)`를 수행한다. 트랜잭션
  성공 후 `ImageStore.delete(imagePath)`를 best-effort로 호출한다(예외를 삼킴).
- **Rationale**: Item과 WearEvent는 같은 Isar 인스턴스의 서로 다른 컬렉션이므로 한 트랜잭션에
  묶어 orphan 이벤트(SC-004)를 원천 차단. 파일 시스템은 트랜잭션 밖이라 실패해도 DB 일관성에
  영향 없음(FR-011 best-effort). Isar에는 FK 캐스케이드가 없어 수동 삭제가 필수다.
- **Alternatives**: `EventRepository`에 삭제를 위임하는 방안은 트랜잭션이 두 repository로 쪼개져
  원자성이 깨진다 — `ItemRepository.delete` 한 곳에서 두 컬렉션을 다루는 편이 안전.

## 6. 삭제 후 내비게이션

- **Decision**: 상세 화면(`/item/:id`, root navigator push)에서 삭제 성공 시 `context.pop()`으로
  직전 화면(대개 옷장 그리드)으로 복귀한다. 옷장 그리드는 `watchFiltered` 스트림이 자동
  갱신하므로 별도 새로고침 불필요.
- **Rationale**: 001의 상세 진입은 `pushNamed`(스택 push)이므로 `pop`이 자연스럽다(routes.md 계약).
  삭제된 옷의 상세에 머무르면 안 되므로 즉시 pop.

## 후속 후보 (본 feature 범위 밖)

- 옷장 그리드 다중 선택 일괄 삭제.
- 삭제 실행 취소(undo) / 휴지통(soft delete).
- 수정 이력 추적.

---

**Status**: 결정 확정. contracts/repositories.md·data-model.md에 반영됨.
