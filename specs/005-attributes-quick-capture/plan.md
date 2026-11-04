# Implementation Plan: 구조화 속성·빠른 분류 등록·온디바이스 사진 분석

**Branch**: `feat/005-wardrobe-attributes-ai` | **Date**: 2026-11-02 | **Spec**: [spec.md](./spec.md)

## Summary

타이핑 중심 입력을 칩 선택과 사진 제안으로 바꾼다. 데이터 계층에 문자열 코드 기반 속성 카탈로그를 두고, 사진 분석은
`AttributeSuggester`가 (iOS) Vision 배경 제거·분류 → 순수 Dart 색상 추출 → (선택) Foundation Models 순서로 제안을 만든다.
화면은 등록 폼·정리하기·홈 오늘 입은 옷·옷장 상세 필터·세탁 그룹·설정 사진 분석을 바꾼다.

## Technical Context

**새 패키지 없음.** 색상 추출은 엔진 코덱(`dart:ui`)으로 64px 디코딩 후 순수 Dart k-means로 계산한다. iOS 분석은 Runner의 Swift
`MethodChannel`(`ios/Runner/ClosetimoVisionChannel.swift`)로 직접 구현하고 서드파티 플러그인을 쓰지 않는다(헌법 III).

| 기능 | 기술 | 조건 | 검증 |
|---|---|---|---|
| 배경 제거 | Vision `VNGenerateForegroundInstanceMaskRequest` | iOS 17+ | 맥 실측 11/11 분리, 23~30ms |
| 분류 힌트 | Vision `VNClassifyImageRequest`(라벨 1,303개) | iOS 13+ | 맥 실측: 청바지·운동화·후드 정확, 셔츠·스웨터·스커트 라벨 없음 |
| 색상 추출 | `dart:ui` 디코딩 + CIELAB k-means | 전 기기 | 단위 테스트 + 맥 실측(제품 사진 정확) |
| 기기 내 AI | Foundation Models `@Generable` + `Attachment`(이미지) | iOS 27 SDK·Apple Intelligence 기기 | 스키마는 macOS 26에서 텍스트로 실측(코트·울·체크 정확, 1.3~15.4초). 이미지 입력은 2026-11-04 iPhone 15 Pro(iOS 27) 실측: 종류·세부 종류 9/11, 2.4~4.0초(첫 호출 5.5~7.1초) |

**빌드 조건**: 이미지 입력 코드는 `#if canImport(FoundationModels) && compiler(>=6.4)`로 감싼다. Xcode 26.x(Swift 6.3)
빌드에서는 컴파일되지 않고 `onDeviceAi = unsupported`를 돌려 설정을 숨긴다. 2026-11-04부터 Xcode 27.2(Swift 6.4.2)로 빌드하며
이 경로가 컴파일된다(`Attachment(imageURL:)` 시그니처 확인). Xcode 27은 최소 배포 버전 iOS 15를 요구해 13→15로 올렸다.
FoundationModels는 약한 링크(`LC_LOAD_WEAK_DYLIB`)로 확인해 iOS 26 미만 기기에서도 실행된다.

**Android**(헌법 1.1.0 예외): `android/app/src/main/kotlin/com/closetimo/app/ClosetimoVisionChannel.kt`가 같은 채널을 구현한다.

| 기능 | 의존성 | 비고 |
|---|---|---|
| 배경 제거 | `play-services-mlkit-subject-segmentation:16.0.0-beta1` | Play 서비스 모듈. 설치 시 meta-data로 미리 받고, 없으면 `ModuleInstall`로 요청 |
| 라벨 | `play-services-mlkit-image-labeling:16.0.8` | 종류·소재 힌트 |
| 기기 내 AI | `genai-prompt:1.0.0-beta4` | API 26+(manifest `overrideLibrary` + 런타임 확인), AICore 지원 기기. JSON 응답을 Dart가 검증 |

ML Kit은 기능 진단 정보를 Google에 보내므로 설정 안내와 개인정보처리방침([반영 문안](../../docs/release/privacy-policy-mlkit-update.md))을 함께 둔다.

## 구조

```text
lib/data/models/item.dart                     # 필드 추가, Season, ItemPurpose 확장, displayImagePath
lib/data/models/item_attributes.dart          # 카탈로그·정규화·자동 이름·이름 추론·세탁 그룹·Vision 매핑
lib/data/models/item_filter.dart              # subTypes·colors·seasons·season 축, 속성 라벨 검색
lib/data/suggestions/attribute_suggester.dart # 사진·이름 제안 결합(실패 내성, AI 시간 제한)
lib/data/backup/backup_codec.dart             # 형식 v2
lib/core/vision/{color_extractor,native_vision}.dart
lib/core/widgets/{item_photo,color_swatch_chip}.dart
lib/features/add_item/{add_item_screen,sort_items_screen}.dart, widgets/attribute_pickers.dart
lib/features/home/widgets/{today_wear_card,sort_pending_card}.dart
lib/features/wardrobe/widgets/detail_filter_sheet.dart
lib/features/laundry/laundry_screen.dart       # 세탁 그룹
lib/features/settings/settings_screen.dart     # 사진 분석 섹션
ios/Runner/ClosetimoVisionChannel.swift
```

## 테스트

- 단위: `item_attributes_test`(카탈로그·정규화·자동 이름·추론·세탁 그룹·필터·홈 후보), `color_extractor_test`,
  `attribute_suggester_test`(단계 결합·실패·시간 초과·AI 검증), `vision_channel_catalog_test`(Swift↔Dart 코드 일치),
  `backup_codec_test`(v2·v1 호환·손 편집 정리), `storage_migrator_test`(구 데이터 기본값).
- 저장소(실제 Isar): `isar_item_repository_test`(속성·배경 제거본 생성·교체·삭제), `backup_restore_repository_test`(배경 제거본 왕복).
- 위젯: `quick_capture_flow_test`(칩 입력·이름 추론·사진 제안·여러 장 → 정리하기·정리 대기), `daily_flows_005_test`
  (오늘 입은 옷·세탁 그룹·상세 필터·이번 계절·속성 검색·설정·라우트 쿼리), `item_photo_test`(배경 제거본 → 원본 대체).
- E2E: `integration_test/attributes_vision_test.dart`(채널 왕복·색상·UI 흐름 스크린샷).
- 단위: `native_vision_channel_test`(채널 응답 해석·허용 값 전달·미지원 플랫폼).
- 실기기: Android Galaxy A23(T022), iOS 17+ 배경 제거(T018), iOS 27 Apple Intelligence 기기의 이미지 분석(T019).
