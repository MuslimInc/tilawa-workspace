abstract final class AudioExtrasKeys {
  static const String surahId = 'surahId';
  static const String reciterId = 'reciterId';
  static const String moshafId = 'moshafId';
  static const String moshafName = 'moshafName';
  static const String nameAr = 'nameAr';
  static const String ayahNumber = 'ayahNumber';
}

/// Safe readers for the untyped values stored in [AudioEntity.extras].
extension AudioExtras on Map<String, dynamic>? {
  /// Reads [key] as a [String], converting numeric values when necessary.
  String? getString(String key) {
    final dynamic value = this?[key];
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }

  /// Reads [key] as an [int], parsing string values when necessary.
  int? getInt(String key) {
    final dynamic value = this?[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
