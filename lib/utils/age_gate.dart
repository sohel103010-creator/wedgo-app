// Hard 18+ age gate. Used by registration AND anywhere a DOB is taken.
// Server re-validates independently — never trust the client alone.
class AgeGate {
  static const int adultAge = 18;

  /// Full years between dob and today.
  static int calcAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  static bool isAdult(DateTime dob) => calcAge(dob) >= adultAge;

  /// Returns an error message key, or null when the DOB is acceptable.
  static String? validateDob(DateTime? dob) {
    if (dob == null) return 'dob';
    if (dob.isAfter(DateTime.now())) return 'dob';
    if (!isAdult(dob)) return 'must_be_18';
    return null;
  }
}
