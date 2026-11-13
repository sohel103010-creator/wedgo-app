import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

/// Manual MFS payment submission (Mode B). Payment numbers come from
/// `payment_settings` (admin-editable). The row is created as `pending`;
/// activation happens ONLY after admin approval (approve-payment).
class PaymentSubmitScreen extends ConsumerStatefulWidget {
  final String? packageId;
  const PaymentSubmitScreen({super.key, this.packageId});

  @override
  ConsumerState<PaymentSubmitScreen> createState() =>
      _PaymentSubmitScreenState();
}

class _PaymentSubmitScreenState
    extends ConsumerState<PaymentSubmitScreen> {
  String _method = 'bkash';
  final _sender = TextEditingController();
  final _trx = TextEditingController();
  XFile? _shot;
  bool _busy = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _sender.dispose();
    _trx.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final uid = ref.read(currentUserIdProvider)!;
      String? proofPath;
      if (_shot != null) {
        proofPath =
            'payments/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supa.client.storage
            .from('payment-proofs')
            .upload(proofPath, File(_shot!.path));
      }
      // Amount is taken from the package row server-side on approval;
      // we store the package id only. Never trust a client-sent price.
      await Supa.client.from('payments').insert({
        'user_id': uid,
        'kind': 'subscription',
        'package_id': widget.packageId,
        'amount_bdt': 0, // resolved server-side from package_id
        'method': _method,
        'sender_number': _sender.text.trim(),
        'transaction_id': _trx.text.trim(),
        'proof_storage_path': proofPath,
        'status': 'pending',
      });
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'submit_payment'))),
      body: _done
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 64, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(tr(ref, 'pending'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge),
                  ],
                ),
              ),
            )
          : FutureBuilder<Map<String, dynamic>?>(
              future: Supa.client
                  .from('payment_settings')
                  .select()
                  .eq('id', 1)
                  .maybeSingle(),
              builder: (context, snap) {
                final ps = snap.data;
                final numbers = {
                  'bkash': ps?['bkash_number'],
                  'nagad': ps?['nagad_number'],
                  'rocket': ps?['rocket_number'],
                };
                final enabled = {
                  'bkash': ps?['bkash_enabled'] ?? true,
                  'nagad': ps?['nagad_enabled'] ?? true,
                  'rocket': ps?['rocket_enabled'] ?? true,
                };
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DropdownButtonFormField<String>(
                      value: _method,
                      decoration: InputDecoration(
                          labelText:
                              tr(ref, 'payment_method')),
                      items: [
                        for (final m in ['bkash', 'nagad', 'rocket'])
                          if (enabled[m] == true)
                            DropdownMenuItem(
                                value: m,
                                child: Text(
                                    '${m.toUpperCase()}${numbers[m] != null ? ' — ${numbers[m]}' : ''}')),
                      ],
                      onChanged: (v) =>
                          setState(() => _method = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _sender,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText:
                              tr(ref, 'sender_number')),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _trx,
                      decoration: InputDecoration(
                          labelText: tr(ref, 'trx_id')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(
                          '${tr(ref, 'screenshot')}${_shot != null ? ' ✓' : ''}'),
                      onPressed: () async {
                        final f = await ImagePicker()
                            .pickImage(
                                source: ImageSource.gallery);
                        if (f != null) {
                          setState(() => _shot = f);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.red)),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_busy
                            ? tr(ref, 'loading')
                            : tr(ref, 'submit_payment')),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
