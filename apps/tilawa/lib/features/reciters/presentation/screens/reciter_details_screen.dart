import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/quran_player_chrome.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../../../tour_guide/presentation/widgets/tour_target.dart';
import '../bloc/reciter_details_bloc.dart';
import '../bloc/reciter_download_bloc.dart';
import '../layout/reciter_details_fab_layout.dart';
import '../models/reciter_surah_list_item.dart';
import '../tour/reciters_tour_launcher.dart';
import '../tour/reciters_tour_targets.dart';
import '../widgets/download_all_button.dart';
import '../widgets/moshaf_selector.dart';
import '../widgets/reciter_details_app_bar.dart';
import '../widgets/reciter_history_section.dart';
import '../widgets/reciter_search_header.dart';
import '../widgets/surah_grid_item.dart';
import '../widgets/surah_list_tile.dart';

class ReciterDetailsScreen extends StatefulWidget {
  const ReciterDetailsScreen({super.key, required this.reciter});
  final ReciterEntity reciter;

  @override
  State<ReciterDetailsScreen> createState() => _ReciterDetailsScreenState();
}

class _ReciterDetailsScreenState extends State<ReciterDetailsScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _playingSurahKey = GlobalKey();
  bool _showScrollToTop = false;
  bool _hasScrolledToPlaying = false;
  bool _playbackTourAttempted = false;
  ReciterViewMode _lastViewMode = ReciterViewMode.list;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ReciterDetailsBloc>().state.searchQuery,
    );
    if (widget.reciter.moshaf.isEmpty) return;
    final MoshafEntity selectedMoshaf = widget.reciter.moshaf.first;
    context.read<ReciterDetailsBloc>().add(
      LoadSurahList(reciter: widget.reciter, moshaf: selectedMoshaf),
    );
    context.read<ReciterDetailsBloc>().add(
      LoadReciterHistory(widget.reciter.id.toString()),
    );
    getIt<AnalyticsService>().logScreenView(
      widget.reciter.name,
      screenClass: AnalyticsParams.reciterDetailsScreen,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool shouldShow = _scrollController.offset > 400;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    _scrollController.animateTo(
      0,
      duration: context.tokens.durationMedium,
      curve: context.tokens.curveEmphasized,
    );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<ReciterDetailsBloc>();
    final moshaf =
        bloc.state.selectedMoshaf ??
        (widget.reciter.moshaf.isNotEmpty ? widget.reciter.moshaf.first : null);
    if (moshaf == null) return;

    final completer = Completer<void>();
    late final StreamSubscription<ReciterDetailsState> subscription;
    subscription = bloc.stream.listen((state) {
      if (state.status == ReciterDetailsStatus.loaded ||
          state.status == ReciterDetailsStatus.error) {
        subscription.cancel();
        completer.complete();
      }
    });

    bloc.add(LoadSurahList(reciter: widget.reciter, moshaf: moshaf));
    bloc.add(LoadReciterHistory(widget.reciter.id.toString()));
    await completer.future;
  }

  void _scrollToPlayingSurah(List<SurahEntity> surahs) {
    final audioBloc = context.read<AudioPlayerBloc>();
    final currentAudio = audioBloc.state.currentAudio;
    if (currentAudio == null || !audioBloc.state.shouldShowBottomPlayer) return;

    final int playingIndex = surahs.indexWhere(
      (s) => s.id == currentAudio.id || s.audio.url == currentAudio.url,
    );
    if (playingIndex < 0) return;

    final bool isGrid =
        context.read<ReciterDetailsBloc>().state.viewMode ==
        ReciterViewMode.grid;

    // If the item is already built, scroll directly.
    if (_playingSurahKey.currentContext != null) {
      _ensureVisibleForKey(_playingSurahKey);
      return;
    }

    // Step 1: Jump approximately so the lazy builder creates the item.
    const double approxHeaderHeight = 300.0;
    double itemOffset = 0.0;
    final tokens = context.tokens;
    if (isGrid) {
      final double itemHeight = _reciterGridMainAxisExtent(context);
      final int row = playingIndex ~/ _reciterGridColumnCount(context);
      itemOffset = row * (itemHeight + tokens.spaceSmall);
    } else {
      final double tileHeight = tokens.iconBadgeSize + tokens.spaceLarge * 2;
      itemOffset = playingIndex * (tileHeight + tokens.spaceExtraSmall);
    }

    final double approxOffset = approxHeaderHeight + itemOffset;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(approxOffset.clamp(0.0, maxScroll));

    // Step 2: After the frame, the item is now built with its GlobalKey.
    // Use ensureVisible for pixel-perfect positioning.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_playingSurahKey.currentContext != null) {
        _ensureVisibleForKey(_playingSurahKey);
      }
    });
  }

  /// Scrolls so [key]'s widget is visible at ~30% from the top,
  /// which places it comfortably below pinned headers.
  void _ensureVisibleForKey(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: context.tokens.durationFast,
      curve: context.tokens.curveEmphasized,
      alignment: 0.0,
    );
  }

  void _schedulePlaybackTour() {
    if (_playbackTourAttempted) {
      return;
    }
    _playbackTourAttempted = true;
    final Duration tourDelay = context.tokens.durationSlow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(tourDelay, () {
        if (!mounted) {
          return;
        }
        final bool showPlayer = context
            .read<AudioPlayerBloc>()
            .state
            .shouldShowBottomPlayer;
        if (!showPlayer) {
          _playbackTourAttempted = false;
          return;
        }
        unawaited(
          getIt<RecitersTourLauncher>().maybeShowPlaybackTour(context),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    // Rebuild FAB offset when shell chrome or mini-player visibility changes.
    context.watch<QuranPlayerChromeNotifier>();
    context.select(
      (AudioPlayerBloc bloc) => (
        bloc.state.shouldShowBottomPlayer,
        bloc.state.currentAudio?.id,
      ),
    );

    final ReciterDetailsFabLayout layout = ReciterDetailsFabLayout.resolve(
      context,
      scrollToTopFabVisible: _showScrollToTop,
    );

    return Stack(
      children: [
        TilawaShellChildScaffold(
          // Scroll-to-top uses [AnimatedSlide]/[AnimatedOpacity]; disable the
          // scaffold scaling animator so rebuilds do not shrink the FAB.
          floatingActionButtonAnimator:
              FloatingActionButtonAnimator.noAnimation,
          floatingActionButton: AnimatedSlide(
            offset: layout.showScrollToTopFab
                ? Offset.zero
                : const Offset(0, 2),
            duration: tokens.durationFast,
            child: IgnorePointer(
              ignoring: !layout.showScrollToTopFab,
              child: AnimatedOpacity(
                opacity: layout.showScrollToTopFab ? 1.0 : 0.0,
                duration: tokens.durationFast,
                child: FloatingActionButton.small(
                  // Unique tag so this scroll-to-top FAB never shares the
                  // default Hero tag with another route's FAB during
                  // transitions.
                  heroTag: 'reciter_details_scroll_top_fab',
                  onPressed: _scrollToTop,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: TilawaFabLocation.placement(
            TilawaFabPlacement.end,
            bottomOffset: layout.fabBottomOffset,
          ),
          body: TilawaContentBounds(
            kind: TilawaContentKind.media,
            child: BlocConsumer<ReciterDetailsBloc, ReciterDetailsState>(
              listenWhen: (previous, current) =>
                  (previous.searchQuery != current.searchQuery &&
                      current.searchQuery.isEmpty) ||
                  (current.playCommand != null &&
                      previous.playCommand != current.playCommand) ||
                  (previous.status != current.status &&
                      current.status == ReciterDetailsStatus.loaded) ||
                  previous.viewMode != current.viewMode,
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.viewMode != current.viewMode ||
                  previous.filteredSurahs != current.filteredSurahs ||
                  previous.searchQuery != current.searchQuery ||
                  previous.listeningHistory != current.listeningHistory ||
                  previous.selectedMoshaf != current.selectedMoshaf,
              listener: (context, state) {
                if (state.searchQuery.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  _searchController.clear();
                }

                // Scroll to playing surah when switching list ↔ grid
                if (state.viewMode != _lastViewMode) {
                  _lastViewMode = state.viewMode;
                  if (_scrollController.hasClients) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToPlayingSurah(state.filteredSurahs);
                    });
                  }
                }

                final PlaySurahCommand? command = state.playCommand;
                if (command != null) {
                  context.read<AudioPlayerBloc>().add(
                    AudioPlayerEvent.playFromQueue(
                      command.playlist,
                      command.initialIndex,
                    ),
                  );
                  _schedulePlaybackTour();
                }

                if (state.status == ReciterDetailsStatus.loaded) {
                  context.read<ReciterDownloadBloc>().add(
                    InitializeReciterDownload(
                      reciterName: widget.reciter.name,
                      totalSurahs: state.surahList.length,
                      downloadedSurahIds: state.surahList
                          .where((s) => s.isDownloaded)
                          .map((s) => s.id)
                          .toList(),
                    ),
                  );

                  // Auto-scroll to playing surah only on first load
                  if (!_hasScrolledToPlaying) {
                    _hasScrolledToPlaying = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollToPlayingSurah(state.filteredSurahs);
                      }
                    });
                  }
                }
              },
              builder: (context, state) {
                return TilawaRefreshIndicator(
                  onRefresh: _onRefresh,
                  edgeOffset: reciterDetailsRefreshIndicatorEdgeOffset(
                    context,
                  ),
                  child: CustomScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    restorationId: 'reciter_details_scroll_view',
                    slivers: [
                      ReciterDetailsAppBar(
                        reciter: widget.reciter,
                        searchController: _searchController,
                      ),

                      // Continue Listening chips
                      if (state.listeningHistory.isNotEmpty &&
                          state.searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: tokens.spaceSmall,
                              bottom: tokens.spaceExtraSmall,
                            ),
                            child: ReciterHistorySection(
                              historyList: state.listeningHistory,
                              onPlay: (history) =>
                                  _onPlayHistory(context, state, history),
                            ),
                          ),
                        ),

                      // Moshaf selector (only if multiple)
                      if (widget.reciter.moshaf.length > 1 &&
                          state.searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: MoshafSelector(
                            reciter: widget.reciter,
                            state: state,
                          ),
                        ),

                      // Surah header row with count + Download All
                      if (state.status == ReciterDetailsStatus.loaded &&
                          state.surahList.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _SurahHeaderRow(
                            count: state.filteredSurahs.length,
                            reciter: widget.reciter,
                            surahs: state.surahList,
                            showDownload: state.searchQuery.isEmpty,
                          ),
                        ),

                      // Animated content switcher
                      _ReciterDetailsContent(
                        reciter: widget.reciter,
                        state: state,
                        listBottomPadding: layout.listBottomPadding,
                        playingSurahKey: _playingSurahKey,
                        onClearSearch: () {
                          context.read<ReciterDetailsBloc>().add(
                            const FilterSurahs(''),
                          );
                        },
                        onPlaySurah: (surah) {
                          HapticFeedback.lightImpact();
                          context.read<ReciterDetailsBloc>().add(
                            PlaySurahRequested(surah),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _onPlayHistory(
    BuildContext context,
    ReciterDetailsState state,
    dynamic history,
  ) {
    HapticFeedback.lightImpact();
    final int surahIdx = state.surahList.indexWhere((s) {
      final String? surahId = s.audio.extras.getString(AudioExtrasKeys.surahId);
      return surahId != null && surahId == history.surahId.toString();
    });

    if (surahIdx >= 0) {
      context.read<ReciterDetailsBloc>().add(
        PlaySurahRequested(state.surahList[surahIdx]),
      );
    }
  }
}

/// Section heading with the result count and its supporting bulk action.
class _SurahHeaderRow extends StatelessWidget {
  const _SurahHeaderRow({
    required this.count,
    required this.reciter,
    required this.surahs,
    required this.showDownload,
  });

  final int count;
  final ReciterEntity reciter;
  final List<SurahEntity> surahs;
  final bool showDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Expanded(
            child: TilawaSectionTitle(
              title: '${context.l10n.surahs} ($count)',
            ),
          ),
          if (showDownload) DownloadAllButton(reciter: reciter, surahs: surahs),
        ],
      ),
    );
  }
}

class _ReciterDetailsContent extends StatelessWidget {
  const _ReciterDetailsContent({
    required this.reciter,
    required this.state,
    required this.listBottomPadding,
    required this.onPlaySurah,
    required this.playingSurahKey,
    required this.onClearSearch,
  });
  final ReciterEntity reciter;
  final ReciterDetailsState state;
  final double listBottomPadding;
  final ValueChanged<SurahEntity> onPlaySurah;
  final GlobalKey playingSurahKey;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final double bottomPadding = listBottomPadding;
    final currentAudio = context.select(
      (AudioPlayerBloc bloc) => bloc.state.currentAudio,
    );

    void retry() {
      if (reciter.moshaf.isEmpty) return;
      context.read<ReciterDetailsBloc>().add(
        LoadSurahList(reciter: reciter, moshaf: reciter.moshaf.first),
      );
    }

    switch (state.status) {
      case ReciterDetailsStatus.error:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: TilawaErrorState(
            icon: Icons.cloud_off_rounded,
            title: state.errorMessage ?? context.l10n.anErrorOccurred,
            retryLabel: context.l10n.retry,
            onRetry: retry,
          ),
        );
      case ReciterDetailsStatus.loaded:
        if (state.surahList.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: TilawaEmptyState(
              icon: Icons.library_music_outlined,
              title: context.l10n.noSurahsAvailable,
              action: TilawaButton(
                text: context.l10n.retry,
                leadingIcon: const Icon(Icons.refresh_rounded),
                onPressed: retry,
              ),
            ),
          );
        }

        final List<SurahEntity> filteredSurahs = state.filteredSurahs;
        if (filteredSurahs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: TilawaEmptyState(
              icon: Icons.search_off_rounded,
              title: context.l10n.noSurahsMatchSearch,
              action: TilawaButton(
                text: context.l10n.reset,
                leadingIcon: const Icon(Icons.close_rounded),
                onPressed: onClearSearch,
              ),
            ),
          );
        }

        if (state.viewMode == ReciterViewMode.grid) {
          return SliverPadding(
            padding: EdgeInsets.only(
              top: tokens.spaceExtraSmall,
              bottom: bottomPadding,
            ),
            sliver: SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _reciterGridColumnCount(context),
                  mainAxisSpacing: tokens.spaceSmall,
                  crossAxisSpacing: tokens.spaceSmall,
                  mainAxisExtent: _reciterGridMainAxisExtent(context),
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final SurahEntity surah = filteredSurahs[index];
                  final ReciterSurahListItem item =
                      ReciterSurahListItem.fromSurahEntity(
                        surah,
                        reciterId: reciter.id,
                        reciterName: reciter.name,
                        listIndex: index,
                      );
                  final bool isPlaying =
                      currentAudio?.id == item.audioId ||
                      (currentAudio != null &&
                          currentAudio.url == item.audioUrl);
                  final key = isPlaying ? playingSurahKey : null;
                  final Widget gridItem = SurahGridItem(
                    key: key,
                    item: item,
                    onTap: () => onPlaySurah(surah),
                  );
                  if (isPlaying) {
                    return TourTarget(
                      targetId: RecitersTourTargets.playingSurah,
                      child: gridItem,
                    );
                  }
                  return gridItem;
                }, childCount: filteredSurahs.length),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.only(
            top: tokens.spaceExtraSmall,
            bottom: bottomPadding,
          ),
          sliver: SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final SurahEntity surah = filteredSurahs[index];
                final ReciterSurahListItem item =
                    ReciterSurahListItem.fromSurahEntity(
                      surah,
                      reciterId: reciter.id,
                      reciterName: reciter.name,
                      listIndex: index,
                    );
                final bool isPlaying =
                    currentAudio?.id == item.audioId ||
                    (currentAudio != null && currentAudio.url == item.audioUrl);
                final key = isPlaying ? playingSurahKey : null;
                final Widget tile = Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: tokens.spaceTiny,
                  ),
                  child: SurahListTile(
                    key: key,
                    item: item,
                    onTap: () => onPlaySurah(surah),
                  ),
                );
                if (isPlaying) {
                  return TourTarget(
                    targetId: RecitersTourTargets.playingSurah,
                    child: tile,
                  );
                }
                return tile;
              }, childCount: filteredSurahs.length),
            ),
          ),
        );
      case ReciterDetailsStatus.initial:
      case ReciterDetailsStatus.loading:
        return SliverPadding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          sliver: const _ReciterDetailsLoadingSliver(),
        );
    }
  }
}

