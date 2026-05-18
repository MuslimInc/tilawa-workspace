import 'package:flutter/material.dart';

/// Fixed-width scenario constraints so atom/molecule cells render at a stable
/// width across machines (avoids golden drift due to intrinsic resolution).
const BoxConstraints kV2AtomConstraints = BoxConstraints(
  minWidth: 360,
  maxWidth: 360,
  minHeight: 48,
  maxHeight: 240,
);

const BoxConstraints kV2RowConstraints = BoxConstraints(
  minWidth: 360,
  maxWidth: 360,
  minHeight: 48,
  maxHeight: 320,
);

const BoxConstraints kV2OrganismConstraints = BoxConstraints(
  minWidth: 360,
  maxWidth: 360,
  minHeight: 80,
  maxHeight: 720,
);

const BoxConstraints kV2ScreenConstraints = BoxConstraints(
  minWidth: 360,
  maxWidth: 360,
  minHeight: 640,
  maxHeight: 800,
);
