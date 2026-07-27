abstract class DedicationPhotoUrlResolver {
  /// Returns an HTTPS download URL, or null when [photoStoragePath] is null
  /// or resolution fails.
  Future<String?> resolveDownloadUrl(String? photoStoragePath);
}
