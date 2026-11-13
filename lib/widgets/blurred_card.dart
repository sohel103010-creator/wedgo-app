// Profile card with privacy blur. Tapping a locked card shows the
// premium gate instead of the profile.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/profile.dart';

class BlurredProfileCard extends StatelessWidget {
  final WedGoProfile profile;
  final bool locked;
  final VoidCallback onTap;

  const BlurredProfileCard({
    super.key,
    required this.profile,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _photo(),
                  if (locked)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                        child: const Icon(Icons.lock,
                            color: Colors.white, size: 40),
                      ),
                    ),
                  if (profile.isVerified && !locked)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.verified,
                          color: Colors.blueAccent, size: 22),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locked ? '••••••' : profile.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    locked
                        ? '••'
                        : '${profile.age ?? '—'} • ${profile.district ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo() {
    if (profile.photoUrl != null) {
      return Image.network(profile.photoUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, size: 48, color: Colors.white),
      );
}
