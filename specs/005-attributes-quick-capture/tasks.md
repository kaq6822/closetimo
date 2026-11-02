# Tasks: 005 구조화 속성·빠른 분류 등록·온디바이스 사진 분석

체크는 해당 검증 증거(테스트·빌드·실기기 기록)가 있을 때만 한다.

## 데이터

- [x] T001 Item 속성 필드·`Season`·`ItemPurpose` 확장, 카탈로그(`item_attributes.dart`) — `item_attributes_test`, `item_classification_test`
- [x] T002 `ItemFilter` 속성 축·이번 계절·속성 라벨 검색 — `item_attributes_test`
- [x] T003 저장소 생성·수정·삭제의 속성 정규화와 배경 제거본 파일 처리 — `isar_item_repository_test`
- [x] T004 백업 형식 v2(속성·배경 제거본·설정), v1 호환 — `backup_codec_test`, `backup_restore_repository_test`
- [x] T005 `UserPreferences.removeBackground`·`onDeviceAi`와 저장소 setter — `daily_flows_005_test`(설정)
- [x] T006 구 데이터 기본값 회귀 — `storage_migrator_test`

## 분석

- [x] T007 대표 색상 추출(`color_extractor.dart`) — `color_extractor_test`
- [x] T008 제안기 결합·실패 내성·AI 시간 제한·prewarm — `attribute_suggester_test`
- [x] T009 iOS 채널(배경 제거·분류·Foundation Models 스키마) + Swift↔Dart 코드 가드 — `vision_channel_catalog_test`, iOS 빌드

## 화면

- [x] T010 등록 폼: 속성 칩, 이름 자동·추론, 사진 제안(축별 출처 순위), 배경 제거본 표시·원본 사용 — `quick_capture_flow_test`
- [x] T011 여러 장 등록 → 정리하기(`/sort-items`) — `quick_capture_flow_test`
- [x] T012 홈 오늘 입은 옷·정리 대기·세탁 그룹 요약 — `daily_flows_005_test`, `quick_capture_flow_test`
- [x] T013 옷장 상세 필터(라우트 쿼리 왕복)·이번 계절·색상 점 — `daily_flows_005_test`
- [x] T014 세탁 그룹·그룹 선택 — `daily_flows_005_test`
- [x] T015 설정 사진 분석 섹션 — `daily_flows_005_test`
- [x] T016 사진 표시 공용화(`ItemPhoto`), 상세 속성 요약

## 검증

- [x] T017 `flutter analyze`·전체 `flutter test`·토큰 검사·iOS/Android debug 빌드
- [ ] T018 iOS 17+ **실기기**에서 배경 제거·분류 힌트 동작 확인
      (`integration_test/attributes_vision_test.dart`를 `--dart-define=E2E_VISION_STRICT=true`로 실행).
      2026-11-02 iPhone 17 Pro 시뮬레이터(iOS 26.5): 채널 왕복·기능 확인(배경 제거 true·분류 true·AI unsupported)·
      엔진 색상 추출(`navy`)·UI 흐름 통과, 스크린샷 `build/ios_verify_shots/005_*.png`. 단, 시뮬레이터는 Vision 신경망
      요청을 실행하지 못해(`Failed to create espresso context`) 배경 제거·분류는 빈 결과로 돌아왔다(오류 내성 경로 확인).
      같은 Vision 코드는 macOS 26.6에서 11/11 피사체 분리를 확인했다.
- [ ] T019 Xcode 27로 빌드해 iOS 27 Apple Intelligence 실기기에서 기기 내 AI 분석 정확도·지연 측정
      (`Attachment(imageURL:)` 시그니처 확인 포함, 시뮬레이터는 이미지 분석 미지원)
- [ ] T020 Android 실기기 QA(색상 추천·여러 장 등록·정리하기) — docs/qa/android-qa-runbook.md
- [ ] T021 소규모 사용성 평가로 SC-501~503 확인(입력 시간·찾기 시간)

## 별도 검토(이번 범위 밖)

- Android 온디바이스 AI(ML Kit GenAI·Gemini Nano): 사용자가 켜는 실험 기능 여부와 헌법 III 예외 승인.
