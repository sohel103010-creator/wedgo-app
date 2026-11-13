// Mirrors public.calls. Billing/settlement is authoritative server-side
// (settle_call via 'end-call'). Client timers are display-only.
class CallRecord {
  final String id;
  final String callerId;
  final String receiverId;
  final String callType; // audio|video
  final String status; // ringing|active|ended|rejected|missed|failed
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final int? billedSeconds;

  const CallRecord({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
    this.billedSeconds,
  });

  factory CallRecord.fromJson(Map<String, dynamic> j) => CallRecord(
        id: j['id'] as String,
        callerId: j['caller_id'] as String,
        receiverId: j['receiver_id'] as String,
        callType: (j['call_type'] ?? 'audio') as String,
        status: (j['status'] ?? 'ended') as String,
        startedAt: DateTime.parse(j['started_at'] as String),
        answeredAt: j['answered_at'] == null
            ? null
            : DateTime.parse(j['answered_at'] as String),
        endedAt: j['ended_at'] == null
            ? null
            : DateTime.parse(j['ended_at'] as String),
        durationSeconds: j['duration_seconds'] as int?,
        billedSeconds: j['billed_seconds'] as int?,
      );
}
