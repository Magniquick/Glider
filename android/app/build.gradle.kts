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

    val hasKeystore = rootProject.file("key.properties").exists()

    buildTypes {
        debug {
            // Install alongside a release/store install instead of replacing it
            // (which would take the session and local data with it).
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }

        release {
            // Fall back to debug signing so `flutter build apk` works locally
            // without key.properties. Producing one in CI is refused, but that
            // check lives below: this block is evaluated on every Gradle
            // invocation, so throwing here would also fail a profile build,
            // which never touches the release signing config.
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

// Refuse to hand out a release artifact signed with the Android debug key: it
// is a well-known constant, so the build would be forgeable by anyone and
// could not upgrade a real install. Scoped to the tasks that actually package
// a release, so profile and debug builds are unaffected.
if (!rootProject.file("key.properties").exists() &&
    System.getenv("CI").toBoolean()
) {
    tasks.matching { it.name == "assembleRelease" || it.name == "bundleRelease" }
        .configureEach {
            doFirst {
                throw GradleException(
                    "android/key.properties is missing. Refusing to produce a " +
                        "debug-signed release build in CI.",
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
