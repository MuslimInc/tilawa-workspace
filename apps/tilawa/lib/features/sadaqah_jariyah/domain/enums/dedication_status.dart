enum DedicationStatus {
  draft,
  published,
  archived;

  String get wireValue => name;

  static DedicationStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final DedicationStatus value in DedicationStatus.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}
