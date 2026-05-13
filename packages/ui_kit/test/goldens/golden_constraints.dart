import 'package:flutter/material.dart';

/// Constraints applied to every [GoldenTestScenario] in ui_kit goldens.
///
/// Alchemist lays scenarios in a [Table] with [IntrinsicColumnWidth], which
/// queries intrinsic dimensions. Some widgets (for example those using
/// [LayoutBuilder]) cannot report intrinsics under unbounded constraints; a
/// bounded max width and height avoids that failure on recent Flutter versions.
///
/// **Horizontal:** [minWidth] and [maxWidth] are both `800` so each scenario
/// cell has a stable snapshot width across machines (avoids golden size drift
/// when intrinsics differ slightly between Flutter / font versions).
const BoxConstraints kUiKitGoldenScenarioConstraints = BoxConstraints(
  minWidth: 800,
  maxWidth: 800,
  minHeight: 48,
  maxHeight: 1200,
);
