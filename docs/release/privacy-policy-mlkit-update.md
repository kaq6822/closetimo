# 개인정보처리방침 반영 문안 — Android 기기 내 사진 분석(ML Kit)

**대상**: 공개 개인정보처리방침 `https://kaq6822.github.io/smulsmul/apps/closetimo/privacy/`(저장소 `kaq6822/smulsmul`)
**근거**: 헌법 1.1.0 원칙 III 예외, spec 005 FR-520
**상태**: 공개 페이지 반영 완료(2026-11-03, kaq6822/smulsmul#4 — 국문·영문 3항 "사진 분석"). Play Console 데이터 보안 양식은 출시 전에 콘솔에서 직접 갱신한다(T028).

## 추가할 문단(안)

### 사진 분석과 Google ML Kit (Android)

옷장이모는 사진에서 배경을 지우고 옷의 종류·색상·소재를 제안하기 위해 Google ML Kit을 사용합니다.
사진 분석은 모두 기기 안에서 이루어지며, 사진과 옷장 기록은 Google이나 다른 서버로 전송되지 않습니다.

다만 ML Kit은 기능 개선과 진단을 위해 다음 정보를 Google에 전송할 수 있습니다.

- 기기 정보(제조사, 모델, OS 버전, 사용 가능한 하드웨어 가속기)
- 앱 정보(패키지 이름, 앱 버전)
- 기능 사용 정보(기능 종류·버전, 설정, 처리 지연 시간, 입력·출력 크기, 오류 코드, 기기 내 AI 사용 시 설정 언어)
- 기기·설치 단위 식별자(기기 내 AI 사용 시 Google이 정한 이용자·기기 식별자 포함)

또한 분석 모델은 Google Play 서비스를 통해 내려받습니다. 지원 기기에서 "기기 내 AI로 자세히 분석"을 켜면
Gemini Nano 모델을 사용하며, 이 기능도 사진을 기기 밖으로 보내지 않습니다.
자세한 내용은 Google의 ML Kit 데이터 공개 문서(https://developers.google.com/ml-kit/android-data-disclosure)를 참고하세요.

iOS에서는 Apple Vision·Foundation Models을 기기 안에서만 사용하며 별도 정보를 전송하지 않습니다.

## Play Console 데이터 보안 양식(T028, 출시 전 콘솔에서 직접 입력)

[ML Kit 데이터 공개 문서](https://developers.google.com/ml-kit/android-data-disclosure) 기준(2026-11-03 확인). 문서는 Play 범주명을 직접 주지 않으므로 아래 대응은 제안이다.

| Play 범주 | 수집 | 근거 | 목적 |
|---|---|---|---|
| 앱 정보 및 성능 › 진단 | 예 | 기기·앱 정보, 지연 시간, API 설정, 입력·출력 크기, 오류 코드 | 분석(Analytics)·앱 기능 |
| 기기 또는 기타 ID | 예 | 설치 단위 식별자(GenAI는 이용자·기기 식별자) | 분석(Analytics) |
| 사진·동영상 | 아니요 | 사진은 기기 밖으로 전송하지 않음 | — |

- 공유(제3자 전송): 아니요 — ML Kit은 이 데이터를 제3자에게 넘기지 않는다고 명시.
- 전송 중 암호화: 예(HTTPS). 삭제 요청: 앱이 보관하지 않으므로 Google 처리 방침을 안내.
- 필수/선택: ML Kit 진단은 사용자가 끌 수 없으므로 "필수"로 둔다.
