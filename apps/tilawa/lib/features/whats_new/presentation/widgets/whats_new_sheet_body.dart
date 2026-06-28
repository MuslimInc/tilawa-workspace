import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Scrollable bullet list for release highlights.
class WhatsNewSheetBody extends StatelessWidget {
  const WhatsNewSheetBody({
    super.key,
    required this.highlights,
  });

  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TextDirection textDirection = Directionality.of(context);
    final TextStyle bodyStyle = theme.textTheme.bodyMedium!.copyWith(
      color: colorScheme.onSurface,
      height: tokens.textHeightLoose,
    );
    final TextStyle markerStyle = bodyStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final double bulletTopInset = _firstLineBulletInset(
      context: context,
      bodyStyle: bodyStyle,
      markerStyle: markerStyle,
    );

    if (highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    final EdgeInsets padding = _contentPadding(context, tokens);

    return SingleChildScrollView(
      padding: padding,
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: highlights
              .map(
                (String highlight) => Row(
                  crossAxisAlignment: .start,
                  textDirection: textDirection,
                  spacing: tokens.spaceSmall,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: bulletTopInset),
                      child: Text(
                        '•',
                        style: markerStyle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        highlight,
                        style: bodyStyle,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Centers the bullet on the first line when copy wraps to multiple lines.
  static double _firstLineBulletInset({
    required BuildContext context,
    required TextStyle bodyStyle,
    required TextStyle markerStyle,
  }) {
    final double bodyLineHeight = _lineHeight(context, bodyStyle);
    final double markerLineHeight = _lineHeight(context, markerStyle);
    return (bodyLineHeight - markerLineHeight) / 2;
  }

  static double _lineHeight(BuildContext context, TextStyle style) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double fontSize = style.fontSize ?? 14;
    final double height = style.height ?? 1;
    return scaler.scale(fontSize) * height;
  }

  EdgeInsets _contentPadding(
    BuildContext context,
    MeMuslimDesignTokens tokens,
  ) {
    final EdgeInsets base = TilawaBottomSheetScaffold.resolvedBodyPadding(
      context,
    );
    final EdgeInsets extra = EdgeInsetsDirectional.fromSTEB(
      tokens.spaceSmall,
      tokens.spaceMedium,
      tokens.spaceSmall,
      tokens.spaceExtraLarge,
    ).resolve(Directionality.of(context));
    return base + extra;
  }
}
