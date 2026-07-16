import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

/// Uploads / deletes the signed-in user's single optimized avatar object.
///
/// One object path per user (`avatar.jpg`) — overwrites on each change so
/// Storage never keeps original large images or historical versions.
@lazySingleton
class ProfileAvatarStorage {
  ProfileAvatarStorage(this._storage);

  final FirebaseStorage _storage;

  /// Client pick target — enough for 3× retina of a ~96dp avatar.
  static const int maxEdgePx = 320;

  /// JPEG quality for [ImagePicker] — balances size vs clarity for avatars.
  static const int jpegQuality = 70;

  /// Soft client cap before upload (rules enforce a hard cap).
  static const int maxUploadBytes = 350 * 1024;

  static const String _fileName = 'avatar.jpg';

  Reference _ref(String userId) =>
      _storage.ref().child('users').child(userId).child(_fileName);

  /// True when [photoUrl] points at this app's avatar object (not Google CDN).
  static bool isManagedAvatarUrl(String? photoUrl, String userId) {
    final String url = photoUrl?.trim() ?? '';
    if (url.isEmpty) {
      return false;
    }
    return url.contains('/users%2F$userId%2F$_fileName') ||
        url.contains('/users/$userId/$_fileName');
  }

  /// Uploads an already-resized JPEG and returns a cache-busted download URL.
  Future<String> upload({
    required String userId,
    required String localPath,
  }) async {
    final File file = File(localPath);
    final int length = await file.length();
    if (length <= 0 || length > maxUploadBytes) {
      throw StateError('avatar_too_large');
    }

    final Reference ref = _ref(userId);
    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=31536000',
      ),
    );
    final String downloadUrl = await ref.getDownloadURL();
    // Same object path → same base URL; bust client image caches on replace.
    final Uri uri = Uri.parse(downloadUrl);
    return uri
        .replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            'v': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        )
        .toString();
  }

  /// Deletes the managed avatar object when present.
  Future<void> delete(String userId) async {
    try {
      await _ref(userId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }
}
