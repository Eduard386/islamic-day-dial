plugins {
    id("com.android.application") version "8.7.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

// Установить оба APK: watchface (resource-only, индексируется системой) и app (код, complications)
tasks.register("installAll") {
    dependsOn(":watchface:installDebug", ":app:installDebug")
    group = "wear"
    description = "Установить watchface + app (оба нужны для WFF)"
}

// На эмуляторе WFF может не появляться в picker — используйте эту команду для активации
tasks.register<Exec>("setWatchFace") {
    commandLine(
        "adb", "shell", "am", "broadcast",
        "-a", "com.google.android.wearable.app.DEBUG_SURFACE",
        "--es", "operation", "set-watchface",
        "--es", "watchFaceId", "com.islamicdaydial.watchface"
    )
    group = "wear"
    description = "Активировать Islamic Day на эмуляторе (если не виден в picker)"
}
