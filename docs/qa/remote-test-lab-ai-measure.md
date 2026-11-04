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
ML Kit GenAI 지원 목록(2026-11 기준): Galaxy S25·S26 시리즈, Z Fold7, Z Flip8·Z Fold8 등.
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
