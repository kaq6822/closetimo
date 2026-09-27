import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 업로드 키 설정. android/key.properties는 저장소에 커밋하지 않는다(android/.gitignore).
// 작성 방법: docs/release/android-signing.md, 형식: android/key.properties.example
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasUploadKey = keystorePropertiesFile.exists()
if (hasUploadKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("android/key.properties is missing '$name'")

android {
    namespace = "com.closetimo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 스토어 게시 후에는 바꿀 수 없다(#25). iOS 번들 ID와 같은 값을 쓴다.
        applicationId = "com.closetimo.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // key.properties가 없으면 로컬 QA용 release APK만 debug 키로 서명한다.
            // 스토어 업로드용 AAB(bundleRelease)는 아래에서 빌드 자체를 막는다.
            signingConfig =
                if (hasUploadKey) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

// 업로드 키 없이 만든 release 산출물이 스토어로 나가지 않게 한다(#11).
gradle.taskGraph.whenReady {
    if (hasUploadKey) return@whenReady
    val releaseTasks = allTasks.filter { it.project == project && it.name.endsWith("Release") }
    if (releaseTasks.any { it.name.startsWith("bundle") }) {
        throw GradleException(
            "Release app bundle requires an upload key. " +
                "Create android/key.properties (see docs/release/android-signing.md)."
        )
    }
    if (releaseTasks.any { it.name.startsWith("assemble") }) {
        // flutter build는 Gradle을 -q로 실행해 warn 레벨이 숨겨지므로 quiet 레벨로 출력한다.
        logger.quiet(
            """
            |
            |======================================================================
            | WARNING: android/key.properties not found.
            | This release APK is signed with the DEBUG key and cannot be uploaded
            | to Google Play. Use it for local QA only.
            | See docs/release/android-signing.md to configure the upload key.
            |======================================================================
            |
            """.trimMargin()
        )
    }
}

flutter {
    source = "../.."
}
