import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../l10n/generated/app_localizations.dart';
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
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ReciterDetailsRoute(
              reciterId: reciter.id.toString(),
              $extra: reciter,
            ).push(context);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                _ReciterAvatar(reciter: reciter),
                SizedBox(width: 14),
                Expanded(child: _ReciterInfo(reciter: reciter)),
                _FavoriteButton(reciter: reciter),
              ],
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
    return Container(
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.8),
            theme.primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          reciter.letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                ),
              ),
            ),
          ],
        ),
        if (reciter.moshaf.isNotEmpty) ...[
          SizedBox(height: 6),
          Text(
            reciter.moshaf.first.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        context.read<FavoritesCubit>().toggleFavorite(reciter);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
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
        ),
      ),
    );
  }
}
