// Central Supabase access with RUNTIME-resolved configuration.
//
// Startup flow:
//   1. AppConfigStore.load() — secure-storage override, else --dart-define.
//   2. If a config exists -> Supabase.initialize with it.
//   3. If none -> Supa.ready stays false and the app routes to /setup,
//      where the user pastes the values (no rebuild needed).
//
// Every Supabase call in the app goes through Supa.client, so the
// runtime-resolved values are always the ones in effect.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config_store.dart';

class Supa {
  static bool _ready = false;
  static BackendConfig? _config;

  /// Resolve config and initialize. Returns true when usable.
  static Future<bool> init() async {
    final cfg = await AppConfigStore.load();
    if (cfg == null) return false;
    await Supabase.initialize(url: cfg.url, publishableKey: cfg.anonKey);
    _config = cfg;
    _ready = true;
    return true;
  }

  /// Re-initialize after the user saves new values in the Setup screen.
  /// Returns false when re-init failed (caller should ask for app restart).
  static Future<bool> reinit() async {
    final cfg = await AppConfigStore.load();
    if (cfg == null) return false;
    try {
      await Supabase.initialize(url: cfg.url, publishableKey: cfg.anonKey);
    } catch (_) {
      return false;
    }
    _config = cfg;
    _ready = true;
    return true;
  }

  static bool get ready => _ready;
  static BackendConfig? get config => _config;

  static SupabaseClient get client {
    if (!_ready) {
      throw StateError(
          'Supabase is not configured. Open the in-app Setup screen and paste SUPABASE_URL / SUPABASE_ANON_KEY, or rebuild with --dart-define.');
    }
    return Supabase.instance.client;
  }
}
