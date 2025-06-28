buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

// إعدادات لتحسين الأداء ومنع مشاكل القفل
gradle.startParameter.apply {
    maxWorkerCount = 1
    isParallelProjectExecutionEnabled = false
    isBuildCacheEnabled = true
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    // إعدادات لإخفاء تحذيرات Firebase المهجورة
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf(
            "-Xlint:-deprecation",
            "-Xlint:-unchecked",
            "-Xlint:-rawtypes",
            "-nowarn"
        ))
        options.isWarnings = false
        options.isDeprecation = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
