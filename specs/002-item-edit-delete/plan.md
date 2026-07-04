# Implementation Plan: 옷 정보 수정 & 삭제

**Branch**: `002-item-edit-delete` | **Date**: 2026-07-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-item-edit-delete/spec.md`

## Summary

001-home-dashboard가 남긴 CRUD 공백(수정·삭제)을 채운다. 데이터 레이어에
`ItemRepository.update(int id, ItemPatch)`·`ItemRepository.delete(int id)`를 추가하고,
UI는 기존 등록 화면(`AddItemScreen`)을 등록/수정 겸용 폼으로 확장하며, 옷 상세 화면
상단바에 오버플로 메뉴(수정/삭제)를 붙인다. 삭제는 대상 Item + 연관 WearEvent를 단일
Isar 트랜잭션으로 제거하고 sandbox 이미지 파일을 best-effort로 지운다. 새 스키마 필드나
새 화면은 도입하지 않는다 — 기존 위젯·토큰·라우트 패턴을 재사용한다.

## Technical Context

**Language/Version**: Dart 3.5+ / Flutter 3.27 (stable) — 001과 동일

**Primary Dependencies**: 신규 의존성 없음. 기존 isar, flutter_riverpod, go_router, image_picker, freezed 재사용.

**Storage**: Isar. `Item`·`WearEvent` 컬렉션 스키마 무변경. 이미지 파일은 `ImageStore`(sandbox `documents/items/`).

**Testing**: `flutter_test` 위젯·단위 테스트. repository 로직은 in-memory fake로 검증(001 `test/feature/wear_record_test.dart` 패턴 재사용).

**Target Platform**: iOS 13+ / Android API 21+ — 001과 동일.

**Project Type**: 모바일 단일 앱 (백엔드 없음).

**Performance Goals**: 수정 저장 후 100ms 이내 UI 반영(SC-002), 삭제 즉시 반영(SC-003). Isar `watchLazy` 스트림이 자동 갱신을 담당하므로 별도 무효화 불필요.

**Constraints**:
- 오프라인 우선(FR-013). 네트워크 호출 없음.
- 디자인 토큰 일관성(FR-014, 헌법 II) — 등록 화면 위젯 재사용으로 자연 충족.
- 삭제는 영구(soft delete 없음). undo 없음.

**Scale/Scope**: 단일 사용자, 단건 수정·삭제. 신규 파일 2개(ItemPatch, 삭제 확인 다이얼로그) + 기존 파일 확장(repository 인터페이스·구현, add_item 화면, item_detail 화면, image_store, 라우터).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 원칙 | 평가 | 비고 |
|---|---|---|
| **I. 큐레이션 우선 사용자 흐름** (NON-NEGOTIABLE) | ✅ Pass | 수정은 3단계(⋯→수정→저장, SC-001), 삭제는 확인 1스텝. 기존 등록 폼 재사용으로 새 학습 부담 없음. |
| **II. 디자인 시스템 일관성** | ✅ Pass | 새 색상·간격 없음. 오버플로 메뉴·확인 다이얼로그는 001 `DeleteEventDialog` 패턴과 동일 위젯 언어. |
| **III. 로컬 우선 데이터 소유권** | ✅ Pass | 모든 변경은 로컬 Isar 트랜잭션. 삭제는 사용자 데이터를 사용자 의도대로 제거(소유권 강화). 외부 호출 없음. |
| **IV. Spec 주도 변경 관리** | ✅ Pass | 본 plan·spec·tasks·contracts·data-model 산출물이 코드 PR과 동봉된다. |

**Result**: 4/4 통과. `Complexity Tracking` 정당화 사유 없음.

## Project Structure

### Documentation (this feature)

```text
specs/002-item-edit-delete/
├── plan.md              # 이 파일
├── spec.md              # 기능 요구사항
├── research.md          # 기술 결정 (delta)
├── data-model.md        # 스키마 영향 (무변경 확인 + ItemPatch DTO)
├── contracts/
│   └── repositories.md  # ItemRepository update/delete 계약 (delta)
├── quickstart.md        # 수동 검증 시나리오
└── tasks.md             # 구현 작업 목록
```

### Source Code (변경 대상)

```text
lib/
├── app/
│   └── router.dart                         # [수정] /item/:id/edit push 라우트 추가
├── core/persistence/
│   └── image_store.dart                    # [수정] delete(String relativePath) 추가
├── data/
│   ├── models/
│   │   └── item_patch.dart                 # [신규] 수정 요청 DTO (freezed)
│   └── repositories/
│       ├── item_repository.dart            # [수정] update/delete 시그니처 추가
│       └── isar_item_repository.dart        # [수정] update/delete 구현 (status 재평가 + cascade)
└── features/
    ├── add_item/
    │   ├── add_item_screen.dart            # [수정] editId 파라미터로 등록/수정 겸용
    │   ├── new_item_draft.dart             # [수정] Item→draft 팩토리 + 사진 상태 필드
    │   └── widgets/photo_picker_card.dart  # [수정] 기존 imagePath 표시 + 제거 액션
    └── item_detail/
        ├── item_detail_screen.dart         # [수정] 상단바 오버플로 메뉴(수정/삭제)
        └── widgets/delete_item_dialog.dart # [신규] 삭제 확인 다이얼로그

test/
└── feature/
    └── item_edit_delete_test.dart          # [신규] update 상태 재평가 + delete cascade 회귀
```

**Structure Decision**: 001의 feature-first 레이아웃을 그대로 따른다. 수정 화면을 신설하지 않고
`add_item/`을 등록/수정 겸용으로 확장해 폼 위젯 중복을 피한다(헌법 I·II). 삭제 확인 다이얼로그는
001 `DeleteEventDialog`와 같은 형태이나 대상·문구가 달라 `item_detail/widgets/`에 별도 위젯으로 둔다.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

해당 없음 — 4개 헌법 원칙 모두 위반 없이 통과.
