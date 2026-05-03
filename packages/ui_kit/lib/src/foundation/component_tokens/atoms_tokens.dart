import 'package:flutter/material.dart';

import '../density.dart';
import 'token_lerp.dart';

@immutable
class TilawaSectionTitleTokens {
  const TilawaSectionTitleTokens({required this.fontWeight});

  final FontWeight fontWeight;

  factory TilawaSectionTitleTokens.defaults() =>
      const TilawaSectionTitleTokens(fontWeight: .w800);

  TilawaSectionTitleTokens copyWith({FontWeight? fontWeight}) {
    return TilawaSectionTitleTokens(fontWeight: fontWeight ?? this.fontWeight);
  }

  static TilawaSectionTitleTokens lerp(
    TilawaSectionTitleTokens a,
    TilawaSectionTitleTokens b,
    double t,
  ) {
    return TilawaSectionTitleTokens(
      fontWeight: FontWeight.lerp(a.fontWeight, b.fontWeight, t)!,
    );
  }
}

@immutable
class TilawaSheetHandleTokens {
  const TilawaSheetHandleTokens({
    required this.width,
    required this.height,
    required this.marginBottom,
    required this.cornerRadius,
    required this.colorOpacity,
  });

  final double width;
  final double height;
  final double marginBottom;
  final double cornerRadius;
  final double colorOpacity;

  factory TilawaSheetHandleTokens.defaults() => const TilawaSheetHandleTokens(
    width: 46,
    height: 5,
    marginBottom: 16,
    cornerRadius: 999,
    colorOpacity: 0.22,
  );

  TilawaSheetHandleTokens copyWith({
    double? width,
    double? height,
    double? marginBottom,
    double? cornerRadius,
    double? colorOpacity,
  }) {
    return TilawaSheetHandleTokens(
      width: width ?? this.width,
      height: height ?? this.height,
      marginBottom: marginBottom ?? this.marginBottom,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      colorOpacity: colorOpacity ?? this.colorOpacity,
    );
  }

  static TilawaSheetHandleTokens lerp(
    TilawaSheetHandleTokens a,
    TilawaSheetHandleTokens b,
    double t,
  ) {
    return TilawaSheetHandleTokens(
      width: lerpTokenDouble(a.width, b.width, t),
      height: lerpTokenDouble(a.height, b.height, t),
      marginBottom: lerpTokenDouble(a.marginBottom, b.marginBottom, t),
      cornerRadius: lerpTokenDouble(a.cornerRadius, b.cornerRadius, t),
      colorOpacity: lerpTokenDouble(a.colorOpacity, b.colorOpacity, t),
    );
  }
}

/// Component tokens for [TilawaCard].
///
/// Defaults match the existing behavior where the card reads
/// `radiusLarge`, `borderWidthThin`, and `spaceMedium` from
/// [TilawaDesignTokens].
@immutable
class TilawaCardTokens {
  const TilawaCardTokens({
    required this.borderRadius,
    required this.borderWidth,
    required this.padding,
  });

  /// Corner radius of the card.
  final double borderRadius;

  /// Border width of the card outline.
  final double borderWidth;

  /// Default inner padding.
  final EdgeInsets padding;

  factory TilawaCardTokens.defaults() => const TilawaCardTokens(
    borderRadius: 16.0,
    borderWidth: 0.5,
    padding: EdgeInsets.all(12.0),
  );

  TilawaCardTokens copyWith({
    double? borderRadius,
    double? borderWidth,
    EdgeInsets? padding,
  }) {
    return TilawaCardTokens(
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
    );
  }

  static TilawaCardTokens lerp(
    TilawaCardTokens a,
    TilawaCardTokens b,
    double t,
  ) {
    return TilawaCardTokens(
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
      borderWidth: lerpTokenDouble(a.borderWidth, b.borderWidth, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
    );
  }
}

/// Component tokens for [TilawaIconBox].
///
/// Defaults match the existing behavior where the icon box reads
/// `iconSizeLarge`, `spaceSmall`, and `radiusMedium` from
/// [TilawaDesignTokens].
@immutable
class TilawaIconBoxTokens {
  const TilawaIconBoxTokens({
    required this.iconSize,
    required this.padding,
    required this.borderRadius,
  });

