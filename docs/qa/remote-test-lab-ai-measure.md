# 원격 실기기 기기 내 AI 측정 — Samsung Remote Test Lab (005 T019 Android)

Gemini Nano(ML Kit GenAI Prompt API)는 AICore가 있는 실기기에서만 돈다. 에뮬레이터 이미지에는 AICore가 없어
앱이 `unsupported`를 돌려 설정을 숨긴다(측정 불가). 지원 기기가 없으면 Samsung Remote Test Lab(무료)의 원격 Galaxy를 쓴다.

## 1. APK 만들기

```bash
python3 tool/qa/build_ai_measure_apk.py <사진 폴더(*.jpg)>   # 기본 모델 대기 15분(--wait-min)
# → build/app/outputs/flutter-apk/app-profile.apk (arm64, 약 60MB)
```

사진은 APK 안에 넣는다(원격 기기로 옮길 필요 없음). 사진·진입점은 `build/ai_measure/`에 생성되며 커밋하지 않는다.
측정 로직은 `integration_test/support/ai_measure.dart`, iOS 절차는 `integration_test/on_device_ai_measure.dart` 머리말을 본다.

## 2. 원격 기기 고르기

[Remote Test Lab](https://developer.samsung.com/remote-test-lab)에 삼성 계정으로 로그인해 Gemini Nano 지원 기기를 예약한다.
앱은 Prompt API(`GenerativeModel`)를 쓴다. Prompt API 지원 기기(2026-11 기준, developers.google.com/ml-kit/genai): Galaxy S26·S26+·S26 Ultra,
Z Fold7·Z TriFold, Z Flip8·Z Fold8·Z Fold8 Ultra, Pixel 9·10·11 등. **Galaxy S25 시리즈는 요약·이미지 설명 같은 작업 API만 지원하고
Prompt API는 지원하지 않는다**(앱에서는 `unsupported`).
기기 화면 상단의 Android 버전과 모델명을 결과와 함께 기록한다.

## 3. 실행과 결과 읽기

1. 원격 화면의 **APK 설치**(Install App)로 APK를 올린다. 설치 후 앱 "옷장이모"가 자동 실행되지 않으면 직접 연다.
2. 화면 첫 줄 `caps {…, ai: …}`를 본다.
   - `available`: 바로 측정한다.
   - `notReady`: 앱이 Gemini Nano 내려받기를 요청하고 최대 15분 기다린다(`aiWait`가 늘어남). 그동안 Wi-Fi를 유지한다.
   - `unsupported`: 이 기기는 지원하지 않는다. 다른 기기로 바꾼다.
   - `visionWait`는 배경 제거·라벨 모듈(Play 서비스) 내려받기 대기 시간이다.
3. 사진마다 `AI(cut)`(배경 제거본 입력 = 앱 실제 동작)·`AI(org)`(원본) 줄에 `종류/세부 종류 [색상] 소재 시간`이 나온다.
   `stage done`이 되면 끝이며 화면은 20분 유지된다. 스크롤하며 **스크린샷**을 남긴다.
4. 로그 뷰어가 있으면 `CLOSETIMO_MEASURE`로 걸러 사진별 JSON을 복사한다.

## 4. 기록

결과는 `docs/product/2026-11-02-ux-redesign-and-on-device-ai.md` §3.4 표 형식(정답·앱 제안·지연)으로 옮기고
`specs/005-attributes-quick-capture/tasks.md`에 기기·날짜와 함께 남긴다.

## 참고 — Galaxy A23(미지원 기기) 확인 (2026-11-04)

같은 APK로 확인: `ai: unsupported`, ML Kit 배경 제거 11/11, 사진당 0.7~0.9초. 라벨은 청바지(`denim 0.99`)·운동화·가방은 맞고,
착용 사진은 다른 옷(티셔츠 사진의 청바지 등)을 잡는다.

## 결과 — Galaxy S26 Ultra 원격 기기 (2026-11-04, 측정 실패)

SM-S948B-PL03(폴란드, Android 16, One UI 8.5). `ai: unsupported`이고, ML Kit 배경 제거·라벨 모듈도 5분 대기 안에 준비되지 않아
배경 제거 0/11·라벨 없음으로 끝났다. 기기가 Samsung·Google 계정에 로그인되어 있지 않고 "조직 소유 기기"로 관리되며,
설정 검색에 AICore가 나오지 않는다. 그래서 Play 서비스 모듈과 Gemini Nano(AICore)를 내려받지 못하는 것으로 보인다(추정).
**Remote Test Lab으로는 Gemini Nano 측정이 어렵다.** Prompt API 지원 기기 실물(S26 시리즈·Z Fold7 등)에서 이 APK를 돌린다.

- 원격 기기에서 실제 상태를 볼 수 있게 측정 화면 둘째 줄에 `aiDetail`을 띄운다(`onDeviceAiDetail`: `status=<FeatureStatus 값>`
  또는 `error=<예외>`). 이번 세션에서는 새 APK 재설치가 0%에서 멈춰 이 값을 확인하지 못했다.
- 웹 클라이언트 주의: 앱 시작(▶) 뒤 화면이 꺼질 수 있다(측면 버튼 → 위로 밀어 잠금 해제). Esc 키는 기기 뒤로 가기로 전달된다.
  같은 세션에서 APK를 다시 올리면 설치가 0%에서 멈출 수 있다.
