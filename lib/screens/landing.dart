import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';

/// Public landing: branding, required headline, login/register,
/// admin login in the top corner, blurred demo profile cards.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WedGo'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/admin-login'),
            child: Text(tr(ref, 'admin_login')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.favorite, size: 64, color: Color(0xFF8B1E2D)),
          const SizedBox(height: 12),
          Text(
            tr(ref, 'landing_headline'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr(ref, 'login')),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/register'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr(ref, 'register')),
            ),
          ),
          const SizedBox(height: 28),
          _DemoStrip(ref),
        ],
      ),
    );
  }
}

/// Fictional sample profiles — blurred, clearly internal-only.
/// Tapping shows "register to view". NEVER mixed into Find Partner.
class _DemoStrip extends StatelessWidget {
  final WidgetRef ref;
  const _DemoStrip(this.ref);

  @override
  Widget build(BuildContext context) {
    // Placeholder silhouettes (no real-person imagery).
    final demos = [
      {'name': '••••', 'meta': '••'},
      {'name': '••••', 'meta': '••'},
      {'name': '••••', 'meta': '••'},
      {'name': '••••', 'meta': '••'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: demos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr(ref, 'demo_profile_msg'))),
              ),
              child: _demoCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _demoCard() {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade300,
      ),
      child: const Stack(
        fit: StackFit.expand,
        children: [
          Icon(Icons.person, size: 56, color: Colors.white),
          Positioned(
            bottom: 8,
            left: 8,
            child: Text('••••••',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
