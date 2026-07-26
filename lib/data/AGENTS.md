# AGENTS.md — lib/data (데이터 레이어)

Isar 모델, repository 추상화·구현, Riverpod provider 배선을 담당하는 데이터 레이어다.
프로젝트 공통 규칙(언어·테스트·빌드 검증)은 루트 [AGENTS.md](../../AGENTS.md)를 따른다.

## 구조

```text
data/
├── migrations/        # Isar 3 → Isar Plus 일회성 로컬 데이터 이전
├── models/            # Isar Plus @collection 모델 + *.g.dart
├── repositories/      # 추상 인터페이스(item_repository.dart) + Isar 구현(isar_item_repository.dart)
└── providers/         # Isar 인스턴스와 repository Riverpod 배선
```

## 이 레이어의 규칙

- **스키마의 단일 진실 원천은 [data-model.md](../../specs/001-home-dashboard/data-model.md)다.**
  모델 필드·인덱스 변경은 spec 문서 갱신과 함께 진행한다.
- **repository 인터페이스는 [contracts/repositories.md](../../specs/001-home-dashboard/contracts/repositories.md) 계약을 따른다.**
  인터페이스(`*_repository.dart`)와 Isar 구현(`isar_*_repository.dart`)을 항상 분리 유지한다.
  상위 레이어(features)는 인터페이스에만 의존한다.
- 모델 수정 후에는 반드시 코드 생성을 실행한다:
  `dart run build_runner build`
  `*.g.dart`는 생성 파일이므로 직접 수정 금지.
- 앱 모델과 repository는 Isar Plus 1.3.x API를 사용한다. 구형 Isar 3 타입은
  `packages/closetimo_legacy_isar` 밖으로 노출하지 않는다.
- 새 저장소 이름은 `closetimo_plus`로 고정하고, 이전 원본 `closetimo` 저장소는 삭제하거나
  직접 열어 쓰지 않는다. 이전 정책은 `specs/003-migrate-isar-spm/`을 따른다.
- repository 로직 변경 시 in-memory Isar 인스턴스를 사용한 테스트로 검증한다.
- 이 레이어는 UI(위젯, BuildContext)를 알지 못한다. Flutter widget import 금지 (`providers/` 제외).
