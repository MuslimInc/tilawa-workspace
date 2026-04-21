import 'package:flutter/material.dart';

class PageMetadataStrip extends StatelessWidget {
  const PageMetadataStrip({
    super.key,
    required this.surahNames,
    required this.juzLabel,
    required this.uiTextDirection,
    required this.textColor,
  });

  final String surahNames;
  final String juzLabel;
  final TextDirection uiTextDirection;
  final Color textColor;

  static const double _horizontalPadding = 6;
  static const double _topPadding = 0;
  static const double _bottomPadding = 0;
  static const double _sectionSpacing = 6;
  static const double _surahFontSize = 11.5;
  static const double _juzFontSize = 10.5;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        _topPadding,
        _horizontalPadding,
        _bottomPadding,
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            child: Text(
              surahNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: uiTextDirection,
              textAlign: TextAlign.left,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: _surahFontSize,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
          if (juzLabel.isNotEmpty) ...[
            const SizedBox(width: _sectionSpacing),
            Text(
              juzLabel,
              maxLines: 1,
              textDirection: uiTextDirection,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: _juzFontSize,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
