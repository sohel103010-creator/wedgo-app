import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../providers/auth.dart';
import '../providers/subscription.dart';
import '../services/supabase_client.dart';
import '../widgets/premium_gate.dart';

class ProfileDetailScreen extends ConsumerWidget {
  final String userId;
  const ProfileDetailScreen({super.key, required this.userId});

  Future<WedGoProfile?> _load(WidgetRef ref) async {
    final user = await Supa.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (user == null) return null;
    final profile = await Supa.client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    var p = WedGoProfile.fromJson(user, profile);
    try {
      final media = await Supa.client
          .from('profile_media')
          .select('storage_path')
          .eq('user_id', userId)
          .eq('media_type', 'main')
          .eq('is_approved', true)
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
    } catch (_) {}
    return p;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(hasPremiumProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'find_partner'))),
      body: premium.when(
        data: (isPremium) {
          if (!isPremium) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
              PremiumGate.show(context, ref);
            });
            return const SizedBox.shrink();
          }
          return FutureBuilder<WedGoProfile?>(
            future: _load(ref),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final p = snap.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (p.photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(p.photoUrl!,
                          height: 280, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall),
                      ),
                      if (p.isVerified)
                        const Icon(Icons.verified,
                            color: Colors.blueAccent),
                    ],
                  ),
                  Text('${p.age ?? '—'} • ${p.district ?? ''}'),
                  const Divider(),
                  _row('profile_code', p.profileCode),
                  _row('height', p.heightCm?.toString()),
                  _row('religion', p.religion),
                  _row('education', p.education),
                  _row('profession', p.profession),
                  _row('marital_status', p.maritalStatus),
                  if (p.aboutMe != null)
                    _row('about', p.aboutMe),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.call),
                          label:
                              Text(tr(ref, 'audio_call')),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/call',
                                  arguments: {
                                'otherUserId': p.userId,
                                'otherName': p.fullName,
                                'callType': 'audio',
                              }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.videocam),
                          label:
                              Text(tr(ref, 'video_call')),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/call',
                                  arguments: {
                                'otherUserId': p.userId,
                                'otherName': p.fullName,
                                'callType': 'video',
                              }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.message),
                    label: Text(tr(ref, 'messages')),
                    onPressed: () =>
                        _openChat(context, ref, p),
                  ),
                ],
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _row(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 130,
                child: Text(label,
                    style:
                        const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value ?? '—')),
          ],
        ),
      );

  Future<void> _openChat(
      BuildContext context, WidgetRef ref, WedGoProfile p) async {
    final me = ref.read(currentUserIdProvider)!;
    try {
      // Find existing 1:1 conversation or create one.
      // BACKEND REQUIREMENT: needs INSERT policies on conversations +
      // conversation_members, or a get-or-create-conversation Edge Function
      // (currently missing). RLS errors surface honestly below.
      final mine = await Supa.client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', me);
      String? convId;
      for (final m in (mine as List)) {
        final cid = (m as Map)['conversation_id'] as String;
        final other = await Supa.client
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', cid)
            .eq('user_id', p.userId)
            .maybeSingle();
        if (other != null) {
          convId = cid;
          break;
        }
      }
      convId ??= await Supa.client
          .from('conversations')
          .insert(<String, dynamic>{'is_pinned': false})
          .select('id')
          .single()
          .then((r) => (r as Map)['id'] as String);
      await Supa.client.from('conversation_members').upsert([
        {'conversation_id': convId, 'user_id': me},
        {'conversation_id': convId, 'user_id': p.userId},
      ]);
      if (context.mounted) {
        Navigator.pushNamed(context, '/chat', arguments: {
          'conversationId': convId,
          'otherName': p.fullName,
          'otherUserId': p.userId,
        });
      }
    } on PostgrestException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${tr(ref, 'requires_setup')} (conversations: ${e.code})')));
      }
    }
  }
}
