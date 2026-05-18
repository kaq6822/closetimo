import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// AGP 8+ 호환 패치: namespace 누락된 플러그인(isar_flutter_libs 3.x 등)에
// AndroidManifest의 package 속성을 namespace로 주입한다. 다른 subprojects
// 블록의 evaluationDependsOn 이전에 등록해야 afterEvaluate가 정상 트리거된다.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt is BaseExtension && androidExt.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val packageRegex = Regex("""package="([^"]+)"""")
                val pkg = packageRegex.find(manifestFile.readText())
                    ?.groupValues
                    ?.get(1)
                if (pkg != null) {
                    androidExt.namespace = pkg
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
