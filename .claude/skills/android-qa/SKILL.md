---
name: android-qa
description: 옷장이모 Android 출시 전/회귀 QA. 실기기(없으면 에뮬레이터)에서 정적 분석→빌드 점검→E2E→android CLI 탐색 QA→환경 변화를 수행하고 docs/qa/reports/에 리포트를 남긴다. "안드로이드 QA", "실기기 QA", "출시 전 QA", "android 회귀 테스트" 요청 시 사용.
---

# Android QA

절차의 단일 원본은 [docs/qa/android-qa-runbook.md](../../../docs/qa/android-qa-runbook.md)다. 이 스킬은 순서만 고정한다.

1. 런북 전체와 `docs/qa/reports/`의 **최신 리포트**를 읽는다. 미해결 결함 목록을 이번 회차 재확인 대상으로 잡는다.
2. `android-cli` 스킬을 로드한다(`android layout`, `android screen capture` 사용법).
3. 런북 §2 레이어 순서대로 진행한다. 앞 레이어 실패 시 멈추고 보고한다.
   - E2E: `tool/qa/run_android_e2e.sh`
   - 탐색 QA: `source tool/qa/android_qa.sh && qa_install_release` 후 §4 체크리스트
4. 기기는 사용자의 개인 폰일 수 있다. 입력은 반드시 헬퍼(`tap`/`tapxy`/`back`/`hide_kb`)로만 보내
   `guard()`를 거치게 한다. `adb shell input`을 직접 호출하지 않는다.
5. 바꾼 기기 설정은 원래 값으로 복원하고, 끝나면 `git status`로 툴체인이 자동 수정한 파일을 확인한다.
6. 런북 §8 형식으로 `docs/qa/reports/YYYY-MM-DD-android-<목적>.md`를 작성한다.
   새로 겪은 하네스 함정은 런북 §6에 추가한다.
