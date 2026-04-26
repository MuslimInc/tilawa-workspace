import 'package:flutter/material.dart';

import 'token_lerp.dart';

@immutable
class TilawaFeedbackStripTokens {
  const TilawaFeedbackStripTokens({
    required this.padding,
    required this.borderRadius,
    required this.spinnerSize,
    required this.spinnerStrokeWidth,
    required this.contentGap,
  });

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double spinnerSize;
  final double spinnerStrokeWidth;
  final double contentGap;

  factory TilawaFeedbackStripTokens.defaults() =>
      const TilawaFeedbackStripTokens(
        padding: EdgeInsets.all(14),
        borderRadius: 18,
        spinnerSize: 18,
        spinnerStrokeWidth: 2.2,
        contentGap: 10,
      );

  TilawaFeedbackStripTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    double? spinnerSize,
    double? spinnerStrokeWidth,
    double? contentGap,
  }) {
    return TilawaFeedbackStripTokens(
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      spinnerSize: spinnerSize ?? this.spinnerSize,
      spinnerStrokeWidth: spinnerStrokeWidth ?? this.spinnerStrokeWidth,
      contentGap: contentGap ?? this.contentGap,
    );
  }

  static TilawaFeedbackStripTokens lerp(
    TilawaFeedbackStripTokens a,
    TilawaFeedbackStripTokens b,
    double t,
  ) {
    return TilawaFeedbackStripTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      spinnerSize: lerpTokenDouble(a.spinnerSize, b.spinnerSize, t),
      spinnerStrokeWidth: lerpTokenDouble(
        a.spinnerStrokeWidth,
        b.spinnerStrokeWidth,
        t,
      ),
      contentGap: lerpTokenDouble(a.contentGap, b.contentGap, t),
    );
  }
}

@immutable
class TilawaGlassPanelTokens {
  const TilawaGlassPanelTokens({
    required this.padding,
    required this.borderRadiusOffset,
    required this.backgroundOpacity,
  });

  final EdgeInsetsGeometry padding;
  final double borderRadiusOffset;
  final double backgroundOpacity;

  factory TilawaGlassPanelTokens.defaults() => const TilawaGlassPanelTokens(
    padding: EdgeInsets.all(16),
    borderRadiusOffset: 8,
    backgroundOpacity: 0.8,
  );

