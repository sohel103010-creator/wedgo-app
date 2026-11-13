import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../providers/auth.dart';
import '../providers/subscription.dart';
import '../services/supabase_client.dart';
import '../widgets/blurred_card.dart';
import '../widgets/premium_gate.dart';

/// Partner discovery. Shows ONLY real registered members (never demo
/// profiles). Cards are blurred/locked according to the viewer's package;
/// tapping a locked card shows the premium gate.
class FindPartnerScreen extends ConsumerStatefulWidget {
  const FindPartnerScreen({super.key});

  @override
  ConsumerState<FindPartnerScreen> createState() =>
      _FindPartnerScreenState();
}

class _FindPartnerScreenState
    extends ConsumerState<FindPartnerScreen> {
  String? _district;
  String? _genderFilter;

  Future<List<WedGoProfile>> _load(bool canViewUnlimited) async {
    var q = Supa.client.from('users').select(
        'id, full_name, gender, phone_verified, email_verified, profiles(*)');
    final me = ref.read(currentUserIdProvider);
    if (me != null) q = q.neq('id', me);
    q = q.eq('status', 'active');
    if (_genderFilter != null) q = q.eq('gender', _genderFilter!);
    final rows = await q.limit(60);
    final list = <WedGoProfile>[];
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      final prof = (m['profiles'] as Map<String, dynamic>?);
      var p = WedGoProfile.fromJson(m, prof);
      // Signed photo URL (private bucket) — null when locked/hidden.
      try {
        final media = await Supa.client
            .from('profile_media')
            .select('storage_path')
            .eq('user_id', p.userId)
            .eq('media_type', 'main')
            .eq('is_approved', true)
            .order('sort_order')
            .limit(1)
            .maybeSingle();
        final path = media?['storage_path'] as String?;
        if (path != null && canViewUnlimited) {
          final url = await Supa.client.storage
              .from('profile-images')
              .createSignedUrl(path, 3600);
          p = p.copyWithPhoto(url);
        }
      } catch (_) {}
      list.add(p);
    }
    if (_district != null && _district!.isNotEmpty) {
      list.retainWhere((p) => p.district == _district);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(hasPremiumProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'find_partner')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _filterSheet(context),
          ),
        ],
      ),
      body: premium.when(
        data: (isPremium) => FutureBuilder<List<WedGoProfile>>(
          future: _load(isPremium),
          builder: (context, snap) {
            if (snap.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                  child: Text(
                      '${tr(ref, 'error')}: ${snap.error}'));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Center(child: Text(tr(ref, 'empty')));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                return BlurredProfileCard(
                  profile: p,
                  locked: !isPremium,
                  onTap: () {
                    if (!isPremium) {
                      PremiumGate.show(context, ref);
                    } else {
                      Navigator.pushNamed(context, '/profile',
                          arguments: p.userId);
                    }
                  },
                );
              },
            );
          },
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  void _filterSheet(BuildContext context) {
    final genders = [null, 'male', 'female'];
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(ref, 'gender'),
                style: Theme.of(context).textTheme.titleMedium),
            for (final g in genders)
              RadioListTile<String?>(
                title: Text(g == null
                    ? '—'
                    : tr(ref, g == 'male' ? 'male' : 'female')),
                value: g,
                groupValue: _genderFilter,
                onChanged: (v) {
                  setState(() => _genderFilter = v);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
