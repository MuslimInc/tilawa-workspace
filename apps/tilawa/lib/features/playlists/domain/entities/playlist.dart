import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.coverImageUrl,
    this.isPublic = false,
    this.isFavorite = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => PlaylistItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      coverImageUrl: json['coverImageUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlaylistItem> items;
  final String? coverImageUrl;
  final bool isPublic;
  final bool isFavorite;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
    items,
    coverImageUrl,
    isPublic,
    isFavorite,
  ];

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlaylistItem>? items,
    String? coverImageUrl,
    bool? isPublic,
    bool? isFavorite,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'coverImageUrl': coverImageUrl,
      'isPublic': isPublic,
      'isFavorite': isFavorite,
    };
  }

  /// Get total duration of all items in the playlist
  Duration get totalDuration {
    return items.fold(Duration.zero, (total, item) => total + item.duration);
  }

  /// Get total number of items in the playlist
  int get itemCount => items.length;

  /// Check if playlist is empty
  bool get isEmpty => items.isEmpty;

  /// Check if playlist has items
  bool get isNotEmpty => items.isNotEmpty;
}

class PlaylistItem extends Equatable {
  const PlaylistItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    required this.duration,
    required this.addedAt,
    this.artUri,
    this.album,
    this.genre,
    this.filePath,
    this.isDownloaded = false,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      url: json['url'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      addedAt: DateTime.parse(json['addedAt'] as String),
      artUri: json['artUri'] != null
          ? Uri.parse(json['artUri'] as String)
          : null,
      album: json['album'] as String?,
      genre: json['genre'] as String?,
      filePath: json['filePath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String artist;
  final String url;
  final Duration duration;
  final DateTime addedAt;
  final Uri? artUri;
  final String? album;
  final String? genre;
  final String? filePath;
  final bool isDownloaded;

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    url,
    duration,
    addedAt,
    artUri,
    album,
    genre,
    filePath,
    isDownloaded,
  ];

  PlaylistItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? url,
    Duration? duration,
    DateTime? addedAt,
    Uri? artUri,
    String? album,
    String? genre,
    String? filePath,
    bool? isDownloaded,
  }) {
    return PlaylistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      addedAt: addedAt ?? this.addedAt,
      artUri: artUri ?? this.artUri,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'url': url,
      'duration': duration.inMilliseconds,
      'addedAt': addedAt.toIso8601String(),
      'artUri': artUri?.toString(),
      'album': album,
      'genre': genre,
      'filePath': filePath,
      'isDownloaded': isDownloaded,
    };
  }
}
