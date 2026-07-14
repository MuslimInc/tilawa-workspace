import '../../domain/entities/forced_update_policy.dart';

const String kForcedUpdateAndroidMinBuildField = 'android_min_build_number';
const String kForcedUpdateIosMinBuildField = 'ios_min_build_number';

/// Maps Firestore JSON to [ForcedUpdatePolicy]. Invalid fields fail open as null.
ForcedUpdatePolicy mapForcedUpdatePolicy(Map<String, dynamic> json) {
  return ForcedUpdatePolicy(
    androidMinBuildNumber: readForcedUpdateInt(
      json[kForcedUpdateAndroidMinBuildField],
    ),
    iosMinBuildNumber: readForcedUpdateInt(json[kForcedUpdateIosMinBuildField]),
  );
}

int? readForcedUpdateInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
