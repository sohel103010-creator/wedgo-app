import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';
import '../utils/age_gate.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _gender = 'male';
  DateTime? _dob;
  bool _adultConfirm = false;
  bool _terms = false;
  bool _privacy = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _t(String k) => tr(ref, k);

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final dobErr = AgeGate.validateDob(_dob);
    if (dobErr != null) {
      setState(() => _error = _t(dobErr));
      return;
    }
    if (!_adultConfirm || !_terms || !_privacy) {
      setState(() => _error = _t('must_be_18'));
      return;
    }
    setState(() => _busy = true);
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await Supa.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {
          'full_name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'gender': _gender,
          'date_of_birth': _dob!.toIso8601String().split('T').first,
        },
      );
      final user = res.user;
      if (user == null) throw Exception('signup_failed');
      // Create the public.users row.
      // BACKEND REQUIREMENT: this needs either a `handle_new_user` trigger
      // on auth.users or an INSERT policy on public.users (currently neither
      // exists in the migrations). Until then the RLS error below surfaces
      // honestly instead of faking success.
      try {
        await Supa.client.from('users').insert({
          'id': user.id,
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'full_name': _name.text.trim(),
          'gender': _gender,
          'date_of_birth':
              _dob!.toIso8601String().split('T').first,
          'adult_confirmed': true,
          'terms_accepted_at': now,
          'privacy_accepted_at': now,
        });
      } on PostgrestException catch (e) {
        // Clean up the orphaned auth user is a backend job; here we report.
        throw Exception(
            'requires_setup: public.users insert blocked (${e.code}). Deploy the handle_new_user trigger or users INSERT policy — see README §6.');
      }
      // Minimal profile row so completion % has a base to grow from.
      await Supa.client.from('profiles').insert({
        'user_id': user.id,
        'profile_code':
            'WG-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        'age': AgeGate.calcAge(_dob!),
      });
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('register'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: _t('full_name')),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? _t('full_name') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: _t('mobile')),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? _t('mobile') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: _t('email')),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? _t('email') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: _t('password')),
              validator: (v) =>
                  (v == null || v.length < 6) ? _t('password') : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(labelText: _t('gender')),
              items: [
                DropdownMenuItem(
                    value: 'male', child: Text(_t('male'))),
                DropdownMenuItem(
                    value: 'female', child: Text(_t('female'))),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'male'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('dob')),
              subtitle: Text(_dob == null
                  ? '—'
                  : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().subtract(const Duration(days: 365 * 20)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dob = picked);
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _adultConfirm,
              onChanged: (v) =>
                  setState(() => _adultConfirm = v ?? false),
              title: Text(_t('age_confirm')),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _terms,
              onChanged: (v) => setState(() => _terms = v ?? false),
              title: Text(_t('terms_accept')),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _privacy,
              onChanged: (v) => setState(() => _privacy = v ?? false),
              title: Text(_t('privacy_accept')),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : Text(_t('register')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
