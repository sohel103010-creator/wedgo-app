import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  Future<List<Conversation>> _load(String uid) async {
    final memberships = await Supa.client
        .from('conversation_members')
        .select('conversation_id, conversations(last_message_at)')
        .eq('user_id', uid)
        .isFilter('left_at', null);
    final list = <Conversation>[];
    for (final m in (memberships as List)) {
      final mm = m as Map<String, dynamic>;
      final cid = mm['conversation_id'] as String;
      final members = await Supa.client
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', cid)
          .neq('user_id', uid)
          .limit(1);
      if ((members as List).isEmpty) continue;
      final otherId =
          ((members as List).first as Map)['user_id'] as String;
      final user = await Supa.client
          .from('users')
          .select('full_name')
          .eq('id', otherId)
          .maybeSingle();
      final last = await Supa.client
          .from('messages')
          .select('body, created_at')
          .eq('conversation_id', cid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      list.add(Conversation(
        id: cid,
        otherUserId: otherId,
        otherName:
            (user?['full_name'] ?? '—') as String,
        lastBody: last?['body'] as String?,
        lastMessageAt: last?['created_at'] == null
            ? null
            : DateTime.parse(last!['created_at'] as String),
      ));
    }
    list.sort((a, b) => (b.lastMessageAt ??
            DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.lastMessageAt ??
            DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'messages'))),
      body: uid == null
          ? Center(child: Text(tr(ref, 'empty')))
          : FutureBuilder<List<Conversation>>(
              future: _load(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return Center(child: Text(tr(ref, 'empty')));
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.person)),
                        title: Text(c.otherName),
                        subtitle: Text(c.lastBody ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        onTap: () =>
                            Navigator.pushNamed(context, '/chat',
                                arguments: {
                              'conversationId': c.id,
                              'otherName': c.otherName,
                              'otherUserId': c.otherUserId,
                            }),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
