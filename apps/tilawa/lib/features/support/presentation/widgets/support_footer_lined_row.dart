import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// One footer row: fixed [leading] slot on the start edge (right in RTL) + content.
class SupportFooterLinedRow extends StatelessWidget {
  const SupportFooterLinedRow({
    super.key,
    this.leading,
    required this.content,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget? leading;
  final Widget content;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final double slot = tokens.iconSizeMedium;

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: .spaceBetween,
      spacing: tokens.spaceSmall,
      children: [
        if (leading != null)
          SizedBox(
            width: slot,
            height: slot,
            child: Center(child: leading!),
          ),
        Expanded(child: content),
      ],
    );
  }
}
