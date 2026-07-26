import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Maps: set GOOGLE_MAPS_API_KEY in android/local.properties
val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}
val mapsApiKey: String = localProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""

android {
    namespace = "com.example.strolling"
    compileSdk = flutter.compileSdkVersion
    // No native plugins remain (google_maps/jni removed) → no NDK needed.
    // ndkVersion = flutter.ndkVersion

    // ── No-NDK workaround ─────────────────────────────────────────────────
    // Modern Flutter's Gradle plugin calls `forceNdkDownload()` UNCONDITIONALLY
    // (flutter_tools .../gradle/.../FlutterPluginUtils.kt, FlutterPlugin.kt:229).
    // That function points this module at an empty CMakeLists.txt for the SOLE
    // purpose of making AGP believe there is a C/C++ build and thus download the
    // NDK (~1GB — AGP's default 27.0.12077973). This app has NO native code, so
    // we undo it here: the Flutter plugin sets the CMake path at apply-time; this
    // `android {}` block runs right after, before AGP creates its CXX tasks, so
    // clearing the path removes the CXX build → the NDK is never required.
    externalNativeBuild {
        cmake {
            path = null
        }
    }
    // Belt-and-suspenders: also skip stripping the engine's own .so files, which
    // would otherwise be a second (task-time) reason AGP reaches for the NDK.
    // (Without the NDK these libraries ship unstripped, so the debug APK is large —
    // that is the accepted trade for not downloading the ~1GB NDK.)
    packaging {
        jniLibs {
            keepDebugSymbols.add("**/*.so")
            // The Vulkan validation layer is a ~240MB debug-only diagnostic that the
            // app never loads unless Vulkan validation is explicitly enabled. Dropping
            // it roughly halves the (unstripped) debug APK with no effect on running.
            excludes.add("**/libVkLayer_khronos_validation.so")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.strolling"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
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
