// FLAG_SECURE helper for sensitive screens (calls, verification docs).
// Implemented via a MethodChannel in MainActivity (see android/…).
// Alternative: the flutter_windowmanager_plus plugin — same effect.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';

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

/// Keeps FLAG_SECURE in sync with the signed-in user's admin state.
///
/// Rule: the flag is ON unless an admin session is active. Fail-secure —
/// while the admin check is still loading, or the user is logged out, the
/// flag stays ON. Wraps MaterialApp's builder so it re-applies whenever the
/// app rebuilds; provider listeners cover login, logout and the admin-role
/// resolving after sign-in. This widget owns the flag — individual screens
/// must NOT toggle it themselves (see verification.dart).
class SecureFlagSync extends ConsumerStatefulWidget {
  const SecureFlagSync({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SecureFlagSync> createState() => _SecureFlagSyncState();
}

class _SecureFlagSyncState extends ConsumerState<SecureFlagSync> {
  bool? _applied;

  Future<void> _apply() async {
    final role = ref.read(adminRoleProvider).valueOrNull;
    final session = ref.read(authStateProvider).valueOrNull?.session;
    final secure = !(role != null && session != null);
    if (_applied == secure) return;
    _applied = secure;
    await SecureScreen.set(secure);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(covariant SecureFlagSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminRoleProvider, (_, __) => _apply());
    ref.listen(authStateProvider, (_, __) => _apply());
    return widget.child;
  }
}
