import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';
import '../services/api.dart';

/// Female withdrawal. PIN is verified server-side via the
/// 'request-withdrawal' Edge Function; the client never sees pin_hash.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() =>
      _WithdrawScreenState();
}

class _WithdrawScreenState
    extends ConsumerState<WithdrawScreen> {
  String? _accountId;
  final _amount = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _done = false;

  // Account add fields
  String _newMethod = 'bkash';
  final _newNumber = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _pin.dispose();
    _newNumber.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _accounts(String uid) async {
    final rows = await Supa.client
        .from('withdrawal_accounts')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> _addAccount(String uid) async {
    final num = _newNumber.text.trim();
    if (num.isEmpty) return;
    await Supa.client.from('withdrawal_accounts').insert({
      'user_id': uid,
      'method': _newMethod,
      'account_number': num,
      'is_default': false,
    });
    _newNumber.clear();
    setState(() {});
  }

  Future<void> _submit() async {
    if (_accountId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).requestWithdrawal(
            accountId: _accountId!,
            amountBdt: int.parse(_amount.text.trim()),
            pin: _pin.text,
          );
      if (mounted) setState(() => _done = true);
    } on FunctionMissingException catch (e) {
      if (mounted) {
        setState(() =>
            _error = '${tr(ref, 'requires_setup')} ($e)');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) {
      return Scaffold(
          body: Center(child: Text(tr(ref, 'empty'))));
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'withdraw'))),
      body: _done
          ? Center(
              child: Text(tr(ref, 'pending'),
                  style:
                      Theme.of(context).textTheme.titleLarge))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _accounts(uid),
              builder: (context, snap) {
                final accounts = snap.data ?? [];
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DropdownButtonFormField<String>(
                      value: _accountId,
                      decoration: const InputDecoration(
                          labelText: 'Account'),
                      items: [
                        for (final a in accounts)
                          DropdownMenuItem(
                            value: a['id'] as String,
                            child: Text(
                                '${a['method']} — ${_mask(a['account_number'] as String)}'),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _accountId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<
                              String>(
                            value: _newMethod,
                            items: const [
                              DropdownMenuItem(
                                  value: 'bkash',
                                  child: Text('bKash')),
                              DropdownMenuItem(
                                  value: 'nagad',
                                  child: Text('Nagad')),
                              DropdownMenuItem(
                                  value: 'rocket',
                                  child: Text('Rocket')),
                            ],
                            onChanged: (v) => setState(
                                () => _newMethod = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _newNumber,
                            keyboardType: TextInputType.phone,
                            decoration:
                                const InputDecoration(
                                    labelText: 'Number'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              _addAccount(uid),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: tr(ref, 'amount')),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              tr(ref, 'withdraw_pin')),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.red)),
                    FilledButton(
                      onPressed:
                          (_busy || _accountId == null)
                              ? null
                              : _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_busy
                            ? tr(ref, 'loading')
                            : tr(ref, 'withdraw')),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _mask(String n) =>
      n.length <= 4 ? '••••' : '••••${n.substring(n.length - 4)}';
}
