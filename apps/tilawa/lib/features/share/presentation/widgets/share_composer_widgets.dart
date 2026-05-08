import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A card container for share composer controls.
class ShareControlsCard extends StatelessWidget {
  const ShareControlsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
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
        spacing: tokens.spaceSmall,
        children: [
          Icon(icon, size: tokens.iconSizeSmall, color: theme.primaryColor),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: child,
            ),
          ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: tokens.borderWidthThin,
        ),
      ),
      child: SizedBox(
        height: 48,
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

  static const double _hitAreaSize = 48;
  static const double _visualSize = 36;

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
      width: _hitAreaSize,
      height: _hitAreaSize,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(
            child: SizedBox(
              width: _visualSize,
              height: _visualSize,
              child: Icon(icon, size: tokens.iconSizeSmall, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class ReciterTile extends StatelessWidget {
  const ReciterTile({
    super.key,
    required this.reciterName,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final String reciterName;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ShareControlTileShell(
      onTap: enabled ? onTap : null,
      icon: Icons.multitrack_audio_rounded,
      label: context.l10n.reciters,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              reciterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          if (isLoading)
            SizedBox(
              width: tokens.iconSizeSmall,
              height: tokens.iconSizeSmall,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              size: tokens.iconSizeMedium,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class AyahRangeTile extends StatelessWidget {
  const AyahRangeTile({
    super.key,
    required this.fromAyah,
    required this.toAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final int fromAyah;
  final int toAyah;
  final int minAyah;
  final int maxAyah;
  final ValueChanged<int> onFromChanged;
  final ValueChanged<int> onToChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ShareControlTileShell(
      icon: Icons.format_list_numbered_rounded,
      label: context.l10n.ayah,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AyahStepper(
              value: fromAyah,
              min: minAyah,
              max: maxAyah,
              onChanged: onFromChanged,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              child: Text(
                '-',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AyahStepper(
              value: toAyah,
              min: minAyah,
              max: maxAyah,
              onChanged: onToChanged,
            ),
          ],
        ),
      ),
    );
  }
}
