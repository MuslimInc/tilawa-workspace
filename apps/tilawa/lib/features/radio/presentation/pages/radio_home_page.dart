import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/radio_station.dart';
import '../cubit/radio_cubit.dart';
import '../cubit/radio_state.dart';
import '../widgets/radio_home_skeleton.dart';
import '../widgets/radio_live_badge.dart';
import '../widgets/radio_playback_actions.dart';
import '../widgets/radio_station_artwork.dart';
import '../widgets/radio_station_card.dart';

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return TilawaShellChildScaffold(
      appBar: TilawaAppBar(
        title: l10n.radioTitle,
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => context.read<RadioCubit>().refresh(
              language: RadioPlaybackActions.apiLanguage(context),
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<RadioCubit, RadioState>(
        builder: (context, state) {
          return switch (state.status) {
            RadioStatus.initial ||
            RadioStatus.loading => const RadioHomeSkeleton(),
            RadioStatus.error => TilawaErrorState(
              icon: Icons.radio_rounded,
              title: l10n.radioErrorTitle,
              subtitle: _errorMessage(context, state),
              retryLabel: l10n.retry,
              onRetry: () => context.read<RadioCubit>().load(
                language: RadioPlaybackActions.apiLanguage(context),
              ),
            ),
            RadioStatus.empty => TilawaEmptyState(
              icon: Icons.radio_rounded,
              title: l10n.radioEmptyTitle,
              subtitle: l10n.radioEmptyMessage,
              action: TilawaButton(
                text: l10n.retry,
                onPressed: () => context.read<RadioCubit>().refresh(
                  language: RadioPlaybackActions.apiLanguage(context),
                ),
              ),
            ),
            RadioStatus.loaded => RefreshIndicator(
              onRefresh: () => context.read<RadioCubit>().refresh(
                language: RadioPlaybackActions.apiLanguage(context),
              ),
              child: CustomScrollView(
                slivers: [
                  if (state.isOffline)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          tokens.spaceMedium,
                          tokens.spaceSmall,
                          tokens.spaceMedium,
                          0,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusMedium,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceMedium),
                            child: Text(l10n.radioOfflineBanner),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.all(tokens.spaceMedium),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (state.featured != null && !state.hasSearch)
                          _FeaturedStation(
                            station: state.featured!,
                          ),
                        if (state.featured != null && !state.hasSearch)
                          SizedBox(height: tokens.spaceLarge),
                        TilawaSearchField(
                          controller: _searchController,
                          hintText: l10n.radioSearchHint,
                          onChanged: context.read<RadioCubit>().search,
                          onClear: () {
                            _searchController.clear();
                            context.read<RadioCubit>().search('');
                          },
                        ),
                        if (!state.hasSearch && state.favorites.isNotEmpty) ...[
                          SizedBox(height: tokens.spaceLarge),
                          _SectionTitle(title: l10n.radioFavorites),
                          SizedBox(height: tokens.spaceSmall),
                          _HorizontalStations(
                            stations: state.favorites,
                          ),
                        ],
                        if (!state.hasSearch && state.recent.isNotEmpty) ...[
                          SizedBox(height: tokens.spaceLarge),
                          _SectionTitle(title: l10n.radioRecentlyPlayed),
                          SizedBox(height: tokens.spaceSmall),
                          _HorizontalStations(
                            stations: state.recent,
                          ),
                        ],
                        SizedBox(height: tokens.spaceLarge),
                        _SectionTitle(
                          title: state.hasSearch
                              ? l10n.radioSearchResults
                              : l10n.radioAllStations,
                        ),
                        SizedBox(height: tokens.spaceSmall),
                      ]),
                    ),
                  ),
                  if (state.visibleStations.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: TilawaEmptyState(
                        icon: Icons.search_off_rounded,
                        title: l10n.radioNoSearchResults,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceMedium,
                        0,
                        tokens.spaceMedium,
                        tokens.spaceLarge,
                      ),
                      sliver: SliverList.separated(
                        itemCount: state.visibleStations.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: tokens.spaceSmall),
                        itemBuilder: (context, index) {
                          final RadioStation station =
                              state.visibleStations[index];
                          return RadioStationCard(
                            station: station,
                            onPlay: () => RadioPlaybackActions.play(
                              context,
                              station,
                            ),
                            onFavorite: () => context
                                .read<RadioCubit>()
                                .toggleFavorite(station.id),
                            onTap: () => RadioPlaybackActions.openFullPlayer(
                              context,
                              station,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }

  String _errorMessage(BuildContext context, RadioState state) {
    final String? message = state.failure?.message;
    if (message == 'offline') return context.l10n.radioErrorOffline;
    if (message == 'timeout') return context.l10n.radioErrorTimeout;
    return context.l10n.radioErrorGeneric;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HorizontalStations extends StatelessWidget {
  const _HorizontalStations({required this.stations});

  final List<RadioStation> stations;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stations.length,
        separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSmall),
        itemBuilder: (context, index) {
          final RadioStation station = stations[index];
          return RadioStationCard(
            station: station,
            compact: true,
            onPlay: () => RadioPlaybackActions.play(context, station),
            onFavorite: () =>
                context.read<RadioCubit>().toggleFavorite(station.id),
            onTap: () => RadioPlaybackActions.openFullPlayer(context, station),
          );
        },
      ),
    );
  }
}

class _FeaturedStation extends StatelessWidget {
  const _FeaturedStation({required this.station});

  final RadioStation station;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final product = theme.productColors;
    return TilawaCard(
      onTap: () => RadioPlaybackActions.openFullPlayer(context, station),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              product.featuredGradientStart,
              product.featuredGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
        ),
        padding: EdgeInsets.all(tokens.spaceMedium),
        child: Row(
          children: [
            RadioStationArtwork(
              stationId: station.id,
              size: 88,
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.radioFeatured,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: product.featuredGradientForeground.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    station.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: product.featuredGradientForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSmall),
                  const RadioLiveBadge(),
                ],
              ),
            ),
            TilawaButton(
              onPressed: () => RadioPlaybackActions.play(context, station),
              text: context.l10n.play,
            ),
          ],
        ),
      ),
    );
  }
}
