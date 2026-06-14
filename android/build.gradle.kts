allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Force compileSdk 36 sur TOUS les sous-projets (plugins inclus)
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            androidExtension?.let {
                try {
                    val compileSdkMethod = it.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                    compileSdkMethod.invoke(it, 36)
                } catch (e: Exception) {
                    // ignore si le projet ne supporte pas
                }
            }
        }
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