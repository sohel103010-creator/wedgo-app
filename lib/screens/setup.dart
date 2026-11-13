import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../providers/auth.dart';
import '../services/app_config_store.dart';
import '../services/app_restart.dart';
import '../services/supabase_client.dart';

/// First-launch backend setup. The user pastes SUPABASE_URL and
/// SUPABASE_ANON_KEY once; values are stored in secure storage and take
/// effect immediately — no rebuild needed.
///
/// Priority: saved override > --dart-define build defaults > this screen.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _url = TextEditingController();
  final _key = TextEditingController();
  bool _busy = false;
  bool _testing = false;
  String? _error;
  String? _testResult;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final cfg = await AppConfigStore.load();
    if (!mounted) return;
    setState(() {
      if (cfg != null) {
        _url.text = cfg.url;
        _key.text = cfg.anonKey;
      }
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  String _t(String k) => tr(ref, k);

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
      _error = null;
    });
    final err = await AppConfigStore.testConnection(
        _url.text, _key.text);
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = err == null ? 'OK' : err;
      });
    }
  }

  Future<void> _save() async {
    if (_url.text.trim().isEmpty || _key.text.trim().isEmpty) {
      setState(() => _error = _t('setup_missing'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppConfigStore.save(_url.text, _key.text);
      final restart = AppRestart.requestRestart;
      final ok = restart == null
          ? await Supa.reinit()
          : await restart();
      if (!mounted) return;
      if (ok) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (_) => false);
      } else {
        setState(() => _error =
            'Saved, but the backend could not be reloaded. Please restart the app.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearOverride() async {
    await AppConfigStore.clearOverride();
    if (!mounted) return;
    final restart = AppRestart.requestRestart;
    final ok = restart == null
        ? await Supa.reinit()
        : await restart();
    if (mounted && ok) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBuildDefaults = AppConfig.isConfigured;
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Setup')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.dns,
                    size: 56, color: Color(0xFF8B1E2D)),
                const SizedBox(height: 12),
                const Text(
                  'Connect WedGo to your Supabase backend.\n'
                  'Paste the values once — they are stored securely on this '
                  'device and take effect immediately. No rebuild needed.\n\n'
                  'Find them in: Supabase Dashboard → Project Settings → API.',
                ),
                const SizedBox(height: 8),
                if (hasBuildDefaults)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          'ℹ️ This build already contains default backend values. '
                          'Saving here overrides them on this device only.'),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'SUPABASE_URL',
                    hintText: 'https://xyzcompany.supabase.co',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _key,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'SUPABASE_ANON_KEY',
                    hintText: 'eyJ...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _testing ? null : _test,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(_testing
                        ? _t('loading')
                        : 'Test Connection'),
                  ),
                ),
                if (_testResult != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 8),
                    child: Text(
                      _testResult == 'OK'
                          ? '✓ Reachable'
                          : '✗ $_testResult',
                      style: TextStyle(
                          color: _testResult == 'OK'
                              ? Colors.green
                              : Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.red)),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_busy
                        ? _t('loading')
                        : 'Save & Continue'),
                  ),
                ),
                const SizedBox(height: 8),
                if (Supa.config?.isUserOverride == true)
                  TextButton(
                    onPressed: _clearOverride,
                    child: const Text(
                        'Clear override (use build defaults)'),
                  ),
              ],
            ),
    );
  }
}