  TilawaGlassPanelTokens copyWith({
    EdgeInsetsGeometry? padding,
    double? borderRadiusOffset,
    double? backgroundOpacity,
  }) {
    return TilawaGlassPanelTokens(
      padding: padding ?? this.padding,
      borderRadiusOffset: borderRadiusOffset ?? this.borderRadiusOffset,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }

  static TilawaGlassPanelTokens lerp(
    TilawaGlassPanelTokens a,
    TilawaGlassPanelTokens b,
    double t,
  ) {
    return TilawaGlassPanelTokens(
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
      borderRadiusOffset: lerpTokenDouble(
        a.borderRadiusOffset,
        b.borderRadiusOffset,
        t,
      ),
      backgroundOpacity: lerpTokenDouble(
        a.backgroundOpacity,
        b.backgroundOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaIconActionButtonTokens {
  const TilawaIconActionButtonTokens({
    required this.size,
    required this.borderRadius,
    required this.activeBackgroundOpacity,
    required this.activeBorderOpacity,
    required this.inactiveBorderOpacity,
  });

  final double size;
  final double borderRadius;
  final double activeBackgroundOpacity;
  final double activeBorderOpacity;
  final double inactiveBorderOpacity;

  factory TilawaIconActionButtonTokens.defaults() =>
      const TilawaIconActionButtonTokens(
        size: kMinInteractiveDimension,
        borderRadius: 16,
        activeBackgroundOpacity: 0.12,
        activeBorderOpacity: 0.35,
        inactiveBorderOpacity: 0.26,
      );

  TilawaIconActionButtonTokens copyWith({
    double? size,
    double? borderRadius,
    double? activeBackgroundOpacity,
    double? activeBorderOpacity,
    double? inactiveBorderOpacity,
  }) {
    return TilawaIconActionButtonTokens(
      size: size ?? this.size,
      borderRadius: borderRadius ?? this.borderRadius,
      activeBackgroundOpacity:
          activeBackgroundOpacity ?? this.activeBackgroundOpacity,
      activeBorderOpacity: activeBorderOpacity ?? this.activeBorderOpacity,
      inactiveBorderOpacity:
          inactiveBorderOpacity ?? this.inactiveBorderOpacity,
    );
  }

  static TilawaIconActionButtonTokens lerp(
    TilawaIconActionButtonTokens a,
    TilawaIconActionButtonTokens b,
    double t,
  ) {
    return TilawaIconActionButtonTokens(
      size: lerpTokenDouble(a.size, b.size, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      activeBackgroundOpacity: lerpTokenDouble(
        a.activeBackgroundOpacity,
        b.activeBackgroundOpacity,
        t,
      ),
      activeBorderOpacity: lerpTokenDouble(
        a.activeBorderOpacity,
        b.activeBorderOpacity,
        t,
      ),
      inactiveBorderOpacity: lerpTokenDouble(
        a.inactiveBorderOpacity,
        b.inactiveBorderOpacity,
        t,
      ),
    );
  }
}

@immutable
class TilawaSearchFieldTokens {
  const TilawaSearchFieldTokens({
    required this.height,
    required this.borderRadius,
    required this.contentPadding,
    required this.iconSize,
    required this.focusedBorderOpacity,
    required this.unfocusedBorderOpacity,
    required this.shadowOpacity,
    required this.hintOpacity,
    required this.iconOpacity,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final double iconSize;
  final double focusedBorderOpacity;
  final double unfocusedBorderOpacity;
  final double shadowOpacity;
  final double hintOpacity;
  final double iconOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  factory TilawaSearchFieldTokens.defaults() => const TilawaSearchFieldTokens(
    height: kMinInteractiveDimension,
    borderRadius: 16,
    contentPadding: EdgeInsets.symmetric(vertical: 12),
    iconSize: 18,
    focusedBorderOpacity: 0.28,
    unfocusedBorderOpacity: 0.26,
    shadowOpacity: 0.04,
    hintOpacity: 0.58,
    iconOpacity: 0.72,
    shadowBlur: 12,
    shadowOffset: Offset(0, 4),
  );

  TilawaSearchFieldTokens copyWith({
    double? height,
    double? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    double? iconSize,
    double? focusedBorderOpacity,
    double? unfocusedBorderOpacity,
    double? shadowOpacity,
    double? hintOpacity,
    double? iconOpacity,
    double? shadowBlur,
    Offset? shadowOffset,
  }) {
    return TilawaSearchFieldTokens(
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      iconSize: iconSize ?? this.iconSize,
      focusedBorderOpacity: focusedBorderOpacity ?? this.focusedBorderOpacity,
      unfocusedBorderOpacity:
          unfocusedBorderOpacity ?? this.unfocusedBorderOpacity,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      hintOpacity: hintOpacity ?? this.hintOpacity,
      iconOpacity: iconOpacity ?? this.iconOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }

  static TilawaSearchFieldTokens lerp(
    TilawaSearchFieldTokens a,
    TilawaSearchFieldTokens b,
    double t,
  ) {
    return TilawaSearchFieldTokens(
      height: lerpTokenDouble(a.height, b.height, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      contentPadding: EdgeInsetsGeometry.lerp(
        a.contentPadding,
        b.contentPadding,
        t,
      )!,
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      focusedBorderOpacity: lerpTokenDouble(
        a.focusedBorderOpacity,
        b.focusedBorderOpacity,
        t,
      ),
      unfocusedBorderOpacity: lerpTokenDouble(
        a.unfocusedBorderOpacity,
        b.unfocusedBorderOpacity,
        t,
      ),
      shadowOpacity: lerpTokenDouble(a.shadowOpacity, b.shadowOpacity, t),
      hintOpacity: lerpTokenDouble(a.hintOpacity, b.hintOpacity, t),
      iconOpacity: lerpTokenDouble(a.iconOpacity, b.iconOpacity, t),
      shadowBlur: lerpTokenDouble(a.shadowBlur, b.shadowBlur, t),
      shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
    );
  }
}

@immutable
class TilawaCountProgressRingTokens {
  const TilawaCountProgressRingTokens({
    required this.outerSize,
    required this.innerSize,
    required this.ringStrokeWidth,
    required this.doneIconSize,
    required this.countFontSize,
    required this.doneBorderWidth,
    required this.doneBorderOpacity,
    required this.activeGradientEndOpacity,
    required this.doneGradientEndOpacity,
    required this.progressLabelSpacing,
    required this.progressLabelPadding,
    required this.progressLabelBorderRadius,
    required this.progressLabelBackgroundOpacity,
  });

  final double outerSize;
  final double innerSize;
  final double ringStrokeWidth;
  final double doneIconSize;
  final double countFontSize;
  final double doneBorderWidth;
  final double doneBorderOpacity;
  final double activeGradientEndOpacity;
  final double doneGradientEndOpacity;
  final double progressLabelSpacing;
  final EdgeInsetsGeometry progressLabelPadding;
  final double progressLabelBorderRadius;
  final double progressLabelBackgroundOpacity;

  factory TilawaCountProgressRingTokens.defaults() =>
      const TilawaCountProgressRingTokens(
        outerSize: 72,
        innerSize: 62,
        ringStrokeWidth: 10,
        doneIconSize: 50,
        countFontSize: 36,
        doneBorderWidth: 2,
        doneBorderOpacity: 0.3,
        activeGradientEndOpacity: 0.8,
        doneGradientEndOpacity: 0.7,
        progressLabelSpacing: 16,
        progressLabelPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        progressLabelBorderRadius: 24,
        progressLabelBackgroundOpacity: 0.3,
      );

  TilawaCountProgressRingTokens copyWith({
    double? outerSize,
    double? innerSize,
    double? ringStrokeWidth,
    double? doneIconSize,
    double? countFontSize,
    double? doneBorderWidth,
    double? doneBorderOpacity,
    double? activeGradientEndOpacity,
    double? doneGradientEndOpacity,
    double? progressLabelSpacing,
    EdgeInsetsGeometry? progressLabelPadding,
    double? progressLabelBorderRadius,
    double? progressLabelBackgroundOpacity,
  }) {
    return TilawaCountProgressRingTokens(
      outerSize: outerSize ?? this.outerSize,
      innerSize: innerSize ?? this.innerSize,
      ringStrokeWidth: ringStrokeWidth ?? this.ringStrokeWidth,
      doneIconSize: doneIconSize ?? this.doneIconSize,
      countFontSize: countFontSize ?? this.countFontSize,
      doneBorderWidth: doneBorderWidth ?? this.doneBorderWidth,
      doneBorderOpacity: doneBorderOpacity ?? this.doneBorderOpacity,
      activeGradientEndOpacity:
          activeGradientEndOpacity ?? this.activeGradientEndOpacity,
      doneGradientEndOpacity:
          doneGradientEndOpacity ?? this.doneGradientEndOpacity,
      progressLabelSpacing: progressLabelSpacing ?? this.progressLabelSpacing,
      progressLabelPadding: progressLabelPadding ?? this.progressLabelPadding,
      progressLabelBorderRadius:
          progressLabelBorderRadius ?? this.progressLabelBorderRadius,
      progressLabelBackgroundOpacity:
          progressLabelBackgroundOpacity ?? this.progressLabelBackgroundOpacity,
    );
  }

  static TilawaCountProgressRingTokens lerp(
    TilawaCountProgressRingTokens a,
    TilawaCountProgressRingTokens b,
    double t,
  ) {
    return TilawaCountProgressRingTokens(
      outerSize: lerpTokenDouble(a.outerSize, b.outerSize, t),
      innerSize: lerpTokenDouble(a.innerSize, b.innerSize, t),
      ringStrokeWidth: lerpTokenDouble(a.ringStrokeWidth, b.ringStrokeWidth, t),
      doneIconSize: lerpTokenDouble(a.doneIconSize, b.doneIconSize, t),
      countFontSize: lerpTokenDouble(a.countFontSize, b.countFontSize, t),
      doneBorderWidth: lerpTokenDouble(a.doneBorderWidth, b.doneBorderWidth, t),
      doneBorderOpacity: lerpTokenDouble(
        a.doneBorderOpacity,
        b.doneBorderOpacity,
        t,
      ),
      activeGradientEndOpacity: lerpTokenDouble(
        a.activeGradientEndOpacity,
        b.activeGradientEndOpacity,
        t,
      ),
      doneGradientEndOpacity: lerpTokenDouble(
        a.doneGradientEndOpacity,
        b.doneGradientEndOpacity,
        t,
      ),
      progressLabelSpacing: lerpTokenDouble(
        a.progressLabelSpacing,
        b.progressLabelSpacing,
        t,
      ),
      progressLabelPadding: EdgeInsetsGeometry.lerp(
        a.progressLabelPadding,
        b.progressLabelPadding,
        t,
      )!,
      progressLabelBorderRadius: lerpTokenDouble(
        a.progressLabelBorderRadius,
        b.progressLabelBorderRadius,
        t,
      ),
      progressLabelBackgroundOpacity: lerpTokenDouble(
        a.progressLabelBackgroundOpacity,
        b.progressLabelBackgroundOpacity,
        t,
      ),
    );
  }
}
