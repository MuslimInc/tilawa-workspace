import 'package:equatable/equatable.dart';

class QiblaDirectionEntity extends Equatable {
  const QiblaDirectionEntity({
    required this.qibla,
    required this.direction,
    required this.offset,
  });

  /// The angle in degrees towards the Qibla from North (0-360)
  final double qibla;

  /// The current heading of the device (0-360)
  final double direction;

  /// The difference between the device direction and the Qibla (used for rotation)
  final double offset;

  @override
  List<Object?> get props => [qibla, direction, offset];
}
