import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

/// Settings: language switch, privacy toggles, support, legal pages,
/// account deletion request.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _fbSupport =
      'https://www.facebook.com/profile.php?id=61594689478770';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'settings'))),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr(ref, 'language')),
            trailing: DropdownButton<String>(
              value: locale,
              items: const [
                DropdownMenuItem(
                    value: 'bn', child: Text('বাংলা')),
                DropdownMenuItem(
                    value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(localeProvider.notifier).state = v;
                  Supa.client.from('users').update(
                      {'language': v}).eq('id',
                      ref.read(currentUserIdProvider) ?? '');
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Backend Setup'),
            subtitle: Text(Supa.config?.isUserOverride == true
                ? 'Custom override active'
                : 'Build defaults'),
            onTap: () =>
                Navigator.pushNamed(context, '/setup'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(tr(ref, 'support')),
            subtitle: const Text('Facebook'),
            onTap: () => launchUrl(Uri.parse(_fbSupport),
                mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          FutureBuilder<List<dynamic>>(
            future: Supa.client
                .from('legal_pages')
                .select('slug, title')
                .order('slug'),
            builder: (context, snap) {
              final rows =
                  (snap.data ?? []).cast<Map<String, dynamic>>();
              return Column(
                children: [
                  for (final r in rows)
                    ListTile(
                      leading:
                          const Icon(Icons.description_outlined),
                      title: Text((r['title'] ?? r['slug']).toString()),
                      onTap: () => _showLegal(context, r['slug'] as String),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Account Deletion',
                style: TextStyle(color: Colors.red)),
            onTap: () => _requestDeletion(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showLegal(BuildContext context, String slug) async {
    final row = await Supa.client
        .from('legal_pages')
        .select('title, body_md')
        .eq('slug', slug)
        .maybeSingle();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text((row?['title'] ?? slug).toString()),
        content: SingleChildScrollView(
            child: Text((row?['body_md'] ?? '').toString())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _requestDeletion(
      BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Account Deletion'),
        content: const Text(
            'Your profile will be deactivated. Payment/security records may be retained as required by law. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr(ref, 'cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr(ref, 'ok'))),
        ],
      ),
    );
    if (confirm != true) return;
    await Supa.client.from('users').update({
      'status': 'deleted',
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
    await Supa.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/landing', (_) => false);
    }
  }
}
