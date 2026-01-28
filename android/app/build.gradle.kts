plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must be applied last
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
        import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")

android {
    namespace = "ls.bloomee.musicplayer"
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
        applicationId = "ls.bloomee.musicplayer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Build ONLY arm64 (fixes Gradle/Rust deadlock on Windows)
        ndk {
            abiFilters += setOf("arm64-v8a")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            println("   ✅ key.properties found - configuring release signing")

            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))

            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = rootProject.file("bloomee.jks")
                storePassword = keystoreProperties["storePassword"] as String?
            }
        } else {
            println("   ❌ key.properties not found - using debug signing")
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
                println("   📦 Release build: Using release signing config")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                println("   📦 Release build: Using debug signing config (no keystore)")
            }
        }
    }

    // Required for Flutter + native plugins
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
}

flutter {
    source = "../.."
}
