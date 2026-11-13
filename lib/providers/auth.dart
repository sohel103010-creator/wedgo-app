// Auth + member state (Riverpod).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/strings.dart';
import '../services/supabase_client.dart';
import '../services/api.dart';
import '../models/profile.dart';

final localeProvider = StateProvider<String>((ref) => 'bn');
String tr(WidgetRef ref, String key) =>
    AppStrings.tr(ref.watch(localeProvider), key);

final apiProvider = Provider<ApiService>((ref) => ApiService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!Supa.ready) return const Stream.empty();
  return Supa.client.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final s = ref.watch(authStateProvider).valueOrNull;
  return s?.session?.user.id;
});

/// Raw public.users row for the signed-in member (null when logged out).
final userRowProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  final row = await Supa.client
      .from('users')
      .select()
      .eq('id', uid)
      .maybeSingle();
  return row;
});

/// Combined member profile (users + profiles rows).
final memberProfileProvider =
    FutureProvider<WedGoProfile?>((ref) async {
  final user = await ref.watch(userRowProvider.future);
  if (user == null) return null;
  final profile = await Supa.client
      .from('profiles')
      .select()
      .eq('user_id', user['id'])
      .maybeSingle();
  var p = WedGoProfile.fromJson(user, profile);
  // Resolve main photo via signed URL (profile-images bucket is private).
  try {
    final media = await Supa.client
        .from('profile_media')
        .select('storage_path')
        .eq('user_id', user['id'])
        .eq('media_type', 'main')
        .order('sort_order')
        .limit(1)
        .maybeSingle();
    final path = media?['storage_path'] as String?;
    if (path != null) {
      final url = await Supa.client.storage
          .from('profile-images')
          .createSignedUrl(path, 3600);
      p = p.copyWithPhoto(url);
    }
  } catch (_) {/* photo optional */}
  return p;
});

/// Admin role for the signed-in user (null = not an admin).
final adminRoleProvider = FutureProvider<String?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  final api = ref.watch(apiProvider);
  if (!await api.checkIsAdmin(uid)) return null;
  return api.fetchAdminRole(uid);
});
