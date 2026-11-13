import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<List<Map<String, dynamic>>> _load(String uid) async {
    final rows = await Supa.client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    final bn = ref.watch(localeProvider) == 'bn';
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'notifications'))),
      body: uid == null
          ? Center(child: Text(tr(ref, 'empty')))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _load(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(
                      child: Text(tr(ref, 'empty')));
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final n = items[i];
                      final title = bn &&
                              (n['title_bn'] as String?)
                                      ?.isNotEmpty ==
                                  true
                          ? n['title_bn'] as String
                          : n['title'] as String;
                      final body = bn &&
                              (n['body_bn'] as String?)
                                      ?.isNotEmpty ==
                                  true
                          ? n['body_bn'] as String
                          : (n['body'] as String? ?? '');
                      final read =
                          (n['is_read'] ?? false) as bool;
                      return ListTile(
                        tileColor: read
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.35),
                        title: Text(title,
                            style: TextStyle(
                                fontWeight: read
                                    ? FontWeight.normal
                                    : FontWeight.bold)),
                        subtitle: Text(body,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis),
                        onTap: () {
                          Supa.client
                              .from('notifications')
                              .update({'is_read': true}).eq(
                                  'id', n['id']);
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
