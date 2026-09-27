import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = mutableMapOf<String, String>()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.forEachLine { rawLine ->
        val line = rawLine.trim()
        if (line.isEmpty() || line.startsWith("#")) {
            return@forEachLine
        }

        val separator = line.indexOf('=')
        if (separator <= 0) {
            return@forEachLine
        }

        val key = line.substring(0, separator).trim()
        val value = line.substring(separator + 1).trim()
        if (value.isNotEmpty() && !keystoreProperties.containsKey(key)) {
            keystoreProperties[key] = value
        }
    }
}

android {
    namespace = "com.stefanronnkvist.paid.emailkick"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.stefanronnkvist.paid.emailkick"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"]
            if (storeFilePath.isNullOrBlank()) {
                throw GradleException(
                    "Missing Android release signing config. Create android/key.properties from android/key.properties.example.",
                )
            }

            val keystoreFile = File(storeFilePath)
            storeFile = if (keystoreFile.isAbsolute) keystoreFile else rootProject.file(storeFilePath)
            storePassword = keystoreProperties["storePassword"]
            keyAlias = keystoreProperties["keyAlias"]
            keyPassword = keystoreProperties["keyPassword"]
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
