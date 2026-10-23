
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after Android and Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.unaniacademy.unani_academy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.unaniacademy.unani_academy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load release signing properties if configured.
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()

    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use {
            keystoreProperties.load(it)
        }
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties.getProperty("keyAlias")
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword")
            val storeFileProp = keystoreProperties.getProperty("storeFile")
            val storePasswordProp = keystoreProperties.getProperty("storePassword")

            if (
                !keyAliasProp.isNullOrBlank() &&
                !keyPasswordProp.isNullOrBlank() &&
                !storeFileProp.isNullOrBlank() &&
                !storePasswordProp.isNullOrBlank()
            ) {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = file(storeFileProp)
                storePassword = storePasswordProp
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")

            signingConfig =
                if (
                    releaseSigning.storeFile != null &&
                    releaseSigning.storeFile!!.exists() &&
                    !releaseSigning.keyAlias.isNullOrBlank()
                ) {
                    releaseSigning
                } else {
                    // Temporary fallback for local build testing only.
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
