# AGENTS.md — lib/data (데이터 레이어)

Isar 모델, repository 추상화·구현, Riverpod provider 배선을 담당하는 데이터 레이어다.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
data/
├── models/            # Isar @collection 모델 (item, wear_event, user_preferences) + *.g.dart
├── repositories/      # 추상 인터페이스(item_repository.dart) + Isar 구현(isar_item_repository.dart)
└── providers/
    └── app_providers.dart  # Riverpod provider 배선 (repository DI)
```

## 이 레이어의 규칙

- **스키마의 단일 진실 원천은 [data-model.md](../../specs/001-home-dashboard/data-model.md)다.**
  모델 필드·인덱스 변경은 spec 문서 갱신과 함께 진행한다.
- **repository 인터페이스는 [contracts/repositories.md](../../specs/001-home-dashboard/contracts/repositories.md) 계약을 따른다.**
  인터페이스(`*_repository.dart`)와 Isar 구현(`isar_*_repository.dart`)을 항상 분리 유지한다.
  상위 레이어(features)는 인터페이스에만 의존한다.
- 모델 수정 후에는 반드시 코드 생성을 실행한다:
  `dart run build_runner build --delete-conflicting-outputs`
  `*.g.dart`는 생성 파일이므로 직접 수정 금지.
- Isar 3.x API(`@collection`, `@Index`)를 사용한다. 4.x(Rust 기반) API 사용 금지 —
  마이그레이션은 별도 spec으로 진행한다 (pubspec.yaml 주석 참조).
- repository 로직 변경 시 in-memory Isar 인스턴스를 사용한 테스트로 검증한다.
- 이 레이어는 UI(위젯, BuildContext)를 알지 못한다. Flutter widget import 금지 (`providers/` 제외).
