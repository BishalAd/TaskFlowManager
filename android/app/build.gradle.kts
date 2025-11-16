plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.proj"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.proj"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // ✅ Correct AGP 8 syntax for desugaring
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ✅ Correct Kotlin DSL for jvm settings
    kotlin {
        jvmToolchain(17)
    }

    buildTypes {
       getByName("release") {
           signingConfig = signingConfigs.getByName("debug")
       }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ UPDATED required version for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Recommended for safety
    implementation("androidx.multidex:multidex:2.0.1")
}
