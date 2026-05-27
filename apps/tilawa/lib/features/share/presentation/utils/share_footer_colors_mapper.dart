import 'package:flutter/material.dart';

import '../../domain/entities/share_footer_colors.dart';

ShareFooterColors? shareFooterColorsFromTheme({
  Color? background,
  Color? foreground,
}) {
  if (background == null && foreground == null) {
    return null;
  }
  return ShareFooterColors(
    backgroundArgb: background?.toARGB32(),
    foregroundArgb: foreground?.toARGB32(),
  );
}
