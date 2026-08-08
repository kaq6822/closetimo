# 폰트 자산 가이드

`design.md`의 타이포그래피 시스템은 **Manrope**(라틴) + **Inter**(라벨) + **Pretendard**(한글 폴백)을 사용합니다. 모두 SIL OFL 라이선스라 재배포가 허용되므로, 각 디렉토리의 `OFL.txt`와 함께 **폰트 파일을 저장소에 직접 커밋합니다**. (과거 "로컬 다운로드 후 pubspec 주석 해제" 방식은 폰트가 없는 신규 체크아웃·CI에서 `flutter build`가 asset 누락으로 실패해 폐기했습니다.)

## 다운로드 (재설치·업데이트 시에만 필요)

```bash
# Pretendard (한국어 1차 폴백)
mkdir -p assets/fonts/Pretendard
curl -L -o /tmp/pretendard.zip https://github.com/orioncactus/pretendard/releases/latest/download/Pretendard-1.3.9.zip
unzip -j /tmp/pretendard.zip 'public/static/Pretendard-Regular.otf' 'public/static/Pretendard-Medium.otf' 'public/static/Pretendard-Bold.otf' -d assets/fonts/Pretendard/

# Manrope (google-webfonts-helper — Google Fonts 직접 다운로드 URL은 폐지됨)
mkdir -p assets/fonts/Manrope
curl -L -o /tmp/manrope.zip "https://gwfh.mranftl.com/api/fonts/manrope?download=zip&subsets=latin,latin-ext&variants=regular,500,700&formats=ttf"
unzip -j /tmp/manrope.zip -d /tmp/manrope/
mv /tmp/manrope/manrope-*-regular.ttf assets/fonts/Manrope/Manrope-Regular.ttf
mv /tmp/manrope/manrope-*-500.ttf assets/fonts/Manrope/Manrope-Medium.ttf
mv /tmp/manrope/manrope-*-700.ttf assets/fonts/Manrope/Manrope-Bold.ttf

# Inter (rsms — static TTF가 포함된 마지막 릴리스는 v3.19,
# v4.x 릴리스에는 variable/ttc만 있어 pubspec 정적 등록에 부적합)
mkdir -p assets/fonts/Inter
curl -L -o /tmp/inter.zip https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip
unzip -j /tmp/inter.zip 'Inter Hinted for Windows/Desktop/Inter-Regular.ttf' 'Inter Hinted for Windows/Desktop/Inter-Medium.ttf' -d assets/fonts/Inter/
```

## 등록

`pubspec.yaml`의 `flutter.fonts:` 섹션에 이미 등록되어 있습니다. 폰트 파일을 교체한 경우 `flutter pub get` 후 재빌드하면 반영됩니다.
