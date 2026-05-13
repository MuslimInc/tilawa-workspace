import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class TilawaSectionTitle extends StatelessWidget {
  const TilawaSectionTitle({
    super.key,
    required this.title,
    this.color,
    this.fontWeight,
  });

  final String title;
  final Color? color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.sectionTitle;

    return Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: fontWeight ?? componentTokens.fontWeight,
        ),
      ),
    );
  }
}
