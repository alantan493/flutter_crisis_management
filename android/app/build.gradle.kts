plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.crisis_managment"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.crisis_managment"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = project.findProperty("GOOGLE_MAPS_API_KEY") ?: ""
        // Enable multidex support for Firebase
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // Add packaging options to avoid conflicts
    packaging {
        resources {
            pickFirsts += listOf("**/libc++_shared.so", "**/libjsc.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))
    
    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth") // Required for authentication
    
    // Multidex support for handling large number of methods
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Optional: Add these if you plan to use Google Sign-In later
    // implementation("com.google.android.gms:play-services-auth:20.7.0")
    
    // Optional: Add these if you plan to use Firestore later
    // implementation("com.google.firebase:firebase-firestore")
}