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
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onUpdateLocation,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.currentLocation,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      (locationName != null && locationName!.isNotEmpty)
                          ? locationName!
                          : context.l10n.unknownLocation,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.my_location_rounded,
                  size: 24,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
