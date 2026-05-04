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

    return Semantics(
      identifier: ReciterSemanticsIds.reciterCard(reciter.id),
      child: RepaintBoundary(
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
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.22,
                  ),
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
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reciter.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
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
                Icons.headphones_rounded,
                size: tokens.iconSizeExtraSmall + 2,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.75,
                ),
              ),
              Flexible(
                child: Text(
                  firstMoshaf,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
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

    return Semantics(
      identifier: ReciterSemanticsIds.reciterFavoriteButton(reciter.id),
      child: Material(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
        child: InkWell(
          radius: tokens.radiusExtraLarge,
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          onTap: () => context.read<FavoritesCubit>().toggleFavorite(reciter),
          child: SizedBox(
            width: tokens.iconSizeLarge,
            height: tokens.iconSizeLarge,
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              size: tokens.iconSizeSmall,
              color: isFavorite
                  ? Colors.redAccent
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
