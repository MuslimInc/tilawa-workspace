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

    final String helperText = isLoading
        ? context.l10n.prayerTimesRefreshingLocation
        : context.l10n.prayerTimesTapToRefreshLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 420;
        final bool showHelperText = isLoading || !compact;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          child: InkWell(
            onTap: isLoading ? null : onUpdateLocation,
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerLowest,
                  ],
                ),
                borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: tokens.opacityMedium,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? tokens.spaceMedium : tokens.spaceLarge,
                ),
                child: Row(
                  children: [
                    _LocationIcon(compact: compact),
                    SizedBox(
                      width: compact ? tokens.spaceMedium : tokens.spaceLarge,
                    ),
                    _LocationInfo(
                      locationName: locationName,
                      helperText: helperText,
                      showHelperText: showHelperText,
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    _LocationActionButton(
                      isLoading: isLoading,
                      compact: compact,
                      onPressed: onUpdateLocation,
                    ),
                  ],
                ),
              ),
            ),
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

    final double size = compact ? 44 : 48;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(
          compact ? tokens.radiusMedium : tokens.radiusLarge,
        ),
      ),
      child: Icon(
        Icons.location_on_rounded,
        size: compact ? tokens.iconSizeMedium : tokens.iconSizeLarge,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({
    required this.locationName,
    required this.helperText,
    required this.showHelperText,
  });

  final String? locationName;
  final String helperText;
  final bool showHelperText;

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
            maxLines: showHelperText ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (showHelperText) ...[
            const SizedBox(height: 2),
            Text(
              helperText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

    final double size = compact ? 36 : 40;

    return Tooltip(
      message: context.l10n.updateLocation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(
            compact ? tokens.radiusMedium : tokens.radiusLarge - 4,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: tokens.spaceLarge,
                  height: tokens.spaceLarge,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimaryContainer,
                  ),
                )
              : Icon(
                  Icons.gps_fixed_rounded,
                  size: tokens.iconSizeMedium,
                  color: colorScheme.onPrimaryContainer,
                ),
        ),
      ),
    );
  }
}
