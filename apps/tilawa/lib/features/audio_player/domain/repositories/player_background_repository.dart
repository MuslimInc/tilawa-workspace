import 'package:image_picker/image_picker.dart';

abstract class PlayerBackgroundRepository {
  /// Picks an image from the specified source.
  Future<String?> pickImage(ImageSource source);

  /// Persists the image to app storage and returns the new path.
  Future<String> persistImage(String originalPath);

  /// Deletes an image file from storage.
  Future<void> deleteImage(String path);
}
