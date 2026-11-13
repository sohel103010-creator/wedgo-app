import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

/// Wallet dashboard. Balances are READ from the server ledger
/// (wallets + wallet_transactions) — the client never computes or
/// writes balances. Female earnings are only visible to the owner.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'wallet'))),
      body: uid == null
          ? Center(child: Text(tr(ref, 'empty')))
          : FutureBuilder<Map<String, dynamic>?>(
              future: Supa.client
                  .from('wallets')
                  .select()
                  .eq('user_id', uid)
                  .maybeSingle(),
              builder: (context, snap) {
                if (!snap.hasData && !snap.hasError) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final w = snap.data;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(tr(ref, 'available_balance'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                            Text(
                              '৳${w?['available_bdt'] ?? 0}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      fontWeight:
                                          FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                '${tr(ref, 'pending_balance')}: ৳${w?['pending_bdt'] ?? 0}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/withdraw'),
                            child: Text(tr(ref, 'withdraw')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('History',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium),
                    const SizedBox(height: 8),
                    FutureBuilder<List<dynamic>>(
                      future: Supa.client
                          .from('wallet_transactions')
                          .select()
                          .eq('user_id', uid)
                          .order('created_at',
                              ascending: false)
                          .limit(50),
                      builder: (context, tsnap) {
                        if (!tsnap.hasData) {
                          return const Center(
                              child:
                                  CircularProgressIndicator());
                        }
                        final txs = tsnap.data!;
                        if (txs.isEmpty) {
                          return Center(
                              child: Text(tr(ref, 'empty')));
                        }
                        return Column(
                          children: [
                            for (final t
                                in txs.cast<Map<String, dynamic>>())
                              ListTile(
                                dense: true,
                                title: Text(
                                    '${t['type']}'),
                                subtitle: Text(
                                    '${t['created_at']}'
                                        .toString()
                                        .substring(0, 16)),
                                trailing: Text(
                                  '${(t['amount_bdt'] as int) >= 0 ? '+' : ''}${t['amount_bdt']}',
                                  style: TextStyle(
                                    color: (t['amount_bdt']
                                                as int) >=
                                            0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
