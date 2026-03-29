import 'package:flutter/material.dart';

const double _defaultQuranShadowOffset = 0.25;

List<Shadow> buildQuranBoldShadows(
  Color color, {
  double offset = _defaultQuranShadowOffset,
}) {
  return <Shadow>[
    Shadow(color: color, offset: Offset(offset, 0)),
    Shadow(color: color, offset: Offset(-offset, 0)),
    Shadow(color: color, offset: Offset(0, offset * 0.7)),
    Shadow(color: color, offset: Offset(0, -offset * 0.7)),
  ];
}
