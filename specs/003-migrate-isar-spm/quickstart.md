# Quickstart: 로컬 데이터 엔진 장기 호환성 검증

## 사전 조건

- Flutter 3.44 stable 이상
- Xcode와 iOS Simulator
- Android SDK
- SwiftPM 비활성화 설정을 사용하지 않은 환경

이 프로젝트의 iOS plugin 의존성은 SwiftPM만 사용한다. `Podfile`과 Pods workspace 참조는 제거되어 CocoaPods 설치가 필요하지 않다.

## 의존성 및 생성 코드

```bash
flutter pub get
dart run build_runner build
```

예상 결과:

- `isar_plus`, `isar_plus_flutter_libs`가 동일 버전으로 해석된다.
- 앱 모델의 생성 코드가 최신 schema 형식으로 생성된다.
- 루트 package에서 구형 `isar_generator`가 해석되지 않는다.

## 자동화 검증

```bash
flutter analyze
flutter test
```

예상 결과:

- 경고·오류 0건
- 실제 legacy fixture를 사용한 이전 테스트를 포함해 전체 테스트 통과
- 두 번 이전 호출 후에도 레코드 수와 값이 동일

## Apple 빌드

```bash
flutter build ios --no-codesign --debug 2>&1 | tee /tmp/closetimo-ios-build.log
```

예상 결과:

- `Runner.app` 생성
- `do not support Swift Package Manager` 문구 0건
- `FlutterGeneratedPluginSwiftPackage`를 통해 두 native core가 링크됨
- 앱 bundle의 `Frameworks/libisar_legacy.dylib`에서 legacy core를 동적으로 로드함

legacy 동적 XCFramework를 원본 Isar 3 archive에서 다시 만들 때는 생성물 디렉토리 하나만 제거한 뒤 다음 명령을 실행하고 `BINARY_CHECKSUMS.sha256`을 갱신한다.

```bash
packages/isar_flutter_libs/tool/build_darwin_xcframework.sh
```

## Android 빌드

```bash
flutter build apk --debug
```

예상 결과:

- API 24+ 호환 debug APK 생성
- legacy plugin namespace 임시 주입 없이 성공

## 실제 업데이트 시나리오

1. 이전 버전 앱에서 사진이 있는 의류와 없는 의류를 등록한다.
2. 착용 기록과 세탁 기록을 만들고 알림 설정을 변경한다.
3. 같은 Simulator의 앱 데이터를 유지한 채 새 빌드를 설치한다.
4. 첫 실행에서 의류·이벤트·설정과 이미지가 모두 유지되는지 확인한다.
5. 앱을 강제 종료하고 다시 실행한다.
6. 두 번째 실행이 이전 작업을 반복하지 않고 모든 기능이 정상 동작하는지 확인한다.

## 신규 설치 시나리오

1. 앱을 삭제해 Simulator 데이터를 초기화한다.
2. 새 빌드를 설치하고 실행한다.
3. 빈 홈이 표시되는지 확인한다.
4. 등록 → 착용 → 세탁 → 수정 → 삭제 흐름을 네트워크 없이 수행한다.

## 2026-07-25 검증 결과

- 환경: Flutter 3.44.6, iPhone 17 Pro / iOS 26.5 Simulator
- 자동화: `flutter analyze` 경고·오류 0건, 전체 68개 테스트, 디자인 토큰 검사 통과
- 빌드: iOS `Runner.app`과 Android API 24+ `app-debug.apk` 생성, SwiftPM 미지원 경고·중복 native 심볼·Android namespace 오류 0건
- 신규 설치: 빈 홈, 의류 등록, 착용 기록, 세탁 바구니 추가·완료, 설정 변경, 강제 종료 후 의류·설정 영속성을 확인했다. iOS 시스템 앨범 선택기 실행과 Simulator 사진 목록 표시도 확인했다.
- 업데이트 설치: 실제 Isar 3 `closetimo.isar` fixture를 앱 Documents에 배치하고 첫 실행 이전을 수행했다. 의류 ID·이름·브랜드·세탁 방법·착용 횟수·최근 세탁일·세탁 바구니 상태·착용 이벤트 메모가 UI에 그대로 표시됐다. 보존된 Documents 이미지 경로에 fixture 이미지를 배치한 뒤 목록과 수정 화면의 이미지 표시도 확인했다.
- 업데이트 재실행: `source=alreadyMigrated, items=1, events=1` 로그와 동일한 UI 상태를 확인해 이전이 반복되지 않음을 검증했다.
- 수정·삭제: 이전된 의류를 실제 UI에서 수정해 상세 화면 반영과 성공 안내를 확인했다. 이어 삭제 확인 창에서 삭제한 뒤 옷장 빈 상태, 연관 기록 제거 및 Documents의 이미지 파일 제거를 확인했다. 동일 흐름은 자동화 회귀 테스트로도 검증했다.

## legacy 제거 조건

`packages/isar`, `packages/isar_flutter_libs`, `packages/closetimo_legacy_isar`와 `closetimo.isar` 읽기 경로는 이번 전환 릴리스에서 유지한다. 서버·분석 도구가 없는 제품 특성상 현장 이전율을 계측할 수 없으므로 다음 조건을 모두 충족할 때만 별도 spec에서 제거한다.

1. 최소 한 번의 주요 앱 릴리스 동안 직접 업데이트 경로를 제공했다.
2. 제품 지원 정책이 Isar 3 버전에서의 직접 업데이트 지원 종료를 명시적으로 승인했다.
3. 제거 릴리스의 회귀 테스트와 출시 노트가 구형 앱을 건너뛴 사용자의 데이터 처리 방침을 포함한다.

사용자 디바이스의 원본 `closetimo.isar` 파일은 legacy 코드 제거와 별개로 자동 삭제하지 않는다.