  /// Default icon size inside the box.
  final double iconSize;

  /// Inner padding around the icon.
  final double padding;

  /// Corner radius of the container.
  final double borderRadius;

  factory TilawaIconBoxTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density == TilawaDensity.compact) {
      return const TilawaIconBoxTokens(
        iconSize: 20.0,
        padding: 6.0,
        borderRadius: 10.0,
      );
    }
    return const TilawaIconBoxTokens(
      iconSize: 24.0,
      padding: 8.0,
      borderRadius: 12.0,
    );
  }

  TilawaIconBoxTokens copyWith({
    double? iconSize,
    double? padding,
    double? borderRadius,
  }) {
    return TilawaIconBoxTokens(
      iconSize: iconSize ?? this.iconSize,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  static TilawaIconBoxTokens lerp(
    TilawaIconBoxTokens a,
    TilawaIconBoxTokens b,
    double t,
  ) {
    return TilawaIconBoxTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      padding: lerpTokenDouble(a.padding, b.padding, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
    );
  }
}

/// Component tokens for [TilawaLoadingIndicator].
@immutable
class TilawaLoadingIndicatorTokens {
  const TilawaLoadingIndicatorTokens({
    required this.defaultStrokeWidth,
    required this.compactStrokeWidth,
  });

  /// Default stroke width for the circular progress indicator.
  final double defaultStrokeWidth;

  /// Compact stroke width used in smaller contexts.
  final double compactStrokeWidth;

  factory TilawaLoadingIndicatorTokens.defaults() =>
      const TilawaLoadingIndicatorTokens(
        defaultStrokeWidth: 4.0,
        compactStrokeWidth: 2.0,
      );

  TilawaLoadingIndicatorTokens copyWith({
    double? defaultStrokeWidth,
    double? compactStrokeWidth,
  }) {
    return TilawaLoadingIndicatorTokens(
      defaultStrokeWidth: defaultStrokeWidth ?? this.defaultStrokeWidth,
      compactStrokeWidth: compactStrokeWidth ?? this.compactStrokeWidth,
    );
  }

  static TilawaLoadingIndicatorTokens lerp(
    TilawaLoadingIndicatorTokens a,
    TilawaLoadingIndicatorTokens b,
    double t,
  ) {
    return TilawaLoadingIndicatorTokens(
      defaultStrokeWidth: lerpTokenDouble(
        a.defaultStrokeWidth,
        b.defaultStrokeWidth,
        t,
      ),
      compactStrokeWidth: lerpTokenDouble(
        a.compactStrokeWidth,
        b.compactStrokeWidth,
        t,
      ),
    );
  }
}

/// Component tokens for [TilawaIconToggle].
@immutable
class TilawaIconToggleTokens {
  const TilawaIconToggleTokens({
    required this.iconSize,
    required this.padding,
    required this.borderRadius,
  });

  final double iconSize;
  final double padding;
  final double borderRadius;

  factory TilawaIconToggleTokens.defaults() => const TilawaIconToggleTokens(
    iconSize: 20.0,
    padding: 8.0,
    borderRadius: 12.0,
  );

  TilawaIconToggleTokens copyWith({
    double? iconSize,
    double? padding,
    double? borderRadius,
  }) {
    return TilawaIconToggleTokens(
      iconSize: iconSize ?? this.iconSize,
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  static TilawaIconToggleTokens lerp(
    TilawaIconToggleTokens a,
    TilawaIconToggleTokens b,
    double t,
  ) {
    return TilawaIconToggleTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      padding: lerpTokenDouble(a.padding, b.padding, t),
      borderRadius: lerpTokenDouble(a.borderRadius, b.borderRadius, t),
    );
  }
}

/// Component tokens for [TilawaDivider].
@immutable
class TilawaDividerTokens {
  const TilawaDividerTokens({
    required this.height,
    required this.thickness,
    required this.colorOpacity,
  });

  /// Default divider height (includes spacing above and below).
  final double height;

  /// Line thickness.
  final double thickness;

  /// Opacity applied to the default divider color.
  final double colorOpacity;

  factory TilawaDividerTokens.defaults() =>
      const TilawaDividerTokens(height: 1.0, thickness: 0.5, colorOpacity: 1.0);

  TilawaDividerTokens copyWith({
    double? height,
    double? thickness,
    double? colorOpacity,
  }) {
    return TilawaDividerTokens(
      height: height ?? this.height,
      thickness: thickness ?? this.thickness,
      colorOpacity: colorOpacity ?? this.colorOpacity,
    );
  }

  static TilawaDividerTokens lerp(
    TilawaDividerTokens a,
    TilawaDividerTokens b,
    double t,
  ) {
    return TilawaDividerTokens(
      height: lerpTokenDouble(a.height, b.height, t),
      thickness: lerpTokenDouble(a.thickness, b.thickness, t),
      colorOpacity: lerpTokenDouble(a.colorOpacity, b.colorOpacity, t),
    );
  }
}

/// Component tokens for [TilawaEmptyState].
@immutable
class TilawaEmptyStateTokens {
  const TilawaEmptyStateTokens({
    required this.iconSize,
    required this.iconOpacity,
    required this.titleSpacing,
    required this.subtitleSpacing,
    required this.actionSpacing,
    required this.padding,
  });

  /// Size of the empty-state icon.
  final double iconSize;

  /// Opacity applied to the icon color.
  final double iconOpacity;

  /// Spacing between the icon and the title.
  final double titleSpacing;

  /// Spacing between the title and the subtitle.
  final double subtitleSpacing;

  /// Spacing between the subtitle and the action widget.
  final double actionSpacing;

  /// Outer padding around the whole empty-state layout.
  final EdgeInsets padding;

  factory TilawaEmptyStateTokens.defaults({
    TilawaDensity density = TilawaDensity.comfortable,
  }) {
    if (density == TilawaDensity.compact) {
      return const TilawaEmptyStateTokens(
        iconSize: 40.0,
        iconOpacity: 0.4,
        titleSpacing: 12.0,
        subtitleSpacing: 4.0,
        actionSpacing: 16.0,
        padding: EdgeInsets.all(16.0),
      );
    }
    return const TilawaEmptyStateTokens(
      iconSize: 48.0,
      iconOpacity: 0.4,
      titleSpacing: 16.0,
      subtitleSpacing: 8.0,
      actionSpacing: 24.0,
      padding: EdgeInsets.all(24.0),
    );
  }

  TilawaEmptyStateTokens copyWith({
    double? iconSize,
    double? iconOpacity,
    double? titleSpacing,
    double? subtitleSpacing,
    double? actionSpacing,
    EdgeInsets? padding,
  }) {
    return TilawaEmptyStateTokens(
      iconSize: iconSize ?? this.iconSize,
      iconOpacity: iconOpacity ?? this.iconOpacity,
      titleSpacing: titleSpacing ?? this.titleSpacing,
      subtitleSpacing: subtitleSpacing ?? this.subtitleSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      padding: padding ?? this.padding,
    );
  }

  static TilawaEmptyStateTokens lerp(
    TilawaEmptyStateTokens a,
    TilawaEmptyStateTokens b,
    double t,
  ) {
    return TilawaEmptyStateTokens(
      iconSize: lerpTokenDouble(a.iconSize, b.iconSize, t),
      iconOpacity: lerpTokenDouble(a.iconOpacity, b.iconOpacity, t),
      titleSpacing: lerpTokenDouble(a.titleSpacing, b.titleSpacing, t),
      subtitleSpacing: lerpTokenDouble(a.subtitleSpacing, b.subtitleSpacing, t),
      actionSpacing: lerpTokenDouble(a.actionSpacing, b.actionSpacing, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
    );
  }
}
