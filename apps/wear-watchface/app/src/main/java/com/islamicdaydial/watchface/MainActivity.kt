package com.islamicdaydial.watchface

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button

/**
 * Launcher activity. WFF watch face is selected from the system picker.
 */
class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<Button>(R.id.btn_open_picker).setOnClickListener {
            openWatchFacePicker()
        }
    }

    private fun openWatchFacePicker() {
        try {
            startActivity(Intent("com.google.android.wearable.action.CHANGE_WATCH_FACE"))
        } catch (_: Exception) {
            try {
                startActivity(Intent(android.app.WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
            } catch (_: Exception) {}
        }
    }
}
