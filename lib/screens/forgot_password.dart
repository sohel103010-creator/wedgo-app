import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _isError = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _msg = null;
      _isError = false;
    });
    try {
      await Supa.client.auth.resetPasswordForEmail(_email.text.trim());
      setState(() => _msg = '✓ ${_email.text.trim()}');
    } on AuthException catch (e) {
      setState(() {
        _msg = e.message;
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'forgot_password'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration:
                InputDecoration(labelText: tr(ref, 'email')),
          ),
          const SizedBox(height: 16),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_msg!,
                  style: TextStyle(
                      color: _isError ? Colors.red : Colors.green)),
            ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr(ref, 'send')),
            ),
          ),
        ],
      ),
    );
  }
}
