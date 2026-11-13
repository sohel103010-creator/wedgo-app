// Active subscription + premium state for the signed-in member.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/supabase_client.dart';
import 'auth.dart';

/// The member's currently active subscription (with package + usage meters).
/// Server is authoritative: status/expiry come from the DB, never the client.
final activeSubscriptionProvider =
    FutureProvider<Subscription?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  final now = DateTime.now().toUtc().toIso8601String();
  final row = await Supa.client
      .from('subscriptions')
      .select('*, packages(*)')
      .eq('user_id', uid)
      .eq('status', 'active')
      .gt('expires_at', now)
      .order('expires_at', ascending: false)
      .limit(1)
      .maybeSingle();
  if (row == null) return null;
  var sub = Subscription.fromJson(row);
  final usage = await Supa.client
      .from('subscription_usage')
      .select()
      .eq('subscription_id', sub.id)
      .maybeSingle();
  if (usage != null) sub = sub.withUsage(usage);
  return sub;
});

/// Convenience: does the signed-in member currently hold a usable package?
/// Female members never need one (server still governs per male package).
final hasPremiumProvider = FutureProvider<bool>((ref) async {
  final sub = await ref.watch(activeSubscriptionProvider.future);
  return sub != null && sub.isActive;
});
