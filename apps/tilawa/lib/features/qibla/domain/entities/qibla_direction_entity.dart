import 'package:equatable/equatable.dart';

import '../qibla_heading_math.dart';

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

  /// Geographic bearing to the Qibla from north (0–360), fixed for location.
  final double offset;

  /// Estimated compass heading error in degrees, when the platform provides it.
  final double? accuracy;

  /// Returns true when the device heading is within 2° of the Qibla bearing.
  bool get isAligned => isHeadingAlignedWithBearing(
    bearing: offset,
    heading: direction,
  );

  bool get hasPoorCompassAccuracy =>
      accuracy != null && accuracy! >= _poorAccuracyThreshold;

  @override
  List<Object?> get props => [qibla, direction, offset, accuracy];
}
