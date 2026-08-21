import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "nl.viter.glider"
    // flutter_secure_storage 11 requires compiling against API 37. compileSdk
    // only governs which APIs are available at compile time; targetSdk below
    // stays at Flutter's default (36 / Android 16), which is what selects
    // runtime behaviour.
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "nl.viter.glider"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        debug {
            // Install alongside a release/store install instead of replacing it
            // (which would take the session and local data with it).
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }

        release {
            // Fall back to debug signing so `flutter build apk` works locally
            // without key.properties -- but never in CI, where a silently
            // debug-signed release artifact could be published. The Android
            // debug key is a well-known constant, so such a build would be
            // forgeable by anyone and could not upgrade a real install.
            val hasKeystore = rootProject.file("key.properties").exists()
            val isCi = System.getenv("CI").toBoolean()
            if (!hasKeystore && isCi) {
                throw GradleException(
                    "android/key.properties is missing. Refusing to produce a " +
                        "debug-signed release build in CI.",
                )
            }
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.material:material:1.14.0")
}
