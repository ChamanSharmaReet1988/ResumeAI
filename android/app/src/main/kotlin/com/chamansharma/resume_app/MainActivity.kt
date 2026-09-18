package com.quickresume

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT < 26) {
            return
        }
        try {
            val pluginClass = Class.forName("com.quickresume.AndroidGenAiPlugin")
            val register = pluginClass.getDeclaredMethod(
                "register",
                FlutterEngine::class.java,
            )
            register.invoke(null, flutterEngine)
        } catch (_: Throwable) {
            // Gemini Nano is optional; older devices keep using cloud/on-device fallbacks.
        }
    }
}
