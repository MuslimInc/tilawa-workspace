import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class ReciterCard extends StatelessWidget {
  const ReciterCard({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return RepaintBoundary(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          onTap: () {
            ReciterDetailsRoute(
              reciterId: reciter.id.toString(),
              $extra: reciter,
            ).push(context);
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(tokens.radiusLarge),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  // _ReciterAvatar(reciter: reciter),
                  // SizedBox(width: tokens.spaceMedium),
                  Expanded(child: _ReciterInfo(reciter: reciter)),
                  SizedBox(width: tokens.spaceSmall),
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

class _ReciterAvatar extends StatelessWidget {
  const _ReciterAvatar({required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final primaryColor = theme.primaryColor;

    return RepaintBoundary(
      child: Container(
        width: tokens.iconSizeExtraLarge,
        height: tokens.iconSizeExtraLarge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          color: primaryColor.withValues(alpha: 0.85),
        ),
        child: Center(
          child: Text(
            reciter.letter,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final String firstMoshaf = reciter.moshaf.isNotEmpty
        ? reciter.moshaf.first.name
        : '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reciter.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // SizedBox(width: tokens.spaceSmall),
            // _RecitationsBadge(count: reciter.moshaf.length),
          ],
        ),
        if (firstMoshaf.isNotEmpty) ...[
          SizedBox(height: tokens.spaceExtraSmall),
          Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                size: tokens.iconSizeExtraSmall + 2,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.75,
                ),
              ),
              SizedBox(width: tokens.spaceExtraSmall),
              Expanded(
                child: Text(
                  firstMoshaf,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ] else ...[
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            context.l10n.recitationsAvailable(reciter.moshaf.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

class _RecitationsBadge extends StatelessWidget {
  const _RecitationsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_music_rounded,
            size: tokens.iconSizeExtraSmall,
            color: theme.primaryColor,
          ),
          SizedBox(width: tokens.spaceExtraSmall),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    final bool isFavorite = context.select<FavoritesCubit, bool>((cubit) {
      final FavoritesState state = cubit.state;
      return state is FavoritesLoaded && state.favoriteIds.contains(reciter.id);
    });

    return Material(
      color: theme.primaryColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
      child: InkWell(
        radius: tokens.radiusExtraLarge,
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        onTap: () => context.read<FavoritesCubit>().toggleFavorite(reciter),
        child: SizedBox(
          width: tokens.iconSizeExtraLarge - tokens.spaceSmall,
          height: tokens.iconSizeExtraLarge - tokens.spaceSmall,
          child: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            size: tokens.iconSizeMedium,
            color: isFavorite
                ? Colors.redAccent
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
