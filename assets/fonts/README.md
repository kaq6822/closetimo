# 폰트 자산 가이드

`design.md`의 타이포그래피 시스템은 **Manrope**(라틴) + **Inter**(라벨) + **Pretendard**(한글 폴백)을 사용합니다. 모두 SIL OFL 라이선스이므로 자유 배포 가능하지만, 라이선스 파일 보존을 위해 본 저장소에는 폰트 파일을 직접 커밋하지 않고 다운로드 가이드를 둡니다.

## 다운로드

```bash
# Pretendard (한국어 1차 폴백)
mkdir -p assets/fonts/Pretendard
curl -L -o /tmp/pretendard.zip https://github.com/orioncactus/pretendard/releases/latest/download/Pretendard-1.3.9.zip
unzip -j /tmp/pretendard.zip 'public/static/Pretendard-Regular.otf' 'public/static/Pretendard-Medium.otf' 'public/static/Pretendard-Bold.otf' -d assets/fonts/Pretendard/

# Manrope (Google Fonts)
mkdir -p assets/fonts/Manrope
curl -L -o /tmp/manrope.zip https://fonts.google.com/download?family=Manrope
unzip -j /tmp/manrope.zip 'static/Manrope-Regular.ttf' 'static/Manrope-Medium.ttf' 'static/Manrope-Bold.ttf' -d assets/fonts/Manrope/

# Inter (rsms)
mkdir -p assets/fonts/Inter
curl -L -o /tmp/inter.zip https://github.com/rsms/inter/releases/latest/download/Inter-4.1.zip
unzip -j /tmp/inter.zip 'Inter Desktop/Inter-Regular.ttf' 'Inter Desktop/Inter-Medium.ttf' -d assets/fonts/Inter/
```

## 등록

위 단계 완료 후 `pubspec.yaml`의 `flutter.fonts:` 섹션 주석을 해제하고 `flutter pub get`을 다시 실행하세요.

## 현재 상태

폰트 파일이 등록되지 않은 상태에서는 Flutter가 OS 시스템 폰트로 자동 폴백합니다. 텍스트 가독성에는 문제가 없으나, 디자인 시스템의 시각적 일관성은 폰트 등록 후에야 완전히 달성됩니다. 본 항목은 v1.0 release 전 마무리 task로 남깁니다(spec 001 T085 PR 체크리스트).
