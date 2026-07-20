plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Redirect build output to a path without spaces to fix Gradle path-space bug
// on machines where the username contains a space ("mayerdoya service")
layout.buildDirectory.set(file("C:/tmp/flutter_build/app"))

android {
    namespace = "com.example.pathao_agent"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        // Disable Kotlin incremental compilation to avoid the
        // "Storage for [*.tab] is already registered" file-lock bug seen on
        // this machine with the bundled Kotlin compiler.
        freeCompilerArgs = freeCompilerArgs + "-Xjsr305=strict"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pathao_agent_new"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Updated to prevent crashes with secure_storage and geolocator on real devices
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

afterEvaluate {
    tasks.all {
        if (name.startsWith("assembleDebug") || name.startsWith("assembleRelease") || name.startsWith("assembleProfile")) {
            doLast {
                val destDir = file("../../build/app/outputs/flutter-apk")
                destDir.mkdirs()
                copy {
                    from(layout.buildDirectory.dir("outputs/flutter-apk"))
                    into(destDir)
                    include("*.apk")
                }
                println("Copied APKs to ${destDir.absolutePath}")
            }
        }
    }
}
