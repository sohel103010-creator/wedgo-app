// Mirrors public.packages — pricing/policy is DATA from Supabase,
// never hardcoded. Admin edits it without an app release.
class Package {
  final String id;
  final String name;
  final String nameBn;
  final int priceBdt;
  final int durationDays;
  final bool canText;
  final bool canPhoto;
  final bool canAudioCall;
  final bool canVideoCall;
  final bool canVoiceMessage;
  final bool canSharePhone;
  final bool canShareLink;
  final int? profileViewLimit; // null = unlimited
  final int audioMinutes;
  final int videoMinutes;
  final bool isActive;

  const Package({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.priceBdt,
    required this.durationDays,
    required this.canText,
    required this.canPhoto,
    required this.canAudioCall,
    required this.canVideoCall,
    required this.canVoiceMessage,
    required this.canSharePhone,
    required this.canShareLink,
    this.profileViewLimit,
    required this.audioMinutes,
    required this.videoMinutes,
    required this.isActive,
  });

  factory Package.fromJson(Map<String, dynamic> j) => Package(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        nameBn: (j['name_bn'] ?? '') as String,
        priceBdt: (j['price_bdt'] ?? 0) as int,
        durationDays: (j['duration_days'] ?? 30) as int,
        canText: (j['can_text'] ?? false) as bool,
        canPhoto: (j['can_photo'] ?? false) as bool,
        canAudioCall: (j['can_audio_call'] ?? false) as bool,
        canVideoCall: (j['can_video_call'] ?? false) as bool,
        canVoiceMessage: (j['can_voice_message'] ?? false) as bool,
        canSharePhone: (j['can_share_phone'] ?? false) as bool,
        canShareLink: (j['can_share_link'] ?? false) as bool,
        profileViewLimit: j['profile_view_limit'] as int?,
        audioMinutes: (j['audio_minutes'] ?? 0) as int,
        videoMinutes: (j['video_minutes'] ?? 0) as int,
        isActive: (j['is_active'] ?? true) as bool,
      );
}
