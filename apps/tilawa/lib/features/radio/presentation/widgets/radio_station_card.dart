import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/radio_station.dart';
import 'radio_station_artwork.dart';

class RadioStationCard extends StatelessWidget {
  const RadioStationCard({
    super.key,
    required this.station,
    required this.onPlay,
    required this.onFavorite,
    this.onTap,
    this.compact = false,
  });

  final RadioStation station;
  final VoidCallback onPlay;
  final VoidCallback onFavorite;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    if (compact) {
      return SizedBox(
        width: 132,
        child: TilawaCard(
          onTap: onTap ?? onPlay,
          expandHeight: true,
          padding: EdgeInsets.all(tokens.spaceSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioStationArtwork(
                stationId: station.id,
                compact: true,
                size: 48,
              ),
              SizedBox(height: tokens.spaceSmall),
              Expanded(
                child: Text(
                  station.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TilawaCard(
      onTap: onTap ?? onPlay,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          children: [
            RadioStationArtwork(
              stationId: station.id,
              compact: true,
              size: tokens.iconBoxSize,
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Text(
                station.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: station.isFavorite
                  ? context.l10n.radioRemoveFavorite
                  : context.l10n.radioAddFavorite,
              onPressed: onFavorite,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  station.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(station.isFavorite),
                  color: station.isFavorite
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.play,
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

