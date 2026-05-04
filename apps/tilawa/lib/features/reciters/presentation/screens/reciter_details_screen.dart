import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/quran_player_widget.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../bloc/reciter_details_bloc.dart';
import '../bloc/reciter_download_bloc.dart';
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<ReciterDetailsBloc>();
    final moshaf =
        bloc.state.selectedMoshaf ??
        (widget.reciter.moshaf.isNotEmpty ? widget.reciter.moshaf.first : null);
    if (moshaf == null) return;
    bloc.add(LoadSurahList(reciter: widget.reciter, moshaf: moshaf));
    bloc.add(LoadReciterHistory(widget.reciter.id.toString()));
    await Future<void>.delayed(const Duration(milliseconds: 800));
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
    final double approxHeaderHeight = 300.0;
    double itemOffset = 0.0;
    if (isGrid) {
      final int row = playingIndex ~/ 2;
      final double contentWidth = context.resolveContentWidth(
        TilawaContentKind.media,
      );
      final double itemHeight = ((contentWidth - 32.0 - 12.0) / 2.0) / 0.99;
      itemOffset = row * (itemHeight + 12.0);
    } else {
      itemOffset = playingIndex * 88.0;
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final double bottomPlayerOffset = MediaQuery.viewPaddingOf(context).bottom;
    final bool showBottomPlayer = context.select((AudioPlayerBloc bloc) {
      final AudioPlayerState state = bloc.state;
      return state.shouldShowBottomPlayer && state.currentAudio != null;
    });

    return Stack(
      children: [
        Scaffold(
          // Scroll-to-top FAB
          floatingActionButton: AnimatedSlide(
            offset: _showScrollToTop ? Offset.zero : const Offset(0, 2),
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showScrollToTop,
              child: AnimatedOpacity(
                opacity: _showScrollToTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.9),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: showBottomPlayer
              ? _CustomFloatingActionButtonLocation(
                  offset:
                      QuranPlayerWidget.collapsedHeight(context) +
                      bottomPlayerOffset +
                      tokens.spaceExtraLarge,
                )
              : FloatingActionButtonLocation.endFloat,
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
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  edgeOffset: kToolbarHeight + 64,
                  child: CustomScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    restorationId: 'reciter_details_scroll_view',
                    slivers: [
                      ReciterDetailsAppBar(reciter: widget.reciter),
                      ReciterSearchHeader(controller: _searchController),

                      // Continue Listening chips
                      if (state.listeningHistory.isNotEmpty &&
                          state.searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 4),
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
                        bottomPlayerOffset: bottomPlayerOffset,
                        showBottomPlayer: showBottomPlayer,
                        playingSurahKey: _playingSurahKey,
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
        if (showBottomPlayer) Positioned.fill(child: QuranPlayerWidget()),
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
      final id = s.audio.extras?['surahId'];
      return id != null && id.toString() == history.surahId.toString();
    });

    if (surahIdx >= 0) {
      context.read<ReciterDetailsBloc>().add(
        PlaySurahRequested(state.surahList[surahIdx]),
      );
    }
  }
}

/// Row containing "Surahs (count)" on the left and the Download All
/// button on the right. Keeps everything compact in one line.
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${context.l10n.surahs} ($count)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
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
    required this.bottomPlayerOffset,
    required this.showBottomPlayer,
    required this.onPlaySurah,
    required this.playingSurahKey,
  });
  final ReciterEntity reciter;
  final ReciterDetailsState state;
  final double bottomPlayerOffset;
  final bool showBottomPlayer;
  final Function(SurahEntity) onPlaySurah;
  final GlobalKey playingSurahKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final double bottomPadding =
        bottomPlayerOffset +
        (showBottomPlayer
            ? QuranPlayerWidget.collapsedHeight(context) +
                  tokens.spaceExtraLarge
            : tokens.spaceExtraLarge);
    final double emptyStateIconSize =
        tokens.iconSizeExtraLarge + tokens.iconSizeSmall;
    final currentAudio = context.select(
      (AudioPlayerBloc bloc) => bloc.state.currentAudio,
    );
    switch (state.status) {
      case ReciterDetailsStatus.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: emptyStateIconSize,
                  color: theme.colorScheme.error,
                ),
                SizedBox(height: tokens.spaceLarge),
                Text(
                  state.errorMessage ?? context.l10n.anErrorOccurred,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.spaceLarge),
                ElevatedButton.icon(
                  onPressed: () {
                    if (reciter.moshaf.isNotEmpty) {
                      context.read<ReciterDetailsBloc>().add(
                        LoadSurahList(
                          reciter: reciter,
                          moshaf: reciter.moshaf.first,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.retry),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceExtraLarge,
                      vertical: tokens.spaceMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case ReciterDetailsStatus.loaded:
        if (state.surahList.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off_rounded,
                    size: emptyStateIconSize,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Text(
                    context.l10n.noSurahsAvailable,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<SurahEntity> filteredSurahs = state.filteredSurahs;
        if (filteredSurahs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: emptyStateIconSize,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: tokens.spaceLarge),
                  Text(
                    context.l10n.noSurahsMatchSearch,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.viewMode == ReciterViewMode.grid) {
          return SliverPadding(
            padding: EdgeInsets.only(
              top: tokens.spaceExtraSmall,
              left: tokens.spaceLarge,
              right: tokens.spaceLarge,
              bottom: bottomPadding,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: tokens.cardCompactWidthThreshold,
                mainAxisSpacing: tokens.spaceMedium,
                crossAxisSpacing: tokens.spaceMedium,
                mainAxisExtent: tokens.cardCompactHeightThreshold,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final SurahEntity surah = filteredSurahs[index];
                final bool isPlaying =
                    currentAudio?.id == surah.id ||
                    (currentAudio != null &&
                        currentAudio.url == surah.audio.url);
                final key = isPlaying ? playingSurahKey : null;
                return SurahGridItem(
                  key: key,
                  surah: surah,
                  index: index,
                  reciterName: reciter.name,
                  reciterId: reciter.id,
                  onTap: () => onPlaySurah(surah),
                );
              }, childCount: filteredSurahs.length),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.only(
            top: tokens.spaceExtraSmall,
            left: tokens.spaceLarge,
            right: tokens.spaceLarge,
            bottom: bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final SurahEntity surah = filteredSurahs[index];
              final bool isPlaying =
                  currentAudio?.id == surah.id ||
                  (currentAudio != null && currentAudio.url == surah.audio.url);
              final key = isPlaying ? playingSurahKey : null;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
                child: SurahListTile(
                  key: key,
                  surah: surah,
                  index: index,
                  reciterName: reciter.name,
                  reciterId: reciter.id,
                  onTap: () => onPlaySurah(surah),
                ),
              );
            }, childCount: filteredSurahs.length),
          ),
        );
      case ReciterDetailsStatus.initial:
      case ReciterDetailsStatus.loading:
        return SliverPadding(
          padding: EdgeInsets.only(
            top: tokens.spaceLarge,
            left: tokens.spaceLarge,
            right: tokens.spaceLarge,
            bottom: bottomPadding,
          ),
          sliver: SliverSkeletonizer(
            child: state.viewMode == ReciterViewMode.grid
                ? SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: tokens.cardCompactWidthThreshold,
                      mainAxisSpacing: tokens.spaceMedium,
                      crossAxisSpacing: tokens.spaceMedium,
                      mainAxisExtent: tokens.cardCompactHeightThreshold,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            tokens.radiusLarge,
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                      childCount: 8,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const SkeletonSurahListTile(),
                      childCount: 8,
                    ),
                  ),
          ),
        );
    }
  }
}

class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _CustomFloatingActionButtonLocation({required this.offset});
  final double offset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Default miniEndFloat style position
    final double x =
        scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16;
    final double y =
        scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        offset;

    return Offset(x, y);
  }
}
