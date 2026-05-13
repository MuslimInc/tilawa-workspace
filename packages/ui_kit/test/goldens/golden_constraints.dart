import 'package:flutter/material.dart';

/// Constraints applied to every [GoldenTestScenario] in ui_kit goldens.
///
/// Alchemist lays scenarios in a [Table] with [IntrinsicColumnWidth], which
/// queries intrinsic dimensions. Some widgets (for example those using
/// [LayoutBuilder]) cannot report intrinsics under unbounded constraints; a
/// bounded max width and height avoids that failure on recent Flutter versions.
const BoxConstraints kUiKitGoldenScenarioConstraints = BoxConstraints(
  minWidth: 160,
  maxWidth: 800,
  minHeight: 48,
  maxHeight: 1200,
);