int _reciterGridColumnCount(BuildContext context) {
  return switch (context.windowSize) {
    TilawaWindowSize.narrow => 2,
    TilawaWindowSize.medium => 3,
    TilawaWindowSize.expanded || TilawaWindowSize.large => 4,
  };
}

double _reciterGridMainAxisExtent(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final MeMuslimDesignTokens tokens = theme.tokens;
  final TextStyle titleStyle = theme.textTheme.titleSmall!.copyWith(
    height: 1.2,
  );
  final double titleHeight = MediaQuery.textScalerOf(
    context,
  ).scale(titleStyle.fontSize! * titleStyle.height! * 2);

  return tokens.iconBadgeSize +
      tokens.spaceSmall +
      titleHeight +
      tokens.spaceMedium * 2;
}

class _ReciterDetailsLoadingSliver extends StatelessWidget {
  const _ReciterDetailsLoadingSliver();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLarge,
          vertical: tokens.spaceSmall,
        ),
        child: TilawaSkeleton(
          semanticLabel: context.l10n.loading,
          child: Column(
            spacing: tokens.spaceExtraSmall,
            children: const <Widget>[
              _ReciterDetailsSkeletonTile(),
              _ReciterDetailsSkeletonTile(),
              _ReciterDetailsSkeletonTile(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReciterDetailsSkeletonTile extends StatelessWidget {
  const _ReciterDetailsSkeletonTile();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return TilawaCard(
      surface: TilawaCardSurface.flat,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      borderColor: theme.colorScheme.surfaceContainerLowest,
      borderRadius: tokens.radiusMedium,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        spacing: tokens.spaceMedium,
        children: [
          SizedBox(
            width: tokens.iconBadgeSize,
            child: Center(
              child: TilawaSkeletonLine(
                width: tokens.iconSizeSmall,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: Column(
              spacing: tokens.spaceExtraSmall,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TilawaSkeletonLine(style: theme.textTheme.titleSmall),
                TilawaSkeletonLine(
                  width: tokens.contentMaxWidthForm / 4,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TilawaSkeletonBone.circle(dimension: tokens.minInteractiveDimension),
        ],
      ),
    );
  }
}
