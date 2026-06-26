/// Platform booking policy for Quran tutor sessions.
enum QuranTutorBookingMode {
  autoConfirm,
  requiresTutorApproval,
}

extension QuranTutorBookingModeParsing on QuranTutorBookingMode {
  static QuranTutorBookingMode? tryParse(String? raw) => switch (raw) {
    'autoConfirm' => QuranTutorBookingMode.autoConfirm,
    'requiresTutorApproval' => QuranTutorBookingMode.requiresTutorApproval,
    _ => null,
  };

  bool get requiresTutorApproval =>
      this == QuranTutorBookingMode.requiresTutorApproval;
}

/// Distribution default when Firestore / dart-define are missing.
QuranTutorBookingMode distributionDefaultQuranTutorBookingMode({
  String distribution = const String.fromEnvironment(
    'TILAWA_DISTRIBUTION',
    defaultValue: 'local',
  ),
}) {
  return distribution == 'play_production'
      ? QuranTutorBookingMode.requiresTutorApproval
      : QuranTutorBookingMode.autoConfirm;
}
