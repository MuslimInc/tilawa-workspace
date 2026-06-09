import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';
import 'reciter_card.dart';

/// Favorites tab on the Reciters home screen.
///
/// Reads from [FavoritesCubit] only — not filtered through [RecitersBloc].
class RecitersFavoritesTab extends StatelessWidget {
  const RecitersFavoritesTab({
    super.key,
    required this.pageStorageKey,
    required this.scrollController,
  });

  final PageStorageKey<String> pageStorageKey;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ScrollController? primaryScrollController =
        PrimaryScrollController.maybeOf(context);

    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (BuildContext context, FavoritesState state) {
        return CustomScrollView(
          key: pageStorageKey,
          controller: primaryScrollController == null
              ? scrollController
              : null,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            switch (state) {
              FavoritesLoading() || FavoritesInitial() => _FavoritesLoadingSliver(
                semanticsLabel: context.l10n.loadingReciters,
              ),
              FavoritesError(:final failure) => _FavoritesMessageSliver(
                icon: Icons.error_outline_rounded,
                title:
                    failure.localizedMessage(context) ??
                    context.l10n.unexpectedError,
                isError: true,
              ),
              FavoritesLoaded(:final favorites) when favorites.isEmpty =>
                const _FavoritesEmptySliver(),
              FavoritesLoaded(:final favorites) => _FavoritesListSliver(
                favorites: favorites,
              ),
              FavoritesState() => _FavoritesLoadingSliver(
                semanticsLabel: context.l10n.loadingReciters,
              ),
            },
          ],
        );
      },
    );
  }
}

/// Fills the remaining viewport without [SliverFillRemaining] intrinsics issues.
class _FavoritesViewportSliver extends StatelessWidget {
  const _FavoritesViewportSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final double height = math.max(constraints.remainingPaintExtent, 0);

        return SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: constraints.crossAxisExtent,
              height: height,
            ),
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _FavoritesLoadingSliver extends StatelessWidget {
  const _FavoritesLoadingSliver({required this.semanticsLabel});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return _FavoritesViewportSliver(
      child: TilawaLoadingIndicator(semanticsLabel: semanticsLabel),
    );
  }
}

class _FavoritesMessageSliver extends StatelessWidget {
  const _FavoritesMessageSliver({
    required this.icon,
    required this.title,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return _FavoritesViewportSliver(
      child: TilawaIllustratedState(
        icon: icon,
        iconColor: isError ? theme.colorScheme.error : null,
        title: title,
        semanticLabel: title,
      ),
    );
  }
}

class _FavoritesEmptySliver extends StatelessWidget {
  const _FavoritesEmptySliver();

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final String title = context.l10n.noFavorites;

    return _FavoritesViewportSliver(
      child: TilawaIllustratedState(
        visual: const TilawaStateVisual(
          icon: Icons.favorite_border_rounded,
          tone: TilawaStateVisualTone.tertiary,
        ),
        title: title,
        subtitle: context.l10n.tourRecitersFavoritesDescription,
        semanticLabel: title,
        maxWidth: tokens.contentMaxWidthForm * 0.6,
      ),
    );
  }
}

class _FavoritesListSliver extends StatelessWidget {
  const _FavoritesListSliver({required this.favorites});

  final List<ReciterEntity> favorites;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final int itemCount = favorites.length + favorites.length - 1;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        120,
      ),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (index.isOdd) {
            return SizedBox(height: tokens.spaceSmall);
          }

          final ReciterEntity reciter = favorites[index ~/ 2];
          return ReciterCard(
            key: ValueKey(reciter.id),
            reciter: reciter,
          );
        },
      ),
    );
  }
}
