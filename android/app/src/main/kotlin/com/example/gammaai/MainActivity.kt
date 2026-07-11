package com.example.gammaai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // This ensures all your plugins (Voice, Auth, etc.) are registered correctly on Android
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}