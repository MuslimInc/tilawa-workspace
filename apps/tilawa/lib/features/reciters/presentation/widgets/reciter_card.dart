import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

class ReciterCard extends StatelessWidget {
  const ReciterCard({super.key, required this.reciter});

  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return RepaintBoundary(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            ReciterDetailsRoute(
              reciterId: reciter.id.toString(),
              $extra: reciter,
            ).push(context);
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
              ),
              // Remove expensive boxShadow to reduce raster jank
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 8, 10),
              child: Row(
                children: [
                  _ReciterAvatar(reciter: reciter),
                  const SizedBox(width: 10),
                  Expanded(child: _ReciterInfo(reciter: reciter)),
                  const SizedBox(width: 6),
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
    final ThemeData theme = Theme.of(context);

    // Pre-calculate colors to avoid multiple withValues calls
    final primaryColor = theme.primaryColor;

    return RepaintBoundary(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
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
    final ThemeData theme = Theme.of(context);
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
            const SizedBox(width: 8),
            _RecitationsBadge(count: reciter.moshaf.length),
          ],
        ),
        if (firstMoshaf.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.headphones_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.75,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
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
          const SizedBox(height: 6),
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
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_music_rounded,
            size: 12,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 4),
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
    final ThemeData theme = Theme.of(context);
    final bool isFavorite = context.select<FavoritesCubit, bool>((cubit) {
      final FavoritesState state = cubit.state;
      return state is FavoritesLoaded && state.favoriteIds.contains(reciter.id);
    });

    return InkResponse(
      radius: 22,
      onTap: () => context.read<FavoritesCubit>().toggleFavorite(reciter),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.primaryColor.withValues(alpha: 0.06),
        ),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: 20,
          color: isFavorite
              ? Colors.redAccent
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
