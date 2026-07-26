---
description: "옷 정보 수정 & 삭제의 구현 작업 목록"
---

# Tasks: 옷 정보 수정 & 삭제

**Input**: Design documents from `/specs/002-item-edit-delete/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/repositories.md

**Tests**: repository 로직은 in-memory fake 회귀 테스트로 검증(001 `wear_record_test.dart` 패턴).

**Organization**: user story(P1 수정 / P2 삭제)별 그룹. 데이터 레이어는 두 스토리가 공유하는 선행 작업.

## Format: `[ID] [P?] [Story] Description with file path`

- **[P]**: 같은 phase 내 다른 파일·무의존 작업(병렬 가능)
- **[Story]**: US1(수정)·US2(삭제)·FND(공유 선행)

---

## Phase 1: Foundational (데이터 레이어 — 두 스토리 공유)

**⚠️ 이 phase 완료 전에는 UI 스토리를 시작할 수 없다.**

- [X] T001 [FND] `ItemPatch` DTO — `lib/data/models/item_patch.dart`에 `@freezed class ItemPatch`로 name, brand, category, careMethod, washCycle, purchasedAt, `File? newPhoto`, `@Default(false) bool removePhoto` 정의(data-model.md §3).
- [X] T002 [FND] `NewItemDraft.fromItem` 팩토리 — `lib/features/add_item/new_item_draft.dart`에 기존 `Item`으로부터 draft 초기값을 만드는 팩토리 추가(수정 폼 prefill용). `tempPhoto`는 null(기존 imagePath는 화면 로컬 상태로 관리).
- [X] T003 [FND] 코드 생성 — `dart run build_runner build --delete-conflicting-outputs`로 `item_patch.freezed.dart`·`new_item_draft.freezed.dart` 갱신.
- [X] T004 [FND] `ImageStore.delete` — `lib/core/persistence/image_store.dart`에 `Future<void> delete(String relativePath)` 추가. `absolutePath`로 해석 후 파일 존재 시 삭제, 실패는 조용히 무시(contracts §2, FR-011).
- [X] T005 [FND] `ItemRepository` 인터페이스 확장 — `lib/data/repositories/item_repository.dart`에 `Future<void> update(int id, ItemPatch patch)`·`Future<void> delete(int id)` 추가(contracts §1). `ItemPatch` import.
- [X] T006 [FND] `IsarItemRepository.update` 구현 — `lib/data/repositories/isar_item_repository.dart`에 contracts §1 `update` 의사코드 구현: name 검증(ArgumentError) + 스칼라 필드 갱신 + 사진 3-way 의도 처리 + status 재평가(FR-004) + 파생 필드 보존. 단일 `writeTxn`, removePhoto 시 txn 밖 best-effort `imageStore.delete`.
- [X] T007 [FND] `IsarItemRepository.delete` 구현 — 같은 파일에 contracts §1 `delete` 의사코드 구현: 연관 `WearEvent` 전량 삭제 + Item 삭제를 단일 `writeTxn`으로, txn 밖 best-effort 이미지 파일 삭제(FR-010·011, SC-004).

**Checkpoint**: `flutter analyze` 통과, repository 시그니처가 contracts와 일치.

---

## Phase 2: User Story 1 - 옷 정보 수정 (Priority: P1)

**Goal**: 상세 → 수정 진입 → 폼 편집 → 저장 → 즉시 반영(FR-001~007).

- [X] T008 [US1] `PhotoPickerCard` 확장 — `lib/features/add_item/widgets/photo_picker_card.dart`에 `String? existingImagePath`(sandbox 절대경로로 표시)와 선택적 "사진 제거" 액션 콜백 추가. `tempPhoto` > `existingImagePath` > 플레이스홀더 우선순위로 렌더.
- [X] T009 [US1] `AddItemScreen` 등록/수정 겸용 — `lib/features/add_item/add_item_screen.dart`에 `final int? editId` 파라미터 추가. editId != null이면 initState에서 `itemRepositoryProvider.get`으로 로드 → `NewItemDraft.fromItem` prefill + `_existingImagePath`/`_photoCleared` 상태 초기화, TopBar subtitle "옷 정보 수정", 하단 버튼 "수정 완료", 저장 시 `update(editId, ItemPatch(...))` 호출 + 토스트 "옷 정보를 수정했어요". 로딩 중 스피너.
- [X] T010 [US1] `/item/:id/edit` 라우트 — `lib/app/router.dart`에 `Routes.editItem` 상수 + root navigator push 라우트(slide-up transition, `/add-item`과 동일 패턴) 추가. `AddItemScreen(editId: id)` 연결. contracts와 동기화.
- [X] T011 [US1] 상세 → 수정 진입 — `lib/features/item_detail/item_detail_screen.dart` 상단바 우측에 오버플로 메뉴(⋯) 추가, "수정하기" 선택 시 `context.pushNamed(Routes.editItem, ...)` 호출. 복귀 후 `_refresh()`로 상세 갱신.

**Checkpoint**: 옷 정보를 고쳐 저장하면 상세·옷장에 즉시 반영. AC1~5 수동 확인.

---

## Phase 3: User Story 2 - 옷 삭제 (Priority: P2)

**Goal**: 상세 → 삭제 → 확인 → cascade 삭제 → 옷장 복귀(FR-008~012).

- [X] T012 [US2] `DeleteItemDialog` 위젯 — `lib/features/item_detail/widgets/delete_item_dialog.dart`에 `Future<bool> confirm(BuildContext)` 정적 메서드. AlertDialog "이 옷을 삭제할까요? 착용·세탁 기록도 함께 사라지고 되돌릴 수 없어요." + "삭제"/"취소". 001 `DeleteEventDialog` 패턴 재사용.
- [X] T013 [US2] 상세 → 삭제 결선 — `lib/features/item_detail/item_detail_screen.dart` 오버플로 메뉴에 "삭제하기" 추가. 선택 시 `DeleteItemDialog.confirm` → true면 `itemRepositoryProvider.delete(id)` → `context.pop()`(옷장 복귀) + 토스트 "옷을 옷장에서 삭제했어요"(FR-009·012).

**Checkpoint**: 옷 삭제 시 옷장·홈·세탁에서 즉시 사라지고 이벤트·이미지도 제거. AC1~5 수동 확인.

---

## Phase 4: 테스트 & 검증

- [X] T014 [P] update 회귀 테스트 — `test/feature/item_edit_delete_test.dart`에 in-memory fake ItemRepository로 (a) 스칼라 필드 갱신 + 파생 필드 보존, (b) 세탁 주기 하향 → dirty / 상향 → clean 재평가(FR-004, AC3·4), (c) 빈 name → ArgumentError, (d) 사진 3-way 의도(교체/제거/유지) 검증.
- [X] T015 [P] delete 회귀 테스트 — 같은 파일에 (a) Item 삭제 시 연관 WearEvent 전량 제거(wear·wash 모두, SC-004), (b) 미존재 id no-op, (c) 이미지 경로 삭제 호출 확인(fake ImageStore) 검증.
- [X] T016 검증 — `dart run build_runner build --delete-conflicting-outputs` → `flutter analyze`(경고 0) → `flutter test`(전체) → `dart run tool/check_design_tokens.dart` 순으로 통과 확인.

---

## Dependencies & Execution Order

```text
Phase 1 (FND: T001→T002→T003, T004, T005→T006/T007) ─┬─► Phase 2 (US1: T008→T009→T010→T011)
                                                      └─► Phase 3 (US2: T012→T013)
                                                              │
                                                              └─► Phase 4 (T014·T015 [P] → T016)
```

- **T001→T002→T003**: ItemPatch·fromItem 정의 후 코드 생성.
- **T005→T006/T007**: 인터페이스 확장 후 구현.
- US1(Phase 2)과 US2(Phase 3)는 Phase 1 완료 후 독립적. UI는 순차 권장(같은 item_detail_screen.dart 편집).
- T014·T015는 [P](다른 관심사, 같은 파일이라 실제로는 순차 편집).

## Notes

- 스키마 무변경 → Isar 마이그레이션 불필요. 코드 생성은 freezed(ItemPatch)만 대상.
- 모든 UI는 001 디자인 토큰·위젯 재사용(FR-014). 새 색상·간격 금지.
- spec.md FR-001~014, SC-001~005는 본 tasks 어딘가에서 검증된다.
