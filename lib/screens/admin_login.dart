import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

/// Admin entry: Google Sign-In, then a SERVER-SIDE role check
/// (rpc is_admin + admin_roles row). No email is hardcoded anywhere —
/// the backend decides who is an admin.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  bool _busy = false;
  String? _error;
  String? _role;

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
      _role = null;
    });
    try {
      if (AppConfig.googleWebClientId.isEmpty) {
        throw Exception(tr(ref, 'requires_setup'));
      }
      final googleUser = await GoogleSignIn(
        serverClientId: AppConfig.googleWebClientId,
      ).signIn();
      if (googleUser == null) {
        setState(() => _busy = false);
        return; // user cancelled
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('google_no_id_token');

      final res = await Supa.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final uid = res.user?.id;
      if (uid == null) throw Exception('auth_failed');

      // Server-side authorization — the ONLY thing that grants admin.
      final api = ref.read(apiProvider);
      final isAdmin = await api.checkIsAdmin(uid);
      if (!isAdmin) {
        await Supa.client.auth.signOut();
        throw Exception('not_an_admin');
      }
      final role = await api.fetchAdminRole(uid);
      if (!mounted) return;
      setState(() => _role = role ?? 'ADMIN');
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'admin_login'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 64, color: Color(0xFF8B1E2D)),
              const SizedBox(height: 16),
              if (_role != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('✓ $_role',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge),
                        const SizedBox(height: 8),
                        const Text(
                            'Full admin console: use the web admin panel.'),
                      ],
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _busy ? null : _googleSignIn,
                  icon: const Icon(Icons.login),
                  label: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_busy
                        ? tr(ref, 'loading')
                        : 'Google ${tr(ref, 'admin_login')}'),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
