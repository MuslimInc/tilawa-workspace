/// Heading math for Qibla compass UI.
library;

/// Signed shortest rotation from [heading] to [bearing], in degrees (-180, 180].
double shortestHeadingDelta({
  required double bearing,
  required double heading,
}) {
  double delta = (bearing - heading) % 360;
  if (delta <= -180) {
    delta += 360;
  } else if (delta > 180) {
    delta -= 360;
  }
  return delta;
}

/// Remaining degrees to face [bearing] from current [heading].
double degreesToQiblaBearing({
  required double bearing,
  required double heading,
}) {
  return shortestHeadingDelta(bearing: bearing, heading: heading).abs();
}

/// Whether [heading] is within [tolerance] degrees of [bearing].
bool isHeadingAlignedWithBearing({
  required double bearing,
  required double heading,
  double tolerance = 2,
}) {
  return degreesToQiblaBearing(bearing: bearing, heading: heading) < tolerance;
}
