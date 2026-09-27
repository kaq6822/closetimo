# Android 릴리스 서명 — 업로드 키와 Play App Signing

옷장이모는 **Play App Signing**을 쓴다. Google이 앱 서명 키를 보관하고 사용자 기기에 배포되는
APK를 그 키로 다시 서명한다. 개발자가 로컬에 두는 것은 **업로드 키** 하나뿐이며, 이 키는
Play Console에 AAB를 올릴 때 "이 업로드가 우리 것"임을 증명하는 용도다.

| 항목 | 값 |
|---|---|
| `applicationId` | `com.closetimo.app` (게시 후 변경 불가) |
| 서명 설정 | `android/app/build.gradle.kts` `signingConfigs.release` ← `android/key.properties` |
| 키 설정 예시 | [`android/key.properties.example`](../../android/key.properties.example) |
| 커밋 금지 | `key.properties`, `*.jks`, `*.keystore` (`android/.gitignore`, 루트 `.gitignore`) |

## 1. 업로드 키스토어 만들기 (최초 1회)

키스토어는 **저장소 밖**에 만든다. 저장소 안에 두면 실수로 커밋·공유될 수 있다.

```bash
keytool -genkey -v \
  -keystore ~/closetimo-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- 비밀번호 두 개(스토어·키)와 이름(CN) 등을 묻는다. 비밀번호는 비밀번호 관리자에 저장한다.
- `.jks` 파일과 비밀번호를 **함께** 백업한다(암호화된 저장소). 둘 중 하나라도 잃으면 §5 절차가 필요하다.
- `keytool`은 JDK에 포함되어 있다. 없으면 Android Studio 번들 JDK를 쓴다:
  `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"`.

## 2. `android/key.properties` 작성

```bash
cp android/key.properties.example android/key.properties
```

```properties
storeFile=/Users/<you>/closetimo-upload.jks
storePassword=<스토어 비밀번호>
keyAlias=upload
keyPassword=<키 비밀번호>
```

- `storeFile`은 절대 경로를 권장한다(상대 경로는 `android/app/` 기준으로 해석된다).
- 네 값 중 하나라도 비어 있으면 Gradle이 `android/key.properties is missing '<name>'`으로 실패한다.
- 커밋 전 `git status`에 `key.properties`가 보이지 않는지 확인한다(`.gitignore`로 무시됨).

## 3. 빌드와 서명 확인

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# 업로드 키 인증서로 서명됐는지 확인 (CN=Android Debug 이면 안 된다)
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

### `key.properties`가 없을 때의 동작

| 명령 | 결과 |
|---|---|
| `flutter build appbundle` (`bundleRelease`) | **빌드 실패** — `Release app bundle requires an upload key.` |
| `flutter build apk --release` / `flutter run --release` (`assembleRelease`) | debug 키로 서명 + 큰 경고 배너. 로컬 QA 전용 |

스토어에 올리는 산출물은 AAB뿐이므로 AAB만 막는다. 이렇게 하면 업로드 키가 없는 개발자·에이전트도
런북 §3의 release APK 점검(L2)과 실기기 QA를 계속할 수 있고, debug 키로 서명된 AAB가 Play Console에
올라가는 사고(#11)는 빌드 단계에서 차단된다. release APK를 배포 용도로 쓰지 말 것.

## 4. Play Console 최초 등록 (Play App Signing)

1. Play Console에서 앱을 만든다(패키지 이름 `com.closetimo.app`).
2. **테스트 및 출시 → 설정 → 앱 서명**에서 "Google에서 생성한 앱 서명 키 사용"(기본값)을 선택한다.
3. 위 §3에서 만든 AAB를 첫 트랙(내부 테스트 권장)에 업로드한다. 이 첫 업로드에 쓴 키가
   **업로드 키로 등록**된다.
4. 앱 서명 페이지에서 "앱 서명 키 인증서"와 "업로드 키 인증서" SHA-256이 따로 표시되는지 확인한다.
   업로드 키 인증서 지문은 로컬에서 `keytool -list -v -keystore ~/closetimo-upload.jks -alias upload`로 대조한다.

## 5. 업로드 키 분실·유출 시

Play App Signing을 쓰므로 업로드 키를 잃어도 **앱은 계속 업데이트할 수 있다**(앱 서명 키는 Google이 보관).

1. §1 명령으로 새 업로드 키스토어를 만든다.
2. 새 키의 인증서를 PEM으로 내보낸다:
   ```bash
   keytool -export -rfc -keystore ~/closetimo-upload-new.jks -alias upload -file upload_certificate.pem
   ```
3. Play Console **앱 서명** 페이지의 "업로드 키 재설정 요청"에서 `upload_certificate.pem`을 제출한다
   (계정 소유자 권한 필요).
4. Google 승인 후(보통 수일) 새 키가 유효해진다. 그때 `android/key.properties`의 `storeFile`·비밀번호를 새 값으로 바꾼다.
   승인 전에는 이전 키로도, 새 키로도 업로드할 수 없는 기간이 생길 수 있다.

유출이 의심되면 같은 절차로 즉시 재설정을 요청한다.
