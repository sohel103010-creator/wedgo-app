// Mirrors public.messages. Rows are created ONLY by the
// 'send-message' Edge Function — the client never inserts directly.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String kind; // text|image|voice|system
  final String? body;
  final String? mediaPath;
  final String? replyTo;
  final bool isDeletedForAll;
  final DateTime createdAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.kind,
    this.body,
    this.mediaPath,
    this.replyTo,
    required this.isDeletedForAll,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j, String myId) =>
      ChatMessage(
        id: j['id'] as String,
        conversationId: j['conversation_id'] as String,
        senderId: j['sender_id'] as String,
        kind: (j['kind'] ?? 'text') as String,
        body: j['body'] as String?,
        mediaPath: j['media_path'] as String?,
        replyTo: j['reply_to'] as String?,
        isDeletedForAll: (j['is_deleted_for_all'] ?? false) as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
        isMine: (j['sender_id'] as String) == myId,
      );
}

class Conversation {
  final String id;
  final String otherUserId;
  final String otherName;
  final String? otherPhotoUrl;
  final String? lastBody;
  final DateTime? lastMessageAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
    this.lastBody,
    this.lastMessageAt,
    this.unread = 0,
  });
}
