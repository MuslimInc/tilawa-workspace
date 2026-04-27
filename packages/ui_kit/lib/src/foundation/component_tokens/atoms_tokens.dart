import 'package:flutter/material.dart';

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
