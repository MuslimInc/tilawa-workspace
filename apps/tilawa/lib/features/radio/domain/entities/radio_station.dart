import 'package:equatable/equatable.dart';

/// Live Islamic radio station from MP3Quran.
class RadioStation extends Equatable {
  const RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String streamUrl;
  final bool isFavorite;

  /// Prefixed id used when mapping to [AudioEntity] for playback.
  String get audioId => 'radio:$id';

  RadioStation copyWith({
    String? id,
    String? name,
    String? streamUrl,
    bool? isFavorite,
  }) {
    return RadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [id, name, streamUrl, isFavorite];
}
