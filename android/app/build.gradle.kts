import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// EN: Release signing is read from android/key.properties (gitignored; see
//     RELEASING.md). Without it, release builds fall back to the debug key so that CI
//     and contributors can build; the stores refuse such a build.
// FR: La signature de release est lue de android/key.properties (ignoré par git ; voir
//     RELEASING.md). Sans lui, la release retombe sur la clé de débogage pour que la CI
//     et les contributeurs puissent construire ; les boutiques refusent un tel build.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "ca.veidimadur.snowbird_in_usa_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // EN: flutter_local_notifications uses java.time APIs that require core
        //     library desugaring on older Android versions.
        // FR: flutter_local_notifications utilise des API java.time qui exigent
        //     le « desugaring » de la bibliothèque de base sur les anciennes
        //     versions d'Android.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "ca.veidimadur.snowbird_in_usa_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // EN: Companion library for core library desugaring (see compileOptions).
    // FR: Bibliothèque compagne du « desugaring » (voir compileOptions).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
