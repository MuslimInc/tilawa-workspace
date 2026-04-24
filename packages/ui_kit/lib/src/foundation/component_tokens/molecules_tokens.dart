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
