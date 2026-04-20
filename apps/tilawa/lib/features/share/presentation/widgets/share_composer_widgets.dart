import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A card container for share composer controls.
class ShareControlsCard extends StatelessWidget {
  const ShareControlsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: tokens.opacitySubtle,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: tokens.opacitySubtle,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// A shell for a control tile in the composer.
class ShareControlTileShell extends StatelessWidget {
  const ShareControlTileShell({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        children: [
          Icon(icon, size: tokens.iconSizeSmall, color: theme.primaryColor),
          SizedBox(width: tokens.spaceSmall),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(child: child),
        ],
      ),
    );

    if (onTap == null) return content;
    var borderRadius = BorderRadius.vertical(
      top: Radius.circular(tokens.radiusLarge),
    );
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
    );
  }
}

/// A divider for control tiles.
class ShareTileDivider extends StatelessWidget {
  const ShareTileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outline.withValues(
        alpha: theme.tokens.opacitySubtle,
      ),
    );
  }
}

/// A stepper widget for selecting Ayah numbers.
class AyahStepper extends StatelessWidget {
  const AyahStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final clamped = value.clamp(min, max);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: tokens.opacitySubtle,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: tokens.opacitySubtle,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: clamped > min,
            onTap: () => onChanged(clamped - 1),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$clamped',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: clamped < max,
            onTap: () => onChanged(clamped + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: tokens.opacityMedium);

    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Icon(icon, size: tokens.iconSizeSmall, color: color),
        ),
      ),
    );
  }
}
