package com.wedgo.matrimony

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * FLAG_SECURE hook for sensitive screens (calls, verification docs).
 * Dart calls SecureScreen.set(true/false) via the "wedgo/secure" channel.
 * This blocks screenshots, screen recording and recent-app previews.
 * Alternative: the flutter_windowmanager_plus plugin (same effect).
 */
class MainActivity : FlutterActivity() {
    private val channel = "wedgo/secure"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, channel
        ).setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                val secure = call.argument<Boolean>("secure") ?: false
                runOnUiThread {
                    if (secure) {
                        window.addFlags(
                            WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(
                            WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
