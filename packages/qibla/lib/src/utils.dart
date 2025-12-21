import 'dart:math' show atan2, cos, sin, tan;

import 'package:vector_math/vector_math.dart' show degrees, radians;

class Utils {
  Utils._();

  static final double _deLa = radians(21.422487);
  static final double _deLo = radians(39.826206);

  static double getOffsetFromNorth(
    double currentLatitude,
    double currentLongitude,
  ) {
    final double laRad = radians(currentLatitude);
    final double loRad = radians(currentLongitude);

    final double y = sin(_deLo - loRad);
    final double x = cos(laRad) * tan(_deLa) - sin(laRad) * cos(_deLo - loRad);

    return (degrees(atan2(y, x)) + 360) % 360;
  }
}
