import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/player_background_configuration.dart';
import '../../domain/repositories/player_background_repository.dart';
import '../models/player_background_configuration_model.dart';

@LazySingleton(as: PlayerBackgroundRepository)
class PlayerBackgroundRepositoryImpl implements PlayerBackgroundRepository {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    return image?.path;
  }

  @override
  Future<String> persistImage(String originalPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final backgroundsDir = Directory(
      p.join(directory.path, 'player_backgrounds'),
    );

    if (!await backgroundsDir.exists()) {
      await backgroundsDir.create(recursive: true);
    }

    final String extension = p.extension(originalPath);
    final String fileName =
        'custom_bg_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String newPath = p.join(backgroundsDir.path, fileName);

    await File(originalPath).copy(newPath);
    return newPath;
  }

  @override
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore deletion errors as per repository policy
    }
  }

  @override
  PlayerBackgroundConfiguration decodePersistedConfiguration(
    Map<String, dynamic> json,
  ) {
    return PlayerBackgroundConfigurationModel.fromJson(json);
  }

  @override
  Map<String, dynamic> encodeConfiguration(
    PlayerBackgroundConfiguration config,
  ) {
    return PlayerBackgroundConfigurationModel.fromEntity(config).toJson();
  }
}
