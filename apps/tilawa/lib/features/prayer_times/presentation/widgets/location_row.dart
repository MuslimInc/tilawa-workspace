import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A row displaying the current location with a refresh action.
class LocationRow extends StatelessWidget {
  const LocationRow({
    super.key,
    required this.locationName,
    required this.isLoading,
    required this.onUpdateLocation,
  });

  final String? locationName;
  final bool isLoading;
  final VoidCallback onUpdateLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 420;

        return TilawaCard(
          onTap: isLoading ? null : onUpdateLocation,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.surface, colorScheme.surfaceContainerLowest],
          ),
          borderRadius: tokens.radiusExtraLarge,
          borderColor: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          padding: EdgeInsets.all(
            compact ? tokens.spaceMedium : tokens.spaceLarge,
          ),
          child: Row(
            children: [
              _LocationIcon(compact: compact),
              SizedBox(width: compact ? tokens.spaceMedium : tokens.spaceLarge),
              _LocationInfo(locationName: locationName),
              SizedBox(width: tokens.spaceSmall),
              _LocationActionButton(
                isLoading: isLoading,
                compact: compact,
                onPressed: onUpdateLocation,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationIcon extends StatelessWidget {
  const _LocationIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return TilawaIconBox(
      icon: Icons.location_on_rounded,
      size: compact ? tokens.iconSizeMedium : tokens.iconSizeLarge,
      backgroundColor: colorScheme.primaryContainer,
      iconColor: colorScheme.onPrimaryContainer,
      borderRadius: compact ? tokens.radiusMedium : tokens.radiusLarge,
      padding: compact ? tokens.spaceSmall : tokens.spaceMedium,
    );
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({required this.locationName});

  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.currentLocation,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (locationName != null && locationName!.isNotEmpty)
                ? locationName!
                : context.l10n.unknownLocation,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LocationActionButton extends StatelessWidget {
  const _LocationActionButton({
    required this.isLoading,
    required this.compact,
    required this.onPressed,
  });

  final bool isLoading;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: context.l10n.updateLocation,
      child: TilawaIconBox(
        icon: Icons.gps_fixed_rounded,
        size: tokens.iconSizeMedium,
        backgroundColor: colorScheme.primaryContainer,
        iconColor: colorScheme.onPrimaryContainer,
        borderRadius: compact ? tokens.radiusMedium : tokens.radiusLarge - 4,
        padding: tokens.spaceSmall,
        child: isLoading
            ? SizedBox(
                width: tokens.iconSizeMedium,
                height: tokens.iconSizeMedium,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
    );
  }
}
