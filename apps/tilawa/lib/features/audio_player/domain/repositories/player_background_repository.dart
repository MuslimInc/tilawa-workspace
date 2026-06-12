import 'package:image_picker/image_picker.dart';

import '../entities/player_background_configuration.dart';

abstract class PlayerBackgroundRepository {
  /// Picks an image from the specified source.
  Future<String?> pickImage(ImageSource source);

  /// Persists the image to app storage and returns the new path.
  Future<String> persistImage(String originalPath);

  /// Deletes an image file from storage.
  Future<void> deleteImage(String path);

  /// Restores persisted player background settings from hydrated storage JSON.
  PlayerBackgroundConfiguration decodePersistedConfiguration(
    Map<String, dynamic> json,
  );

  /// Serializes player background settings for hydrated storage.
  Map<String, dynamic> encodeConfiguration(
    PlayerBackgroundConfiguration config,
  );
}
