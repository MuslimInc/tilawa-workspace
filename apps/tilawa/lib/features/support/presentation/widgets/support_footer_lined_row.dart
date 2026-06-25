import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// One footer row: fixed [leading] slot on the start edge + aligned content.
class SupportFooterLinedRow extends StatelessWidget {
  const SupportFooterLinedRow({
    super.key,
    this.leading,
    required this.content,
    this.contentTextStyle,
  });

  final Widget? leading;
  final Widget content;

  /// When set with [leading], vertically centers the leading widget on the
  /// first line of multi-line [content].
  final TextStyle? contentTextStyle;

  @override
  Widget build(BuildContext context) {
    if (leading == null) {
      return content;
    }

    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double slot = tokens.iconSizeMedium;
    final double leadingTopInset = contentTextStyle == null
        ? 0
        : _firstLineLeadingInset(
            context: context,
            contentStyle: contentTextStyle!,
            leadingSize: tokens.iconSizeSmall,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: Directionality.of(context),
      spacing: tokens.spaceSmall,
      children: [
        Padding(
          padding: EdgeInsets.only(top: leadingTopInset),
          child: SizedBox(
            width: slot,
            height: slot,
            child: Center(child: leading),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  static double _firstLineLeadingInset({
    required BuildContext context,
    required TextStyle contentStyle,
    required double leadingSize,
  }) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double fontSize = contentStyle.fontSize ?? 14;
    final double lineHeight =
        scaler.scale(fontSize) * (contentStyle.height ?? 1);
    return (lineHeight - leadingSize) / 2;
  }
}
