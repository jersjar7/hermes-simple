// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add the Google services plugin
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after other plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jersondevs.hermes.hermes_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.jersondevs.hermes.hermes_app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Add any needed Firebase dependencies
dependencies {
    // Firebase dependencies - match these with your Flutter plugin versions
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-database-ktx")
}

flutter {
    source = "../.."
}