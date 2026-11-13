/// Global hook so the Setup screen can ask the root widget to rebuild
/// every Riverpod provider after the backend config changes —
/// without importing main.dart (which would create an import cycle
/// via app.dart -> screens/setup.dart).
class AppRestart {
  static Future<bool> Function()? requestRestart;
}
