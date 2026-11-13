import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';
import '../services/api.dart';

/// Realtime chat room. Messages stream from Supabase; sending goes
/// through the 'send-message' Edge Function (server validates package
/// permissions + contact-info filter — clients can't bypass).
class ChatRoomScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherName;
  final String otherUserId;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Stream<List<ChatMessage>> _messages(String myId) {
    return Supa.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at')
        .map((rows) => rows
            .map((r) => ChatMessage.fromJson(r, myId))
            .toList());
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).sendMessage(
            conversationId: widget.conversationId,
            body: body,
          );
      _text.clear();
    } on FunctionMissingException catch (e) {
      setState(() => _error = tr(ref, 'requires_setup') + ' ($e)');
    } catch (e) {
      // Server rejections (needs_premium, contact_blocked, suspended…)
      // surface here — never silently dropped.
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserIdProvider);
    if (myId == null) {
      return Scaffold(
          body: Center(child: Text(tr(ref, 'empty'))));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => Navigator.pushNamed(context, '/call',
                arguments: {
                  'otherUserId': widget.otherUserId,
                  'otherName': widget.otherName,
                  'callType': 'audio',
                }),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => Navigator.pushNamed(context, '/call',
                arguments: {
                  'otherUserId': widget.otherUserId,
                  'otherName': widget.otherName,
                  'callType': 'video',
                }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages(myId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final msgs = snap.data!;
                if (msgs.isEmpty) {
                  return Center(
                      child: Text(tr(ref, 'empty')));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[msgs.length - 1 - i];
                    return _bubble(m);
                  },
                );
              },
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(8),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _text,
                      decoration: InputDecoration(
                        hintText: tr(ref, 'type_message'),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (m.isDeletedForAll)
              const Text('(deleted)',
                  style: TextStyle(fontStyle: FontStyle.italic))
            else
              Text(m.body ?? ''),
            Text(
              '${m.createdAt.hour}:${m.createdAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
