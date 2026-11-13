import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';
import '../providers/subscription.dart';
import '../services/supabase_client.dart';
import 'find_partner.dart';
import 'chat_list.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const FindPartnerScreen(),
      const ChatListScreen(),
      const _CallsTab(),
      const _MoreTab(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home),
              label: tr(ref, 'home')),
          NavigationDestination(
              icon: const Icon(Icons.search),
              label: tr(ref, 'find_partner')),
          NavigationDestination(
              icon: const Icon(Icons.message),
              label: tr(ref, 'messages')),
          NavigationDestination(
              icon: const Icon(Icons.call),
              label: tr(ref, 'calls')),
          NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              label: tr(ref, 'more')),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('WedGo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profile.when(
            data: (p) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: p?.photoUrl != null
                              ? NetworkImage(p!.photoUrl!)
                              : null,
                          child: p?.photoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(p?.fullName ?? '—',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              if (p?.isVerified == true)
                                const Row(
                                  children: [
                                    Icon(Icons.verified,
                                        size: 16,
                                        color: Colors.blueAccent),
                                    SizedBox(width: 4),
                                    Text('Verified Profile'),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                        '${tr(ref, 'complete_profile')}: ${p?.completionPct ?? 0}%'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                        value: (p?.completionPct ?? 0) / 100),
                  ],
                ),
              ),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          sub.when(
            data: (s) => Card(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text(s == null
                    ? tr(ref, 'premium_required')
                    : '${tr(ref, 'active_package')}: ${s.package?.nameBn ?? s.packageId}'),
                subtitle: s == null
                    ? null
                    : Text(
                        '${tr(ref, 'remaining_days')}: ${s.remainingDays}'),
                trailing: s == null
                    ? FilledButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/subscribe'),
                        child: Text(tr(ref, 'buy')),
                      )
                    : null,
              ),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CallsTab extends ConsumerWidget {
  const _CallsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'calls'))),
      body: uid == null
          ? Center(child: Text(tr(ref, 'empty')))
          : FutureBuilder<List<dynamic>>(
              future: Supa.client
                  .from('calls')
                  .select()
                  .or('caller_id.eq.$uid,receiver_id.eq.$uid')
                  .order('started_at', ascending: false)
                  .limit(50),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final rows = snap.data!;
                if (rows.isEmpty) {
                  return Center(child: Text(tr(ref, 'empty')));
                }
                return ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final c = rows[i] as Map<String, dynamic>;
                    final out =
                        (c['caller_id'] as String) == uid;
                    final dur =
                        (c['duration_seconds'] as int?) ?? 0;
                    return ListTile(
                      leading: Icon(
                          c['call_type'] == 'video'
                              ? Icons.videocam
                              : Icons.call,
                          color: out ? Colors.blue : Colors.green),
                      title: Text(
                          '${out ? '→' : '←'} ${c['status']}'),
                      subtitle: Text(
                          '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}'),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      {'icon': Icons.account_balance_wallet, 'route': '/wallet', 'key': 'wallet'},
      {'icon': Icons.workspace_premium, 'route': '/subscribe', 'key': 'subscribe'},
      {'icon': Icons.upload, 'route': '/withdraw', 'key': 'withdraw'},
      {'icon': Icons.verified_user, 'route': '/verification', 'key': 'verification'},
      {'icon': Icons.support_agent, 'route': '/settings', 'key': 'support'},
      {'icon': Icons.settings, 'route': '/settings', 'key': 'settings'},
    ];
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'more'))),
      body: ListView(
        children: [
          for (final it in items)
            ListTile(
              leading: Icon(it['icon'] as IconData),
              title: Text(tr(ref, it['key'] as String)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.pushNamed(context, it['route'] as String),
            ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(tr(ref, 'logout'),
                style: const TextStyle(color: Colors.red)),
            onTap: () async {
              await Supa.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/landing', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
