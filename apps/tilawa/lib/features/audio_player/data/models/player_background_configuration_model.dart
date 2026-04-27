import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/player_background_configuration.dart';

part 'player_background_configuration_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PlayerBackgroundConfigurationModel extends PlayerBackgroundConfiguration {
  const PlayerBackgroundConfigurationModel({
    super.type,
    super.customImagePath,
    super.blurAmount,
    super.overlayOpacity,
  });

  factory PlayerBackgroundConfigurationModel.fromEntity(
    PlayerBackgroundConfiguration entity,
  ) {
    return PlayerBackgroundConfigurationModel(
      type: entity.type,
      customImagePath: entity.customImagePath,
      blurAmount: entity.blurAmount,
      overlayOpacity: entity.overlayOpacity,
    );
  }

  factory PlayerBackgroundConfigurationModel.fromJson(
    Map<String, dynamic> json,
  ) => _$PlayerBackgroundConfigurationModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PlayerBackgroundConfigurationModelToJson(this);
}
