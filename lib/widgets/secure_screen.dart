// FLAG_SECURE helper for sensitive screens (calls, verification docs).
// Implemented via a MethodChannel in MainActivity (see android/…).
// Alternative: the flutter_windowmanager_plus plugin — same effect.
import 'package:flutter/services.dart';

class SecureScreen {
  static const _ch = MethodChannel('wedgo/secure');

  /// Enables FLAG_SECURE (blocks screenshots / screen recording /
  /// recent-app previews) while [secure] is true.
  static Future<void> set(bool secure) async {
    try {
      await _ch.invokeMethod('setSecure', {'secure': secure});
    } on MissingPluginException {
      // Non-Android or MainActivity hook missing: documented in README.
    }
  }
}
