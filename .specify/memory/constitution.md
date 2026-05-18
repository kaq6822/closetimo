<!--
SYNC IMPACT REPORT
==================
Version change: TEMPLATE → 1.0.0 (initial ratification)
Modified principles: N/A (initial drafting from template)
Added sections:
- Core Principles (4 principles, reduced from template's 5-slot example)
- Product Constraints
- Development Workflow
- Governance
Removed sections: N/A
Templates requiring updates:
- ✅ .specify/templates/plan-template.md (Constitution Check gate compatible with 4-principle structure)
- ✅ .specify/templates/spec-template.md (no structural conflict)
- ✅ .specify/templates/tasks-template.md (no structural conflict)
Follow-up TODOs: None — `.specify/memory/temp_srd.md` deletion scheduled per Product Constraints once first spec lands.
-->

# 옷장이모(Closetimo) Constitution

## Core Principles

### I. 큐레이션 우선 사용자 흐름 (NON-NEGOTIABLE)
사용자는 옷장을 "관리"하는 것이 아니라 "큐레이션"하는 경험을 해야 한다. 부가 입력 필드는
선택 항목으로 둔다. 사용자의 작업 단계를 늘리는 변경은 동등 이상의 가치를 spec
단계에서 명시적으로 정당화해야 한다.

**Rationale**: 옷장이모는 의류 관리 부담을 줄이기 위한 도구이지, 또 하나의 입력
부담이 되어서는 안 된다.

### II. 디자인 시스템 일관성
모든 UI 변경은 `.specify/memory/design.md`("The Digital Atelier" 디자인 시스템)에
정의된 토큰과 규칙을 따라야 한다. 1px 솔리드 디바이더 금지, 토널 레이어링을 통한
영역 구분, Manrope/Inter 타이포그래피 페어링, Sage 액센트(`primary #47645e`) 사용
규칙은 비협상 사항이다. 디자인 시스템 외 색상·간격·라운딩을 도입하려면 design.md를
먼저 개정해야 한다.

**Rationale**: "프리미엄 부티크" 느낌은 일관된 토큰의 누적 효과로 달성된다.
일회성 예외는 시스템 전체의 가치를 희석시킨다.

### III. 로컬 우선 데이터 소유권
사용자의 의류·착용·세탁 기록은 기본적으로 디바이스 로컬 저장소에 보관한다.
백업은 사용자가 명시적으로 트리거하는 iCloud(iOS) 또는 Google Drive(Android)
경로만 허용한다. 서버 동기화, 계정 시스템, 외부 분석 SDK는 본 헌법의 개정 없이
도입할 수 없다.

**Rationale**: 옷장 데이터는 개인적 생활 기록이다. 기본값을 로컬로 두는 것이
신뢰와 단순성을 동시에 확보하는 가장 짧은 길이다.

### IV. Spec 주도 변경 관리
모든 기능 변경은 `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` 워크플로의
산출물(`spec.md`, `plan.md`, `tasks.md`)을 통해 기록되어야 한다. 코드 변경 PR은
대응되는 feature 폴더의 spec·plan 산출물을 참조해야 하며, 산출물 없이 머지될 수
없다.

**Rationale**: 단일 개발자·소규모 팀일수록 결정의 이유가 휘발되기 쉽다.
Spec Kit 산출물은 미래의 자신과 협업자에게 보내는 가장 저렴한 메모이다.

## Product Constraints

- **타깃 플랫폼**: 모바일(iOS, Android).
- **기본 언어**: 한국어 UI를 1차 지원한다. 다국어는 별도 spec으로 도입한다.
- **오프라인 동작**: 옷 등록, 검색, 착용 기록, 세탁 처리는 네트워크 없이 동작해야
  한다.
- **임시 문서 처리**: `.specify/memory/temp_srd.md`는 첫 feature spec
  (`specs/*/spec.md`) 작성 완료 시점에 삭제한다.

## Development Workflow

- **Branch & Commit**: 새 feature는 `/speckit-git-feature`로 생성된 브랜치에서
  진행하며, 각 speckit 단계 종료 시 `/speckit-git-commit` 훅을 통해 커밋한다.
- **Constitution Gate**: `/speckit-plan` 단계의 "Constitution Check"는 위 4개
  원칙을 모두 통과해야 한다. 통과하지 못하는 항목은 plan의 `Complexity Tracking`
  표에 정당화 사유와 함께 기록한다.
- **리뷰 책임**: 단독 작성자가 자기 PR을 self-approve할 수 없다. 최소 1회의 외부
  리뷰 또는 별도 세션에서의 reviewer agent 검증을 거친다.

## Governance

본 헌법은 옷장이모 프로젝트의 모든 다른 관행보다 우선한다. 개정은 다음 절차를
따른다.

1. 개정 제안은 `.specify/memory/constitution.md`에 대한 PR로 제출한다.
2. 버전 번호는 다음 규칙으로 증가시킨다.
   - **MAJOR**: 원칙의 제거 또는 호환되지 않는 재정의.
   - **MINOR**: 새 원칙·섹션 추가 또는 가이드의 실질적 확장.
   - **PATCH**: 문구 다듬기, 오탈자, 비의미적 정리.
3. 개정과 동시에 `.specify/templates/*` 및 관련 가이던스 문서의 정합성을
   점검·갱신한다.
4. 모든 PR 리뷰는 본 헌법 준수 여부를 명시적으로 확인한다.

**Version**: 1.0.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-05-18
