import 'package:equatable/equatable.dart';

import 'reel_reaction.dart';

/// Domain reel — flattened from mp3quran sheikh/video payload.
final class Reel extends Equatable {
  const Reel({
    required this.id,
    required this.sheikhId,
    required this.sheikhName,
    required this.videoUrl,
    required this.thumbUrl,
    required this.categoryId,
    this.duration,
    this.reaction,
    this.isSaved = false,
  });

  final int id;
  final int sheikhId;
  final String sheikhName;
  final String videoUrl;
  final String thumbUrl;

  /// API `video_type` id (2 / 3 / 4).
  final int categoryId;

  /// Known after player init; null until then.
  final Duration? duration;

  final ReelReaction? reaction;
  final bool isSaved;

  Reel copyWith({
    int? id,
    int? sheikhId,
    String? sheikhName,
    String? videoUrl,
    String? thumbUrl,
    int? categoryId,
    Duration? duration,
    ReelReaction? reaction,
    bool clearReaction = false,
    bool? isSaved,
  }) {
    return Reel(
      id: id ?? this.id,
      sheikhId: sheikhId ?? this.sheikhId,
      sheikhName: sheikhName ?? this.sheikhName,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      categoryId: categoryId ?? this.categoryId,
      duration: duration ?? this.duration,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sheikhId': sheikhId,
    'sheikhName': sheikhName,
    'videoUrl': videoUrl,
    'thumbUrl': thumbUrl,
    'categoryId': categoryId,
    'durationMs': duration?.inMilliseconds,
    'reaction': reaction?.name,
    'isSaved': isSaved,
  };

  factory Reel.fromJson(Map<String, dynamic> json) {
    final String? reactionName = json['reaction'] as String?;
    return Reel(
      id: json['id'] as int,
      sheikhId: json['sheikhId'] as int,
      sheikhName: json['sheikhName'] as String,
      videoUrl: json['videoUrl'] as String,
      thumbUrl: json['thumbUrl'] as String,
      categoryId: json['categoryId'] as int,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      reaction: reactionName == null
          ? null
          : ReelReaction.values.firstWhere(
              (r) => r.name == reactionName,
              orElse: () => ReelReaction.loved,
            ),
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sheikhId,
    sheikhName,
    videoUrl,
    thumbUrl,
    categoryId,
    duration,
    reaction,
    isSaved,
  ];
}
