// Runtime backend configuration store.
//
// Resolution order (no rebuild needed):
//   1. User-pasted values in flutter_secure_storage (Setup screen) — override.
//   2. --dart-define SUPABASE_URL / SUPABASE_ANON_KEY — build-time defaults.
//   3. Nothing -> first-launch Setup screen.
//
// This is what lets a prebuilt APK work without the user compiling anything.
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class BackendConfig {
  final String url;
  final String anonKey;

  /// True when the user pasted these in the Setup screen (secure storage);
  /// false when they came from --dart-define build defaults.
  final bool isUserOverride;

  const BackendConfig({
    required this.url,
    required this.anonKey,
    required this.isUserOverride,
  });
}

class AppConfigStore {
  static const _kUrl = 'wedgo_supabase_url';
  static const _kKey = 'wedgo_supabase_anon_key';
  static const _storage = FlutterSecureStorage();

  /// Returns the effective config, or null when nothing is configured.
  static Future<BackendConfig?> load() async {
    String? url;
    String? key;
    try {
      url = await _storage.read(key: _kUrl);
      key = await _storage.read(key: _kKey);
    } catch (_) {
      // Secure storage unavailable (e.g. some emulators) — fall through
      // to build defaults instead of crashing.
    }
    if (url != null &&
        url.trim().isNotEmpty &&
        key != null &&
        key.trim().isNotEmpty) {
      return BackendConfig(
          url: url.trim(),
          anonKey: key.trim(),
          isUserOverride: true);
    }
    if (AppConfig.supabaseUrl.isNotEmpty &&
        AppConfig.supabaseAnonKey.isNotEmpty) {
      return BackendConfig(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
          isUserOverride: false);
    }
    return null;
  }

  static Future<void> save(String url, String anonKey) async {
    await _storage.write(key: _kUrl, value: url.trim());
    await _storage.write(key: _kKey, value: anonKey.trim());
  }

  static Future<void> clearOverride() async {
    try {
      await _storage.delete(key: _kUrl);
      await _storage.delete(key: _kKey);
    } catch (_) {}
  }

  /// Lightweight reachability check: GET {url}/auth/v1/health.
  /// Returns null on success, or an error description.
  static Future<String?> testConnection(
      String url, String anonKey) async {
    final u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      return 'URL must start with https://';
    }
    if (anonKey.trim().isEmpty) return 'Anon key is empty';
    final client = HttpClient();
    try {
      final req = await client
          .getUrl(Uri.parse('$u/auth/v1/health'))
          .timeout(const Duration(seconds: 10));
      req.headers.set('apikey', anonKey.trim());
      final res =
          await req.close().timeout(const Duration(seconds: 10));
      await res.drain();
      if (res.statusCode == 200 || res.statusCode == 404) {
        // 200 = healthy GoTrue; 404 = reachable host, unexpected path —
        // still proves the URL resolves.
        return null;
      }
      return 'Server replied HTTP ${res.statusCode}';
    } catch (e) {
      return 'Unreachable: $e';
    } finally {
      client.close(force: true);
    }
  }
}
