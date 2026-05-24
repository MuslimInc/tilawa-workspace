import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import '../widgets/reciter_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

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
              appBar: TilawaCatalogAppBar.titleOnly(
                context,
                title: context.l10n.favorites,
              ),
              body: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, state) {
                  if (state is FavoritesLoading) {
                    return const TilawaLoadingIndicator();
                  } else if (state is FavoritesError) {
                    return TilawaIllustratedState(
                      icon: Icons.error_outline_rounded,
                      iconColor: colorScheme.error,
                      title: state.failure.localizedMessage(context) ??
                          context.l10n.unexpectedError,
                      semanticLabel: state.failure.localizedMessage(context) ??
                          context.l10n.unexpectedError,
                    );
                  } else if (state is FavoritesLoaded) {
                    if (state.favorites.isEmpty) {
                      return _buildEmptyState(context, context.l10n);
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceLarge,
                        tokens.spaceLarge,
                        tokens.spaceLarge,
                        120,
                      ),
                      itemCount: state.favorites.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: tokens.spaceSmall),
                      itemBuilder: (context, index) {
                        final ReciterEntity reciter = state.favorites[index];
                        return Dismissible(
                          key: ValueKey(reciter.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: tokens.spaceLarge),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(
                                tokens.radiusLarge,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.onError,
                            ),
                          ),
                          onDismissed: (direction) {
                            context.read<FavoritesCubit>().toggleFavorite(
                              reciter,
                            );
                          },
                          child: ReciterCard(
                            reciter: reciter,
                            favoritesOnlyContext: true,
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink(); // Initial state
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return TilawaIllustratedState(
      icon: Icons.favorite_border_rounded,
      title: l10n.noFavorites,
      semanticLabel: l10n.noFavorites,
    );
  }
}
