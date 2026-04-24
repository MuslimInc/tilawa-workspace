import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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

  static const double _surahFontSize = 11.5;
  static const double _juzFontSize = 10.5;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.tokens.spaceSmall),
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
            SizedBox(width: theme.tokens.spaceSmall),
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
