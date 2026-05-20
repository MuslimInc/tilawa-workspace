import 'package:flutter/material.dart';

import '../molecules/tilawa_icon_action_button.dart';
import 'component_tokens.dart';

/// Title row for [TilawaBottomSheetScaffold] with optional end-aligned close.
class TilawaBottomSheetTitleRow extends StatelessWidget {
  const TilawaBottomSheetTitleRow({
    super.key,
    required this.title,
    this.trailingClose = false,
    this.onClose,
    this.closeSemanticLabel = 'Close',
    this.titleStyle,
  });

  final String title;
  final bool trailingClose;
  final VoidCallback? onClose;
  final String closeSemanticLabel;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.bottomSheetScaffold;
    final effectiveTitleStyle =
        titleStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: effectiveTitleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingClose) ...[
          const SizedBox(width: 8),
          TilawaIconActionButton(
            icon: Icons.close_rounded,
            onTap: onClose ?? () => Navigator.maybePop(context),
            semanticLabel: closeSemanticLabel,
            tooltip: closeSemanticLabel,
            size: tokens.closeButtonSize,
            iconSize: tokens.closeButtonSize * 0.55,
          ),
        ],
      ],
    );
  }
}
