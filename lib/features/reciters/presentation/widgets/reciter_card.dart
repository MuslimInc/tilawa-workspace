import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/entities/reciter_entity.dart';
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            ReciterDetailsRoute(
              reciterId: reciter.id.toString(),
              $extra: reciter,
            ).push(context);
          },
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                _buildAvatar(context),
                SizedBox(width: 14.w),
                Expanded(child: _buildInfo(context)),
                GestureDetector(
                  onTap: () {
                    context.read<FavoritesCubit>().toggleFavorite(reciter);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.r),
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
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 20.sp,
                          color: isFavorite
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 60.r,
      height: 60.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.9),
            Theme.of(context).primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          reciter.letter,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.sp,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reciter.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_music_rounded,
                      size: 12,
                      color: theme.primaryColor,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.recitationsAvailable(reciter.moshaf.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
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
          SizedBox(height: 6.h),
          Text(
            reciter.moshaf.first.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.sp,
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
