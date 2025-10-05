import 'package:equatable/equatable.dart';

class AudioEntity extends Equatable {
  const AudioEntity({
    required this.id,
    required this.title,
    required this.url,
    required this.duration,
    this.artist,
    this.album,
    this.artUri,
  });

  final String id;
  final String title;
  final String url;
  final Duration duration;
  final String? artist;
  final String? album;
  final String? artUri;

  @override
  List<Object?> get props => [id, title, url, duration, artist, album, artUri];
}

class PlaybackStateEntity extends Equatable {
  const PlaybackStateEntity({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.currentIndex,
    required this.queue,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final int currentIndex;
  final List<AudioEntity> queue;

  @override
  List<Object?> get props => [
    isPlaying,
    position,
    duration,
    currentIndex,
    queue,
  ];
}
