import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../reciter_semantics_ids.dart';

class ReciterCard extends StatelessWidget {
  const ReciterCard({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: tokens.borderWidthThin,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            onTap: () {
              ReciterDetailsRoute(
                reciterId: reciter.id.toString(),
                $extra: reciter,
              ).push(context);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLarge,
                vertical: tokens.spaceLarge,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: tokens.spaceSmall,
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      identifier: ReciterSemanticsIds.reciterCard(reciter.id),
                      label: context.l10n.a11yOpenReciterDetails(reciter.name),
                      child: _ReciterInfo(reciter: reciter),
                    ),
                  ),
                  _FavoriteButton(reciter: reciter),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReciterInfo extends StatelessWidget {
  const _ReciterInfo({required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final String firstMoshaf = reciter.moshaf.isNotEmpty
        ? reciter.moshaf.first.name
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reciter.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (firstMoshaf.isNotEmpty) ...[
          SizedBox(height: tokens.spaceSmall),
          Row(
            spacing: tokens.spaceExtraSmall,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                FluentIcons.headphones_20_regular,
                size: tokens.iconSizeSmall,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: tokens.opacityEmphasis,
                ),
              ),
              Flexible(
                child: Text(
                  firstMoshaf,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ] else ...[
          SizedBox(height: tokens.spaceSmall),
          Text(
            context.l10n.recitationsAvailable(reciter.moshaf.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool isFavorite = context.select<FavoritesCubit, bool>((cubit) {
      final FavoritesState state = cubit.state;
      return state is FavoritesLoaded && state.favoriteIds.contains(reciter.id);
    });

    final double hitExtent = math.max(
      kMinInteractiveDimension,
      tokens.iconSizeLargePlus,
    );

    return Semantics(
      button: true,
      identifier: ReciterSemanticsIds.reciterFavoriteButton(reciter.id),
      toggled: isFavorite,
      label: isFavorite
          ? context.l10n.removeFromFavorites
          : context.l10n.addToFavorites,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        child: InkWell(
          radius: tokens.radiusExtraLarge,
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          onTap: () => context.read<FavoritesCubit>().toggleFavorite(reciter),
          child: SizedBox(
            width: hitExtent,
            height: hitExtent,
            child: Center(
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                size: tokens.iconSizeMedium,
                color: isFavorite
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant.withValues(
                        alpha: tokens.opacityMedium,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
