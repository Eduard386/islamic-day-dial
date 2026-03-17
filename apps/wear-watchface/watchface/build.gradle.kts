plugins {
    id("com.android.application")
}

android {
    namespace = "com.islamicdaydial.watchface"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.islamicdaydial.watchface"
        minSdk = 34
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}
