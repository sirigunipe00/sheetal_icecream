
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

plugins {
    id("com.android.application")

    // Firebase configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")

    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "in.easycloud.sheetal_ice_creams"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    defaultConfig {
        applicationId = "in.easycloud.sheetal_ice_creams"

        minSdk = 24
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (System.getenv("CI") != null) {

                // Codemagic CI signing configuration
                storeFile = file(
                    System.getenv("CM_KEYSTORE_PATH")!!
                )

                storePassword =
                    System.getenv("CM_KEYSTORE_PASSWORD")

                keyAlias =
                    System.getenv("CM_KEY_ALIAS")

                keyPassword =
                    System.getenv("CM_KEY_PASSWORD")

            } else {

                // Local release signing configuration
                keyAlias =
                    keystoreProperties.getProperty("keyAlias")

                keyPassword =
                    keystoreProperties.getProperty("keyPassword")

                storeFile =
                    keystoreProperties.getProperty("storeFile")
                        ?.let { file(it) }

                storePassword =
                    keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }

        debug {
            signingConfig =
                signingConfigs.getByName("debug")
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
