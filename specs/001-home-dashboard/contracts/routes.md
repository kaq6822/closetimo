# Contract: Navigation Routes

**Date**: 2026-05-18 **Feature**: 001-home-dashboard

본 문서는 옷장이모 MVP의 라우트 계약을 정의한다. 구현은 `lib/app/router.dart`(`go_router`)에 위치한다. 라우트 이름·경로·전환 규칙은 본 문서의 변경 없이 임의 수정될 수 없다(헌법 IV).

---

## 1. 라우트 트리

```text
/ (ShellRoute: 하단 탭 네비게이션 보유)
├── /home          (HomeScreen, tab=home)            US5
├── /wardrobe      (WardrobeScreen, tab=wardrobe)    US2
│     query: ?category=<Category>   ← 홈 카테고리 카드 진입 시
├── /laundry       (LaundryScreen, tab=laundry)      US4
└── /settings      (SettingsScreen, tab=settings)    US5

(전체 화면 push 라우트, 하단 탭 위에 덮음)
/item/:id         (ItemDetailScreen)                 US3
/add-item         (AddItemScreen, 모달 transition)   US1
```

## 2. 진입점 & 초기 경로

- 앱 부트(`main.dart`) 시: `UserPreferences.lastTab`을 읽어 `/home`, `/wardrobe`, `/laundry`, `/settings` 중 하나로 redirect(FR-022). 값이 null이면 `/home`.
- 탭 전환 시 `UserPreferences.lastTab` 즉시 영속화.

## 3. 전환 규칙

| 출발 | 트리거 | 도착 | 부수 효과 |
|---|---|---|---|
| `/wardrobe` 또는 `/home` 상단바 `+` | 탭 | `/add-item` | 모달 push (slide-up) |
| `/add-item` "등록하기" 성공 | 자동 | pop → 직전 화면 | Toast: "새 옷이 옷장에 등록됐어요" |
| `/wardrobe` 그리드 타일 | 탭 | `/item/:id` | hero-image transition(선택) |
| `/home` 최근 옷 카드 | 탭 | `/item/:id` | 동일 |
| `/home` 카테고리 카드 | 탭 | `/wardrobe?category=상의` | 탭 전환 + 필터 사전 적용(FR-019) |
| `/item/:id` "착용 기록하기" | 탭 | pop → 직전 화면 | Toast: "오늘의 착용이 기록되었어요" (US3 AC1) |
| `/item/:id` 백 버튼 | 탭 | pop | 변경사항 자동 저장 |
| `/laundry` "세탁 완료 처리" | 탭 | 같은 화면 유지 | 항목 제거 + Toast: "N점의 세탁이 완료됐어요" |

## 4. 가드 / 검증

- `/item/:id`에서 `id`에 해당하는 Item이 존재하지 않으면 즉시 pop + 토스트 "옷을 찾을 수 없어요" (US3 안전망, spec edge case는 직접 명시되지 않았으나 방어 코드로 요구).
- `/add-item` 폼이 dirty(사용자가 어떤 필드든 수정)인 상태에서 백 버튼을 누르면 `AlertDialog`로 확인("작성 중인 내용이 사라져요. 나가시겠어요?"). 헌법 I(흐름 단순화) 균형 — 데이터 유실 방어가 더 큰 가치.

## 5. 딥링크

- v1 범위 밖. 모든 외부 진입은 `/` → `/home`으로 redirect.

## 6. 라우트 이름 상수

라우트 이름은 `lib/app/router.dart`의 상수로 노출:

```dart
abstract final class Routes {
  static const home = 'home';
  static const wardrobe = 'wardrobe';
  static const laundry = 'laundry';
  static const settings = 'settings';
  static const itemDetail = 'itemDetail';
  static const addItem = 'addItem';
}
```

문자열 리터럴 `'/wardrobe'`을 직접 사용하는 것을 금지(린트 규칙 또는 코드 리뷰로 강제).

---

**Status**: 라우트 계약 확정.
