# Quickstart: 옷 정보 수정 & 삭제

**Feature**: 002-item-edit-delete

001-home-dashboard/quickstart.md의 개발 환경 부트스트랩을 그대로 사용한다. 본 문서는
002 흐름의 수동 검증 시나리오만 정의한다.

## 1. 코드 생성

`ItemPatch`(freezed) 신규 생성 후:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 2. 검증 명령

```bash
flutter analyze                                  # 경고 0
flutter test test/feature/item_edit_delete_test.dart
flutter test                                     # 전체 회귀
dart run tool/check_design_tokens.dart           # 토큰 하드코딩 검사
```

## 3. 수동 시나리오 (실기기/시뮬레이터)

### 수정 (US1)

1. 옷 1점 등록(예: "코트", 아우터, 세탁 주기 5).
2. 옷장 → 타일 탭 → 상세 진입.
3. 우상단 ⋯ → "수정하기" → 명칭 "겨울 코트", 세탁 주기 +2, 사진 교체.
4. "수정 완료" → 토스트 "옷 정보를 수정했어요" → 상세 제목·사진 갱신 확인.
5. 뒤로 → 옷장 타일 이름·사진이 갱신됐는지 확인(SC-002).
6. **상태 재평가**: 착용을 4회 기록해 4/10(clean) 상태로 만든 뒤 수정에서 주기를 3으로 낮춰 저장 → 즉시 "세탁 필요" 라벨(FR-004, AC3).

### 삭제 (US2)

1. 옷 3점 등록, 그 중 1점에 착용 2회 + 세탁 완료 1회 기록.
2. 그 옷 상세 → ⋯ → "삭제하기" → 다이얼로그 "삭제" 확정.
3. 토스트 "옷을 옷장에서 삭제했어요" → 옷장 탭으로 복귀, 그리드에서 사라짐(AC1).
4. 홈 탭 → 전체 통계 3→2 확인(FR-012).
5. 세탁 바구니/홈 미리보기에 잔존 없는지 확인(AC4).
6. **취소 경로**: 다른 옷 상세 → ⋯ → 삭제 → "취소" → 아무것도 삭제되지 않고 상세 유지(AC2).

## 4. PR 체크리스트

- [ ] `flutter analyze` 경고 0
- [ ] `flutter test` 통과 (신규 `item_edit_delete_test.dart` 포함)
- [ ] `dart run tool/check_design_tokens.dart` 통과
- [ ] spec.md FR-001~014 ↔ 코드 매핑 확인
- [ ] contracts/repositories.md ↔ `ItemRepository` 구현 일치
- [ ] 헌법 4원칙 위반 없음
