import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/app_restart.dart';
import 'services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supa.init(); // runtime config: secure storage, else --dart-define
  runApp(const WedGoRoot());
}

/// Root that owns the Riverpod container so the whole app (including all
/// providers) can be rebuilt after the backend config changes in /setup.
class WedGoRoot extends StatefulWidget {
  const WedGoRoot({super.key});

  @override
  State<WedGoRoot> createState() => WedGoRootState();
}

class WedGoRootState extends State<WedGoRoot> {
  ProviderContainer _container = ProviderContainer();

  @override
  void initState() {
    super.initState();
    AppRestart.requestRestart = applyNewBackendConfig;
  }

  /// Called after saving new backend values: re-inits Supabase and
  /// rebuilds every provider against the new backend.
  Future<bool> applyNewBackendConfig() async {
    final ok = await Supa.reinit();
    if (!ok) return false;
    setState(() {
      _container.dispose();
      _container = ProviderContainer();
    });
    return true;
  }

  static WedGoRootState? of(BuildContext context) =>
      context.findAncestorStateOfType<WedGoRootState>();

  @override
  void dispose() {
    if (identical(AppRestart.requestRestart, applyNewBackendConfig)) {
      AppRestart.requestRestart = null;
    }
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _container,
      child: const WedGoApp(),
    );
  }
}
