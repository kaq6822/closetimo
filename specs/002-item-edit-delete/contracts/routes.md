# Contract: Routes (002 delta)

**Date**: 2026-07-05 **Feature**: 002-item-edit-delete

001-home-dashboard/contracts/routes.md의 라우트 트리를 상속한다. 본 문서는 002가
추가·변경하는 라우트와 네비게이션 계약만 정의한다.

---

## 1. 신규 라우트 — 옷 수정

| 이름 상수 | 경로 | 네비게이터 | 진입 방식 | 화면 |
|---|---|---|---|---|
| `Routes.editItem` | `/item/:id/edit` | root | `pushNamed` | `AddItemScreen(editId: id)` |

- 등록 라우트(`/add-item`)와 동일한 slide-up transition을 사용한다(`_slideUpPage`).
- `id` 파싱 실패 시 placeholder 모달을 띄운다(001 `/item/:id` 규칙과 대칭).
- 진입: 옷 상세 화면 상단바 오버플로 메뉴(⋯) → "수정하기" → `context.pushNamed(Routes.editItem, pathParameters: {'id': '$id'})`.
- 복귀: 저장·취소 시 `context.pop()`으로 상세 화면에 돌아가고, 상세는 `_refresh()`로 갱신한다.

## 2. 네비게이션 변경 — 옷 삭제 후 복귀

- 옷 상세에서 삭제 확정 시(`ItemRepository.delete` 성공 후) `context.goNamed(Routes.wardrobe)`로
  **옷장 탭**에 복귀한다(spec FR-012, US2 AC1).
- `pop()`을 쓰지 않는 이유: 상세 화면은 옷장뿐 아니라 홈 "최근 입은 옷" 카드
  (`recently_worn_list.dart`)와 세탁 타일(`laundry_tile.dart`)에서도 `pushNamed`로 진입하므로,
  `pop()`은 진입 탭(홈/세탁)으로 돌아가 FR-012의 "옷장 탭 복귀"를 위반한다. 삭제는 탭 전환이
  의도이므로 push 규칙(itemDetail/addItem은 pushNamed)과 별개로 go 계열을 사용한다.
- 예외(001 #13): push 아래 기준 위치(`routerDelegate.currentConfiguration.uri`)가 이미 `/wardrobe`
  (옷장 그리드에서 진입)이면 `pop()`으로 돌아간다. 옷장 칩 필터가 `?category=`로 URL에 동기화되므로
  쿼리 없는 `goNamed`는 필터를 전체로 초기화하고 스크롤을 맨 위로 올리기 때문이다.

## 3. 계약 준수 노트

- `lib/app/AGENTS.md` 규칙("라우트 변경은 계약이 먼저")에 따라 본 delta가 코드(`router.dart`의
  `Routes.editItem`·`/item/:id/edit`)와 삭제 후 네비게이션의 단일 진실 원천이다.
- push 진입(itemDetail·addItem·editItem)은 `pushNamed`, 삭제 후 탭 복귀만 `goNamed`.

---

**Status**: editItem 라우트 + 삭제 후 옷장 복귀 계약 확정.
