import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';
import 'athkar_session_count_button.dart';

/// Floating session chrome: page indicator + reset / counter / share.
class AthkarSessionBottomBar extends StatelessWidget {
  const AthkarSessionBottomBar({
    super.key,
    required this.item,
    required this.currentCount,
    required this.currentIndex,
    required this.totalItems,
    required this.onCountTap,
    required this.onReset,
  });

  final AthkarItem item;
  final int currentCount;
  final int currentIndex;
  final int totalItems;
  final VoidCallback onCountTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDone = currentCount == 0;
    final bool canReset = currentCount != item.count;
    final double sideButtonSize = theme.componentTokens.iconActionButton.size;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceSmall,
          tokens.spaceLarge,
          tokens.spaceMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceSmall,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.l10n.athkarPageIndicator(
                  totalItems,
                  currentIndex + 1,
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FloatingSessionIconButton(
                  size: sideButtonSize,
                  icon: Icons.restart_alt_rounded,
                  tooltip: context.l10n.reset,
                  enabled: canReset,
                  onTap: () => _confirmReset(context),
                ),
                SizedBox(width: tokens.spaceLarge),
                AthkarSessionCountButton(
                  currentCount: currentCount,
                  totalCount: item.count,
                  isDone: isDone,
                  onTap: onCountTap,
                ),
                SizedBox(width: tokens.spaceLarge),
                _FloatingSessionIconButton(
                  size: sideButtonSize,
                  icon: Icons.ios_share_rounded,
                  tooltip: context.l10n.share,
                  onTap: () => _shareItem(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final bool? confirmed = await showTilawaConfirmSheet(
      context: context,
      title: context.l10n.reset,
      message: context.l10n.athkarResetConfirmationMessage,
      confirmLabel: context.l10n.reset,
      cancelLabel: context.l10n.cancel,
      confirmVariant: TilawaButtonVariant.primary,
      onConfirm: () => Navigator.of(context).pop(true),
      onClose: () => Navigator.of(context).pop(false),
    );
    if (confirmed == true && context.mounted) {
      onReset();
    }
  }

  Future<void> _shareItem(BuildContext context) async {
    final StringBuffer buffer = StringBuffer(item.textAr);
    if (item.reference.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..write('«${item.reference}»');
    }
    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: context.l10n.athkar,
      ),
    );
  }
}

class _FloatingSessionIconButton extends StatelessWidget {
  const _FloatingSessionIconButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: enabled
            ? tokens.elevationFloating(colorScheme.shadow)
            : const <BoxShadow>[],
      ),
      child: TilawaIconActionButton(
        size: size,
        icon: icon,
        tooltip: tooltip,
        semanticLabel: tooltip,
        enabled: enabled,
        backgroundColor: colorScheme.surface,
        onTap: onTap,
      ),
    );
  }
}
