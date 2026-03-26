import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
<<<<<<< HEAD
import 'package:tilawa/core/extensions.dart';
=======
>>>>>>> master
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
<<<<<<< HEAD
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
=======
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
>>>>>>> master
          onTap: () {
            ReciterDetailsRoute(
              reciterId: reciter.id.toString(),
              $extra: reciter,
            ).push(context);
          },
          child: Ink(
            decoration: BoxDecoration(
<<<<<<< HEAD
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
              ),
=======
              borderRadius: BorderRadius.circular(20),
>>>>>>> master
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
<<<<<<< HEAD
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
=======
            padding: EdgeInsets.all(12),
            child: Row(
              spacing: 12,
              children: [
                _ReciterAvatar(reciter: reciter),
                Expanded(child: _ReciterInfo(reciter: reciter)),
                _FavoriteButton(reciter: reciter),
              ],
>>>>>>> master
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

    return Container(
<<<<<<< HEAD
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
=======
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
>>>>>>> master
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.9),
            theme.primaryColor.withValues(alpha: 0.72),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          reciter.letter,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
<<<<<<< HEAD
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
=======
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
>>>>>>> master
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
<<<<<<< HEAD
        Row(
          children: [
            Expanded(
              child: Text(
                reciter.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
=======
        Text(
          reciter.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_music_rounded,
                      size: 12,
                      color: theme.primaryColor,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.recitationsAvailable(reciter.moshaf.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
>>>>>>> master
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _RecitationsBadge(count: reciter.moshaf.length),
          ],
        ),
<<<<<<< HEAD
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
=======
        if (reciter.moshaf.isNotEmpty) ...[
          SizedBox(height: 6),
>>>>>>> master
          Text(
            context.l10n.recitationsAvailable(reciter.moshaf.length),
            style: theme.textTheme.bodySmall?.copyWith(
<<<<<<< HEAD
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
=======
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
>>>>>>> master
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
<<<<<<< HEAD
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
=======
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        context.read<FavoritesCubit>().toggleFavorite(reciter);
      },
      child: Container(
        padding: EdgeInsets.all(8),
>>>>>>> master
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.primaryColor.withValues(alpha: 0.06),
        ),
<<<<<<< HEAD
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: 20,
          color: isFavorite
              ? Colors.redAccent
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
=======
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          buildWhen: (previous, current) {
            final bool wasFavorite =
                previous is FavoritesLoaded &&
                previous.favoriteIds.contains(reciter.id);
            final bool isFavorite =
                current is FavoritesLoaded &&
                current.favoriteIds.contains(reciter.id);
            return wasFavorite != isFavorite;
          },
          builder: (context, state) {
            final bool isFavorite =
                state is FavoritesLoaded &&
                state.favoriteIds.contains(reciter.id);
            return Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              size: 22,
              color: isFavorite
                  ? Colors.redAccent
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            );
          },
>>>>>>> master
        ),
      ),
    );
  }
}
