// Mirrors public.subscriptions (+ joined package + usage meters).
import 'package.dart';
class Subscription {
  final String id;
  final String userId;
  final String packageId;
  final int pricePaidBdt;
  final String status; // pending|active|expired|cancelled
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final Package? package;
  final int audioSecondsUsed;
  final int videoSecondsUsed;
  final int extraVideoSeconds;
  final int profileViewsUsed;

  const Subscription({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.pricePaidBdt,
    required this.status,
    this.activatedAt,
    this.expiresAt,
    this.package,
    this.audioSecondsUsed = 0,
    this.videoSecondsUsed = 0,
    this.extraVideoSeconds = 0,
    this.profileViewsUsed = 0,
  });

  bool get isActive =>
      status == 'active' &&
      expiresAt != null &&
      expiresAt!.isAfter(DateTime.now());

  int get remainingDays {
    if (expiresAt == null) return 0;
    final d = expiresAt!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  int get audioSecondsLeft {
    final total = (package?.audioMinutes ?? 0) * 60;
    final left = total - audioSecondsUsed;
    return left < 0 ? 0 : left;
  }

  int get videoSecondsLeft {
    final total = (package?.videoMinutes ?? 0) * 60 + extraVideoSeconds;
    final left = total - videoSecondsUsed;
    return left < 0 ? 0 : left;
  }

  factory Subscription.fromJson(Map<String, dynamic> j) {
    final pkgJson = j['packages'];
    return Subscription(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      packageId: j['package_id'] as String,
      pricePaidBdt: (j['price_paid_bdt'] ?? 0) as int,
      status: (j['status'] ?? 'pending') as String,
      activatedAt: j['activated_at'] == null
          ? null
          : DateTime.parse(j['activated_at'] as String),
      expiresAt: j['expires_at'] == null
          ? null
          : DateTime.parse(j['expires_at'] as String),
      package: pkgJson is Map<String, dynamic>
          ? Package.fromJson(pkgJson)
          : null,
    );
  }

  Subscription withUsage(Map<String, dynamic> u) => Subscription(
        id: id,
        userId: userId,
        packageId: packageId,
        pricePaidBdt: pricePaidBdt,
        status: status,
        activatedAt: activatedAt,
        expiresAt: expiresAt,
        package: package,
        audioSecondsUsed: (u['audio_seconds_used'] ?? 0) as int,
        videoSecondsUsed: (u['video_seconds_used'] ?? 0) as int,
        extraVideoSeconds: (u['extra_video_seconds'] ?? 0) as int,
        profileViewsUsed: (u['profile_views_used'] ?? 0) as int,
      );
}
