import 'dart:ui';

import 'package:flutter/material.dart';

/// Helper extension to calculate safe insets that avoid display features
/// (hinges/folds) on foldable devices.
extension DisplayFeatureInsets on BuildContext {
  /// Returns the padding needed to avoid vertical display features (hinges)
  /// in the given [axisDirection].
  EdgeInsetsDirectional getHingeAvoidancePadding(AxisDirection axisDirection) {
    final displayFeatures = MediaQuery.displayFeaturesOf(this);
    if (displayFeatures.isEmpty) {
      return EdgeInsetsDirectional.zero;
    }

    final size = MediaQuery.sizeOf(this);

    double startPadding = 0.0;
    double endPadding = 0.0;

    for (final feature in displayFeatures) {
      if (feature.type == DisplayFeatureType.hinge ||
          feature.type == DisplayFeatureType.fold) {
        final bounds = feature.bounds;

        if (bounds.left <= 0) {
          startPadding = bounds.width;
        } else if (bounds.right >= size.width) {
          endPadding = bounds.width;
        }
      }
    }

    return EdgeInsetsDirectional.fromSTEB(startPadding, 0, endPadding, 0);
  }
}
