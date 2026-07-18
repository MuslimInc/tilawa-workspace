import 'package:json_annotation/json_annotation.dart';

part 'reel_video_dto.g.dart';

@JsonSerializable()
class ReelVideoDto {
  const ReelVideoDto({
    required this.id,
    required this.videoType,
    required this.videoUrl,
    required this.videoThumbUrl,
  });

  final int id;

  @JsonKey(name: 'video_type')
  final int videoType;

  @JsonKey(name: 'video_url')
  final String videoUrl;

  @JsonKey(name: 'video_thumb_url')
  final String videoThumbUrl;

  factory ReelVideoDto.fromJson(Map<String, dynamic> json) =>
      _$ReelVideoDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReelVideoDtoToJson(this);
}

@JsonSerializable()
class ReelSheikhDto {
  const ReelSheikhDto({
    required this.id,
    required this.reciterName,
    required this.videos,
  });

  final int id;

  @JsonKey(name: 'reciter_name')
  final String reciterName;

  final List<ReelVideoDto> videos;

  factory ReelSheikhDto.fromJson(Map<String, dynamic> json) =>
      _$ReelSheikhDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReelSheikhDtoToJson(this);
}

@JsonSerializable()
class ReelVideoTypeDto {
  const ReelVideoTypeDto({
    required this.id,
    required this.videoType,
  });

  final int id;

  @JsonKey(name: 'video_type')
  final String videoType;

  factory ReelVideoTypeDto.fromJson(Map<String, dynamic> json) =>
      _$ReelVideoTypeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReelVideoTypeDtoToJson(this);
}
