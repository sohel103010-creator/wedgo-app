import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth.dart';
import '../services/supabase_client.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      // Runtime backend config: no saved values and no --dart-define
      // defaults -> first-launch Setup screen (no rebuild needed).
      if (!Supa.ready) {
        Navigator.pushReplacementNamed(context, '/setup');
        return;
      }
      final uid = ref.read(currentUserIdProvider);
      Navigator.pushReplacementNamed(
          context, uid == null ? '/landing' : '/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, size: 72, color: Color(0xFF8B1E2D)),
            const SizedBox(height: 12),
            Text('WedGo',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(tr(ref, 'app_tagline')),
          ],
        ),
      ),
    );
  }
}
