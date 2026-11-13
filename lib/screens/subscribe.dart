import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package.dart';
import '../providers/auth.dart';
import '../providers/packages.dart';
import '../providers/subscription.dart';

/// Subscription packages loaded from the `packages` table —
/// admin-editable without an app release.
class SubscribeScreen extends ConsumerWidget {
  const SubscribeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pkgs = ref.watch(packagesProvider);
    final sub = ref.watch(activeSubscriptionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'subscribe'))),
      body: pkgs.when(
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sub.when(
              data: (s) => s == null
                  ? const SizedBox.shrink()
                  : Card(
                      color: Colors.green.shade50,
                      child: ListTile(
                        title: Text(
                            '${tr(ref, 'active_package')}: ${s.package?.nameBn ?? s.packageId}'),
                        subtitle: Text(
                            '${tr(ref, 'remaining_days')}: ${s.remainingDays}'),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            for (final p in list) _packageCard(context, ref, p),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _packageCard(
      BuildContext context, WidgetRef ref, Package p) {
    final feats = <String>[];
    if (p.canText) feats.add('💬 Text');
    if (p.canPhoto) feats.add('🖼 Photo');
    if (p.canAudioCall) feats.add('🎧 Audio ${p.audioMinutes}m');
    if (p.canVideoCall) feats.add('🎥 Video ${p.videoMinutes}m');
    if (p.canSharePhone) feats.add('📞 Number');
    if (p.canShareLink) feats.add('🔗 Link');
    feats.add(p.profileViewLimit == null
        ? '👁 Unlimited views'
        : '👁 ${p.profileViewLimit} views');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.nameBn,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge),
                ),
                Text('৳${p.priceBdt}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${p.durationDays} days'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final f in feats) Chip(label: Text(f))],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pushNamed(
                  context, '/pay',
                  arguments: p.id),
              child: Text(tr(ref, 'buy')),
            ),
          ],
        ),
      ),
    );
  }
}
