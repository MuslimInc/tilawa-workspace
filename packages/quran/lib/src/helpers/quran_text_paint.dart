import 'package:flutter/material.dart';

const double _defaultQuranShadowOffset = 0.25;

List<Shadow> buildQuranBoldShadows(
  Color color, {
  double offset = _defaultQuranShadowOffset,
}) {
  return <Shadow>[
    Shadow(
      color: color.withValues(alpha: 0.6),
      offset: Offset(offset * 0.5, offset * 0.5),
    ),
  ];
}
