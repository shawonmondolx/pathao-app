allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect ALL build outputs to a path without spaces.
// This is required because the Windows username "mayerdoya service" contains
// a space, which causes Gradle to split the path and fail ancestor directory checks.
val safeBuildRoot = file("C:/tmp/flutter_build")
rootProject.layout.buildDirectory.set(safeBuildRoot.resolve("root"))

subprojects {
    val safeSubDir = safeBuildRoot.resolve(project.name)
    project.layout.buildDirectory.set(safeSubDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
