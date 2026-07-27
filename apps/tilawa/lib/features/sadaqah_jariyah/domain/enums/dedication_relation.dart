enum DedicationRelation {
  father,
  mother,
  brother,
  sister,
  husband,
  wife,
  son,
  daughter,
  friend,
  other;

  String get wireValue => name;

  static DedicationRelation? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final DedicationRelation value in DedicationRelation.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}
