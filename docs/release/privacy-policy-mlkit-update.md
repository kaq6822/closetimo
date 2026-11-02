# 개인정보처리방침 반영 문안 — Android 기기 내 사진 분석(ML Kit)

**대상**: 공개 개인정보처리방침 `https://kaq6822.github.io/smulsmul/apps/closetimo/privacy/`(저장소 `kaq6822/smulsmul`)
**근거**: 헌법 1.1.0 원칙 III 예외, spec 005 FR-520
**상태**: 문안 준비. 공개 페이지 반영은 다른 저장소 작업이라 이 PR에 포함하지 않았다. Play Console 데이터 보안 양식도 함께 확인한다.

## 추가할 문단(안)

### 사진 분석과 Google ML Kit (Android)

옷장이모는 사진에서 배경을 지우고 옷의 종류·색상·소재를 제안하기 위해 Google ML Kit을 사용합니다.
사진 분석은 모두 기기 안에서 이루어지며, 사진과 옷장 기록은 Google이나 다른 서버로 전송되지 않습니다.

다만 ML Kit은 기능 개선과 진단을 위해 다음 정보를 Google에 전송할 수 있습니다.

- 기기 정보(제조사, 모델, OS 버전, 사용 가능한 하드웨어 가속기)
- 앱 정보(패키지 이름, 앱 버전)
- 기능 사용 정보(기능 종류·버전, 처리 지연 시간, 입력·출력 크기, 오류 코드)

또한 분석 모델은 Google Play 서비스를 통해 내려받습니다. 지원 기기에서 "기기 내 AI로 자세히 분석"을 켜면
Gemini Nano 모델을 사용하며, 이 기능도 사진을 기기 밖으로 보내지 않습니다.
자세한 내용은 Google의 ML Kit 데이터 공개 문서(https://developers.google.com/ml-kit/android-data-disclosure)를 참고하세요.

iOS에서는 Apple Vision·Foundation Models을 기기 안에서만 사용하며 별도 정보를 전송하지 않습니다.

## Play Console 데이터 보안 확인 항목

- "기기 또는 기타 ID"·"앱 상호작용/진단" 수집 여부를 ML Kit 공개 문서 기준으로 재검토한다(제3자 SDK 수집 포함).
- 데이터는 전송 중 암호화(HTTPS)되며 판매되지 않는다(ML Kit 문서 기준).
