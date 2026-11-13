// Mirrors public.users + public.profiles (+ main photo path).
class WedGoProfile {
  final String userId;
  final String profileCode;
  final String fullName;
  final String gender; // 'male' | 'female'
  final int? age;
  final int? heightCm;
  final String? district;
  final String? division;
  final String? religion;
  final String? education;
  final String? profession;
  final String? maritalStatus;
  final String? aboutMe;
  final String? partnerExpectations;
  final String? ghorJamai; // 'yes' | 'no' | null
  final int completionPct;
  final String verificationStatus; // none|pending|verified|rejected
  final bool isFeatured;
  final bool phoneVerified;
  final bool emailVerified;
  final String? photoUrl; // signed URL resolved by caller (never stored here)

  const WedGoProfile({
    required this.userId,
    required this.profileCode,
    required this.fullName,
    required this.gender,
    this.age,
    this.heightCm,
    this.district,
    this.division,
    this.religion,
    this.education,
    this.profession,
    this.maritalStatus,
    this.aboutMe,
    this.partnerExpectations,
    this.ghorJamai,
    this.completionPct = 0,
    this.verificationStatus = 'none',
    this.isFeatured = false,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.photoUrl,
  });

  factory WedGoProfile.fromJson(
      Map<String, dynamic> user, Map<String, dynamic>? profile) {
    final p = profile ?? <String, dynamic>{};
    return WedGoProfile(
      userId: user['id'] as String,
      profileCode: (p['profile_code'] ?? '') as String,
      fullName: (user['full_name'] ?? '') as String,
      gender: (user['gender'] ?? 'male') as String,
      age: p['age'] as int?,
      heightCm: p['height_cm'] as int?,
      district: p['district'] as String?,
      division: p['division'] as String?,
      religion: p['religion'] as String?,
      education: p['education'] as String?,
      profession: p['profession'] as String?,
      maritalStatus: p['marital_status'] as String?,
      aboutMe: p['about_me'] as String?,
      partnerExpectations: p['partner_expectations'] as String?,
      ghorJamai: p['ghor_jamai'] as String?,
      completionPct: (p['completion_pct'] ?? 0) as int,
      verificationStatus: (p['verification_status'] ?? 'none') as String,
      isFeatured: (p['is_featured'] ?? false) as bool,
      phoneVerified: (user['phone_verified'] ?? false) as bool,
      emailVerified: (user['email_verified'] ?? false) as bool,
    );
  }

  WedGoProfile copyWithPhoto(String? url) => WedGoProfile(
        userId: userId,
        profileCode: profileCode,
        fullName: fullName,
        gender: gender,
        age: age,
        heightCm: heightCm,
        district: district,
        division: division,
        religion: religion,
        education: education,
        profession: profession,
        maritalStatus: maritalStatus,
        aboutMe: aboutMe,
        partnerExpectations: partnerExpectations,
        ghorJamai: ghorJamai,
        completionPct: completionPct,
        verificationStatus: verificationStatus,
        isFeatured: isFeatured,
        phoneVerified: phoneVerified,
        emailVerified: emailVerified,
        photoUrl: url,
      );

  bool get isVerified => verificationStatus == 'verified';
}
