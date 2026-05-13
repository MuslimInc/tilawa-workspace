/// Layout and styling constants for the Qibla feature.
///
/// These constants define sizing ratios, flex factors, and spacing values
/// used throughout the Qibla compass UI. All values are relative to
/// design tokens or screen dimensions to ensure responsive layouts.
library;

import 'package:flutter/material.dart';

// ===============================
// Compass Sizing Ratios
// ===============================

/// Compass widget size as a ratio of the available panel width.
const double kCompassSizeRatio = 0.78;

/// Dial size as a ratio of the available panel width.
const double kDialSizeRatio = 0.58;

/// Qibla pointer icon size in logical pixels.
const double kQiblaPointerIconSize = 72.0;

/// Center indicator size offset added to design token spacing.
const double kCenterIndicatorSizeOffset = 2.0;

/// Center indicator shadow spread radius.
const double kCenterIndicatorShadowSpread = 2.0;

// ===============================
// Compass Painter Constants
// ===============================

/// Tick inset offset added to design token spacing.
const double kTickInsetOffset = 1.0;

/// Border width multiplier for the compass dial border.
const int kBorderWidthMultiplier = 4;

/// Angle increment in degrees for compass dial ticks.
const int kTickAngleIncrement = 5;

/// Total degrees in a circle.
const int kFullCircleDegrees = 360;

/// Major tick interval in degrees (cardinal directions).
const int kMajorTickInterval = 90;

/// Minor tick interval in degrees.
const int kMinorTickInterval = 30;

/// Angle offset to align 0 degrees with top of circle.
const int kCompassAngleOffset = -90;

/// Thin tick stroke width.
const double kThinTickStrokeWidth = 1.0;

/// Thick tick stroke width.
const double kThickTickStrokeWidth = 2.0;

// ===============================
// Typography
// ===============================

/// Font size for the angle display value.
const double kAngleDisplayFontSize = 42.0;

/// Font weight for angle display.
const FontWeight kAngleDisplayFontWeight = FontWeight.w900;

/// Letter spacing for compass text labels.
const double kCompassTextLetterSpacing = 0.0;

// ===============================
// Layout & Spacing
// ===============================

/// Flex factor for the compass area in landscape mode.
const int kLandscapeCompassFlex = 3;

/// Flex factor for the text area in landscape mode.
const int kLandscapeTextFlex = 2;

/// Bottom padding for tip text in portrait mode (accounts for bottom player).
const double kPortraitTipBottomPadding = 120.0;

/// Default bottom padding for tip text.
const double kDefaultTipBottomPadding = 24.0;

/// Horizontal padding for tip text.
const double kTipHorizontalPadding = 32.0;

/// Vertical padding for tip text.
const double kTipVerticalPadding = 24.0;

/// Font size for tip text.
const double kTipFontSize = 16.0;

/// Font weight for tip text.
const FontWeight kTipFontWeight = FontWeight.w500;

/// Max Qibla panel width as a ratio of the form content max width token.
const double kQiblaPanelMaxWidthFactor = 0.72;

// ===============================
// Animation & Effects
// ===============================

/// Multiplier for blur shadow on the qibla pointer.
const double kQiblaPointerBlurMultiplier = 1.5;
