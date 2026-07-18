import '../../domain/entities/radio_station.dart';
import 'radio_station_dto.dart';

abstract final class RadioStationMapper {
  static RadioStation toEntity(
    RadioStationDto dto, {
    required bool isFavorite,
  }) {
    return RadioStation(
      id: dto.id.toString(),
      name: dto.name.trim(),
      streamUrl: dto.url.trim(),
      isFavorite: isFavorite,
    );
  }

  static RadioStationDto toDto(RadioStation station) {
    return RadioStationDto(
      id: int.tryParse(station.id) ?? 0,
      name: station.name,
      url: station.streamUrl,
    );
  }

  static RadioStation fromCachedJson(
    Map<String, dynamic> json, {
    required bool isFavorite,
  }) {
    return RadioStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      streamUrl: json['streamUrl'] as String? ?? json['url'] as String? ?? '',
      isFavorite: isFavorite,
    );
  }

  static Map<String, dynamic> toCachedJson(RadioStation station) {
    return <String, dynamic>{
      'id': station.id,
      'name': station.name,
      'streamUrl': station.streamUrl,
    };
  }
}
