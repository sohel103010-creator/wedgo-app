// Typed wrappers around Supabase Edge Functions + RPCs.
// Server is authoritative: permissions, billing, wallet, moderation all
// run backend-side. The client NEVER writes privileged rows directly.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class FunctionMissingException implements Exception {
  final String name;
  FunctionMissingException(this.name);
  @override
  String toString() =>
      'Edge Function "$name" is not deployed. See README § Backend setup.';
}

class ApiService {
  SupabaseClient get _c => Supa.client;

  Future<Map<String, dynamic>> _invoke(
      String name, Map<String, dynamic> body) async {
    try {
      final res = await _c.functions.invoke(name, body: body);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) {
          throw Exception(data['error'].toString());
        }
        return data;
      }
      return {'data': data};
    } on FunctionException catch (e) {
      // Supabase returns 404 when the function is not deployed.
      if (e.status == 404) throw FunctionMissingException(name);
      rethrow;
    }
  }

  // --- chat -------------------------------------------------------------
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    String kind = 'text',
    String? body,
    String? mediaPath,
    String? replyTo,
  }) =>
      _invoke('send-message', {
        'conversation_id': conversationId,
        'kind': kind,
        if (body != null) 'body': body,
        if (mediaPath != null) 'media_path': mediaPath,
        if (replyTo != null) 'reply_to': replyTo,
      });

  // --- calls ------------------------------------------------------------
  /// Returns {call_id, authorized_seconds, ...}. Throws needs_premium (402)
  /// when the male party has no qualifying package.
  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String callType, // audio|video
  }) =>
      _invoke('initiate-call', {
        'receiver_id': receiverId,
        'call_type': callType,
      });

  /// Idempotent server settlement. Returns {billed_seconds, earning_bdt}.
  Future<Map<String, dynamic>> endCall({
    required String callId,
    String endReason = 'hangup',
  }) =>
      _invoke('end-call', {'call_id': callId, 'end_reason': endReason});

  // --- payments ----------------------------------------------------------
  Future<Map<String, dynamic>> approvePayment({
    required String paymentId,
    required String action, // approve|reject
    String? note,
  }) =>
      _invoke('approve-payment', {
        'payment_id': paymentId,
        'action': action,
        if (note != null) 'note': note,
      });

  Future<Map<String, dynamic>> requestWithdrawal({
    required String accountId,
    required int amountBdt,
    required String pin,
  }) =>
      _invoke('request-withdrawal', {
        'account_id': accountId,
        'amount_bdt': amountBdt,
        'pin': pin,
      });

  // --- login helper -------------------------------------------------------
  /// Phone+password login needs a server-side phone->email resolution.
  /// REQUIRED: deploy the `resolve-login` Edge Function (contract below).
  /// Request:  { phone: "01XXXXXXXXX" }
  /// Response: { email: "user@example.com" } | { error: "not_found" }
  /// Until deployed, email+password login works; phone login shows the
  /// "requires setup" state instead of faking success.
  Future<String> resolveEmailForPhone(String phone) async {
    final data = await _invoke('resolve-login', {'phone': phone});
    final email = data['email'];
    if (email is! String || email.isEmpty) {
      throw Exception(data['error']?.toString() ?? 'not_found');
    }
    return email;
  }

  // --- admin ---------------------------------------------------------------
  /// Server-side role check. NEVER trust a client-side email comparison.
  Future<bool> checkIsAdmin(String uid) async {
    final res = await _c.rpc('is_admin', params: {'uid': uid});
    return res == true;
  }

  Future<String?> fetchAdminRole(String uid) async {
    final row = await _c
        .from('admin_roles')
        .select('role')
        .eq('user_id', uid)
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    return row['role'] as String?;
  }

  // --- misc -----------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchWebrtcConfig() async {
    final row =
        await _c.from('webrtc_config').select().eq('id', 1).maybeSingle();
    return row;
  }

  Future<Map<String, dynamic>?> fetchPaymentSettings() async {
    final row =
        await _c.from('payment_settings').select().eq('id', 1).maybeSingle();
    return row;
  }
}
