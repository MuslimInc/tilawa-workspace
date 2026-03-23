import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String helperText = isLoading
        ? context.l10n.prayerTimesRefreshingLocation
        : context.l10n.prayerTimesTapToRefreshLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 420;
        final bool showHelperText = isLoading || !compact;
        final double borderRadius = compact ? 20 : 24;
        final double outerPadding = compact ? 14 : 16;
        final double leadingSize = compact ? 46 : 52;
        final double actionSize = compact ? 38 : 42;
        final double leadingIconSize = compact ? 22 : 24;
        final double actionIconSize = compact ? 20 : 22;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isLoading ? null : onUpdateLocation,
            borderRadius: BorderRadius.circular(borderRadius),
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
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.42),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(outerPadding),
                child: Row(
                  children: [
                    Container(
                      width: leadingSize,
                      height: leadingSize,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(compact ? 16 : 18),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: leadingIconSize,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(width: compact ? 12 : 14),
                    Expanded(
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
                          const SizedBox(height: 4),
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
                            const SizedBox(height: 4),
                            Text(
                              helperText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: context.l10n.updateLocation,
                      child: Container(
                        width: actionSize,
                        height: actionSize,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            compact ? 14 : 16,
                          ),
                        ),
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: compact ? 18 : 20,
                                  height: compact ? 18 : 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : Icon(
                                  Icons.gps_fixed_rounded,
                                  size: actionIconSize,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                        ),
                      ),
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
