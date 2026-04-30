import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/bottom_player_widget.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import '../widgets/reciter_card.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FavoritesCubit>()..loadFavorites(),
      child: BlocListener<FavoritesCubit, FavoritesState>(
        listener: (context, state) {
          if (state is FavoritesLoaded && state.removedReciter != null) {
            final ReciterEntity reciter = state.removedReciter!;
            ToastUtils.showSuccessToast(
              context.l10n.reciterRemovedFromFavorites(reciter.name),
            );
          }
        },
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                leading: context.canPop() ? const TilawaBackButton() : null,
                title: Text(context.l10n.favorites),
              ),
              body: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, state) {
                  if (state is FavoritesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FavoritesError) {
                    return Center(
                      child: Text(
                        state.failure.localizedMessage(context),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    );
                  } else if (state is FavoritesLoaded) {
                    if (state.favorites.isEmpty) {
                      return _buildEmptyState(context, context.l10n);
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: state.favorites.length,
                      separatorBuilder: (context, index) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ReciterEntity reciter = state.favorites[index];
                        return Dismissible(
                          key: ValueKey(reciter.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            context.read<FavoritesCubit>().toggleFavorite(
                              reciter,
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
            const Positioned.fill(child: BottomPlayerWidget()),
          ],
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
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          SizedBox(height: 16),
          Text(
            l10n.noFavorites,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
