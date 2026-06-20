import 'package:flutter/material.dart';

import 'component_tokens.dart';
import 'tilawa_icons.dart';
import 'design_tokens.dart';

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
          SizedBox(width: theme.tokens.spaceSmall),
          _TilawaBottomSheetCloseButton(
            onClose: onClose ?? () => Navigator.maybePop(context),
            semanticLabel: closeSemanticLabel,
            size: tokens.closeButtonSize,
          ),
        ],
      ],
    );
  }
}

class _TilawaBottomSheetCloseButton extends StatelessWidget {
  const _TilawaBottomSheetCloseButton({
    required this.onClose,
    required this.semanticLabel,
    required this.size,
  });

  final VoidCallback onClose;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return IconButton(
      tooltip: semanticLabel,
      onPressed: onClose,
      icon: const Icon(TilawaIcons.dismiss),
      iconSize: designTokens.iconSizeSmall,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        padding: EdgeInsets.zero,
        foregroundColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            designTokens.resolveRadius(
              family: TilawaRadiusFamily.icon,
              width: size,
              height: size,
            ),
          ),
        ),
      ),
    );
  }
}
