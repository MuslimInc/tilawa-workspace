import 'package:firebase_storage/firebase_storage.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/services/dedication_photo_url_resolver.dart';

class FirebaseDedicationPhotoUrlResolver implements DedicationPhotoUrlResolver {
  FirebaseDedicationPhotoUrlResolver(this._storage);

  final FirebaseStorage _storage;
  final Map<String, _CachedUrl> _cache = <String, _CachedUrl>{};
  static const Duration _ttl = Duration(minutes: 55);

  @override
  Future<String?> resolveDownloadUrl(String? photoStoragePath) async {
    final String? path = photoStoragePath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    if (!path.startsWith('photos/dedications/')) {
      logger.d(
        '[SadaqahJariyah] Rejected photo path outside dedications: $path',
      );
      return null;
    }
    final _CachedUrl? cached = _cache[path];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }
    try {
      final String url = await _storage.ref(path).getDownloadURL();
      _cache[path] = _CachedUrl(url, DateTime.now().add(_ttl));
      return url;
    } on Object catch (e) {
      logger.d('[SadaqahJariyah] Photo resolve failed for $path: $e');
      return null;
    }
  }
}

class _CachedUrl {
  _CachedUrl(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
