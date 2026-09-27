# Closetimo 브랜드 이미지

이 디렉터리에는 출시용 원본 브랜드 이미지를 보관한다. 2026-09-27에 확정한 **B1 미소 옷걸이** 디자인이다.

- `closetimo-app-icon-1024.png`: App Store 및 Google Play 등록용 원본 앱 아이콘 (세이지 배경 + 아이보리 심볼)
- `closetimo-brand-symbol.png`: 한글 워드마크를 제외한 미소 옷걸이 심볼 (투명 배경)
- `closetimo-launch-logo.png`: 런치 화면용 원본 로고 (아이보리 배경 + 세이지 심볼)
- `closetimo-play-feature-graphic-1024x500.png`: Google Play 피처 그래픽 (심볼 + "옷장이모" 워드마크, Pretendard Bold)

## 브랜드 색상

앱 디자인 토큰(`lib/app/theme/tokens.dart`)과 같은 값을 쓴다.

| 용도 | 색상 | 토큰 |
|---|---|---|
| 심볼·아이콘 배경 | `#47645E` 세이지 | `ClosetimoColors.primary` |
| 배경·아이콘 심볼 | `#FAFAF5` 아이보리 | `ClosetimoColors.surface` |
| 워드마크 | `#2E342D` 차콜 | `ClosetimoColors.ink` |

## 플랫폼 반영 위치

아래 리소스는 모두 이 원본에서 내보낸 것이다. 원본을 바꾸면 함께 다시 내보낸다.
심볼 파생 리소스는 `closetimo-brand-symbol.png`의 알파 마스크를 트림한 뒤 위 브랜드 색으로 채워 만든다.

- iOS 앱 아이콘: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (알파 채널 없음, 1024는 정확히 1024px)
- iOS 런치: `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (세이지 심볼 128pt) + `LaunchScreen.storyboard` 배경 `#FAFAF5`
- Android 레거시 아이콘: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Android 적응형 아이콘(API 26+): `mipmap-anydpi-v26/ic_launcher.xml` — 배경 `@color/ic_launcher_background`,
  전경 `mipmap-*/ic_launcher_foreground.png`(108dp 캔버스에 폭 50dp 아이보리 심볼, 테마 아이콘용 monochrome 겸용)
- Android 런치: `drawable-*/launch_logo.png`(세이지 심볼 128dp) + `values/launch_colors.xml`,
  Android 12+ 시스템 스플래시는 `values-v31/styles.xml`, `values-night-v31/styles.xml`
- 앱 내 상단바 심볼: `assets/images/closetimo_symbol.png` (+ `2.0x/`, `3.0x/`, 28pt 폭) — `TopBar` 브랜드 모드에서 사용
