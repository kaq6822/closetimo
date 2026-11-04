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
- [x] T018 iOS 17+ **실기기**에서 배경 제거·분류 힌트 동작 확인
      (`integration_test/attributes_vision_test.dart`를 `--dart-define=E2E_VISION_STRICT=true`로 실행).
      2026-11-02 iPhone 17 Pro 시뮬레이터(iOS 26.5): 채널 왕복·기능 확인(배경 제거 true·분류 true·AI unsupported)·
      엔진 색상 추출(`navy`)·UI 흐름 통과, 스크린샷 `build/ios_verify_shots/005_*.png`. 단, 시뮬레이터는 Vision 신경망
      요청을 실행하지 못해(`Failed to create espresso context`) 배경 제거·분류는 빈 결과로 돌아왔다(오류 내성 경로 확인).
      같은 Vision 코드는 macOS 26.6에서 11/11 피사체 분리를 확인했다.
      2026-11-03 **iPhone 15 Pro 실기기(iOS 27.0.1)**, Xcode 26.6 profile 빌드, `E2E_VISION_STRICT=true`: 채널 테스트(기능 확인·
      배경 제거본 생성·배경 제거본/원본 색상 `navy`)와 UI 흐름 2/2 통과. 터미널(Orca)에 로컬 네트워크 권한이 없어 `flutter drive`
      대신 결과를 앱 Documents에 쓰는 임시 래퍼로 실행했고, 드라이버 없이 찍힌 스크린샷은 실행 화면만 담겨 증거에서 뺐다.
      Xcode 26.6 빌드라 기기 내 AI는 unsupported(설계대로)이며 T019에서 따로 확인한다.
- [x] T019 Xcode 27로 빌드해 iOS 27 Apple Intelligence 실기기에서 기기 내 AI 분석 정확도·지연 측정
      (`Attachment(imageURL:)` 시그니처 확인 포함, 시뮬레이터는 이미지 분석 미지원)
      2026-11-04 iPhone 15 Pro(iOS 27.0.1), Xcode 27.2(Swift 6.4.2) profile 빌드, `integration_test/on_device_ai_measure.dart`:
      이미지 입력 경로 컴파일·`onDeviceAi = available`. 11장(§3.1 세트) 기준 앱 최종 제안(배경 제거본 입력)
      종류 9/11·세부 종류 9/11(지시문 보강 전 세부 종류 5/11), 지연 첫 호출 5.5~7.1초·이후 2.4~4.0초(20초 제한 안).
      틀린 2장(후드·스커트)은 모두 착용 사진이다. 결과: docs/product/2026-11-02-ux-redesign-and-on-device-ai.md §3.4.
      반영: 세부 종류 지시문 보강(knit/jumper/cardigan 구분, iOS·Android), 상의↔아우터 충돌 시 세부 종류 우선(`fromDescription`).
      Xcode 27 최소 배포 버전에 맞춰 iOS 13→15.
- [ ] T020 Android 실기기 탐색 QA(사진 선택·여러 장 등록·정리하기를 실제 사진으로) — docs/qa/android-qa-runbook.md
      2026-11-03 Galaxy A23 흐름 QA 통과(결함 0, 크래시 0) — docs/qa/reports/2026-11-03-android-005-exploratory.md.
      합성 이미지로 진행해 실제 옷 사진의 종류·소재 제안 정확도는 남았다(남색→"파랑" 제안 관찰 포함).
- [ ] T021 소규모 사용성 평가로 SC-501~503 확인(입력 시간·찾기 시간)

## Android 기기 내 사진 분석 (헌법 1.1.0 예외, 2026-11-02 사용자 승인)

- [x] T023 헌법 원칙 III 예외 조항(1.1.0)·AGENTS 로컬 우선 규칙 갱신
- [x] T024 Kotlin 채널(배경 제거·라벨·Gemini Nano)과 MainActivity 등록, ML Kit 의존성·manifest — Android debug 빌드
- [x] T025 Dart 채널 Android 지원·허용 값 목록 전달·ML Kit 라벨/소재 힌트 — `native_vision_channel_test`, `attribute_suggester_test`
- [x] T026 설정의 ML Kit 진단 정보 안내·모델 준비 중 토글 — `daily_flows_005_test`
- [x] T022 Android 실기기 E2E — 2026-11-03 Galaxy A23(SM-A235N, Android 14), `--dart-define=E2E_VISION_STRICT=true`:
      기능 확인(배경 제거 true·라벨 true·Gemini Nano unsupported), ML Kit 배경 제거본 생성·색상 `navy`, Gemini Nano 미지원 시
      UnsupportedError, UI 흐름 통과. 스크린샷 `build/android_verify_shots/005_*.png`(설정 진단 정보 안내 포함).
      이 기기는 Gemini Nano 미지원이라 기기 내 AI 응답 품질은 지원 기기(Galaxy S26·Z Fold7 등)에서 따로 확인한다.
- [x] T027 공개 개인정보처리방침(kaq6822/smulsmul) 반영 — 2026-11-03 kaq6822/smulsmul#4·#5 병합·배포
      (국문·영문 3항 "사진 분석" 신설, 제3자 서비스 항목에 ML Kit 명시). 문안: docs/release/privacy-policy-mlkit-update.md
- [ ] T028 Play Console 데이터 보안 양식에 ML Kit 수집 항목 반영(콘솔 접근 필요, 출시 전) — 확인 항목은 위 문안 문서 참조
