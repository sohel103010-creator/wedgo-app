// Build-time configuration. Values come from --dart-define and are
// compiled in — NEVER hardcode secrets here or anywhere else.
//
// These are DEFAULTS only. At runtime, AppConfigStore.load() prefers
// user-pasted values from secure storage (first-launch Setup screen),
// so a prebuilt APK works without recompiling.
class AppConfig {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const fcmEnabled =
      bool.fromEnvironment('FCM_ENABLED', defaultValue: false);
  static const googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  /// True when --dart-define build defaults are present.
  /// (Independent of any secure-storage override — see AppConfigStore.)
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String appName = 'WedGo';
  static const String packageName = 'com.wedgo.matrimony';
}
