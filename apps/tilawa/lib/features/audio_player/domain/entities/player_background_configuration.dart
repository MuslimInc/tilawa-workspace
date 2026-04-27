import 'package:equatable/equatable.dart';

enum PlayerBackgroundType { defaultType, custom }

class PlayerBackgroundConfiguration extends Equatable {
  const PlayerBackgroundConfiguration({
    this.type = PlayerBackgroundType.defaultType,
    this.customImagePath,
    this.blurAmount = 0.0,
    this.overlayOpacity = 0.4,
  });

  final PlayerBackgroundType type;
  final String? customImagePath;
  final double blurAmount;
  final double overlayOpacity;

  PlayerBackgroundConfiguration copyWith({
    PlayerBackgroundType? type,
    String? customImagePath,
    double? blurAmount,
    double? overlayOpacity,
  }) {
    return PlayerBackgroundConfiguration(
      type: type ?? this.type,
      customImagePath: customImagePath ?? this.customImagePath,
      blurAmount: blurAmount ?? this.blurAmount,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
    );
  }

  @override
  List<Object?> get props => [
    type,
    customImagePath,
    blurAmount,
    overlayOpacity,
  ];
}
