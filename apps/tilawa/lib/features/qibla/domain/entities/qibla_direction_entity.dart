import 'package:equatable/equatable.dart';

class QiblaDirectionEntity extends Equatable {
  const QiblaDirectionEntity({
    required this.qibla,
    required this.direction,
    required this.offset,
    this.accuracy,
  });

  static const double _poorAccuracyThreshold = 45;

  /// The angle in degrees towards the Qibla from North (0-360)
  final double qibla;

  /// The current heading of the device (0-360)
  final double direction;

  /// The difference between the device direction and the Qibla (used for rotation)
  final double offset;

  /// Estimated compass heading error in degrees, when the platform provides it.
  final double? accuracy;

  /// Returns true if the device direction is within 2 degrees of the Qibla
  bool get isAligned {
    final double diff = (direction - offset).abs();
    return diff < 2 || diff > 358;
  }

  bool get hasPoorCompassAccuracy =>
      accuracy != null && accuracy! >= _poorAccuracyThreshold;

  @override
  List<Object?> get props => [qibla, direction, offset, accuracy];
}
