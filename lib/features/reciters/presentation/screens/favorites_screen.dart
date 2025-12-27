import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../widgets/reciter_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FavoritesCubit>()..loadFavorites(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.favorites)),
        body: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            if (state is FavoritesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FavoritesError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            } else if (state is FavoritesLoaded) {
              if (state.favorites.isEmpty) {
                return _buildEmptyState(context, context.l10n);
              }
              return ListView.separated(
                padding: EdgeInsets.all(16.r),
                itemCount: state.favorites.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final ReciterEntity reciter = state.favorites[index];
                  return Dismissible(
                    key: ValueKey(reciter.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      final FavoritesCubit cubit = context
                          .read<FavoritesCubit>();
                      cubit.toggleFavorite(reciter);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.reciterRemovedFromFavorites(
                              reciter.name,
                            ),
                          ), // Improve string if needed
                          action: SnackBarAction(
                            label: context.l10n.undo,
                            onPressed: () {
                              cubit.toggleFavorite(reciter);
                            },
                          ),
                        ),
                      );
                    },
                    child: ReciterCard(reciter: reciter),
                  );
                },
              );
            }
            return const SizedBox.shrink(); // Initial state
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80.r,
            color: Theme.of(context).disabledColor,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.noRecitersFound, // Or a dedicated "noFavorites" string if available
            style: TextStyle(
              fontSize: 18.sp,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
