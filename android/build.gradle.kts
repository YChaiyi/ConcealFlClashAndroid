allprojects {
    repositories {
        maven {
            url = uri("https://storage.flutter-io.cn/download.flutter.io")
            content {
                includeGroup("io.flutter")
            }
        }
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
            content {
                includeGroup("io.flutter")
            }
        }
        maven {
            url = uri("https://jitpack.io")
            content {
                includeGroup("com.github.fast-development.android-js-runtimes")
            }
        }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
