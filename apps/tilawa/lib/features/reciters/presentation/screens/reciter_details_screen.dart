import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../../../shared/widgets/bottom_player_widget.dart';
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
  final Map<String, GlobalKey> _surahKeys = {};
  bool _showScrollToTop = false;
  bool _hasScrolledToPlaying = false;
  ReciterViewMode _lastViewMode = ReciterViewMode.list;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ReciterDetailsBloc>().state.searchQuery,
    );
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
    final moshaf = bloc.state.selectedMoshaf ?? widget.reciter.moshaf.first;
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

    final surah = surahs[playingIndex];

    // Ensure a GlobalKey exists for this surah.
    final key = _surahKeys.putIfAbsent(surah.id, GlobalKey.new);

    // If the item is already built, scroll directly.
    if (key.currentContext != null) {
      _ensureVisibleForKey(key);
      return;
    }

    // Step 1: Jump approximately so the lazy builder creates the item.
    // Rough estimate of headers (~300) + item position.
    // Only needs to be "close enough" — Step 2 handles precision.
    final double approxHeaderHeight = 300.0;
    final double approxOffset = approxHeaderHeight + (playingIndex * 88.0);
    final double maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(approxOffset.clamp(0.0, maxScroll));

    // Step 2: After the frame, the item is now built with its GlobalKey.
    // Use ensureVisible for pixel-perfect positioning.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        _ensureVisibleForKey(key);
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
    return Scaffold(
      // Scroll-to-top FAB
      floatingActionButton: AnimatedSlide(
        offset: _showScrollToTop ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 250),
        child: AnimatedOpacity(
          opacity: _showScrollToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton.small(
            onPressed: _scrollToTop,
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.9),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ReciterDetailsBloc, ReciterDetailsState>(
              listenWhen: (previous, current) =>
                  (previous.searchQuery != current.searchQuery &&
                      current.searchQuery.isEmpty) ||
                  (current.playCommand != null &&
                      previous.playCommand != current.playCommand) ||
                  (previous.status != current.status &&
                      current.status == ReciterDetailsStatus.loaded) ||
                  previous.viewMode != current.viewMode,
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
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    edgeOffset: kToolbarHeight + 64.h,
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
                              padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
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
                          surahKeys: _surahKeys,
                          onPlaySurah: (surah) {
                            HapticFeedback.lightImpact();
                            context.read<ReciterDetailsBloc>().add(
                              PlaySurahRequested(surah),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const BottomPlayerWidget(),
        ],
      ),
    );
  }

  void _onPlayHistory(
    BuildContext context,
    ReciterDetailsState state,
    dynamic history,
  ) {
    HapticFeedback.lightImpact();
    final surah = state.surahList.firstWhere(
      (s) {
        final id = s.audio.extras?['surahId'];
        return id != null && id.toString() == history.surahId.toString();
      },
      orElse: () => SurahEntity(
        audio: AudioEntity(
          id: history.audioUrl,
          url: history.audioUrl,
          title: history.surahName,
          artist: history.reciterName,
          duration: Duration(milliseconds: history.durationMs),
          extras: {
            'reciterId': history.reciterId,
            'moshafId': history.moshafId,
            'surahId': history.surahId,
            'url': history.audioUrl,
          },
        ),
        isDownloaded: false,
        downloadProgress: 0,
      ),
    );

    context.read<ReciterDetailsBloc>().add(PlaySurahRequested(surah));
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Text(
            '${context.l10n.surahs} ($count)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
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
    required this.onPlaySurah,
    required this.surahKeys,
  });
  final ReciterEntity reciter;
  final ReciterDetailsState state;
  final Function(SurahEntity) onPlaySurah;
  final Map<String, GlobalKey> surahKeys;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomPadding = 20.h + MediaQuery.paddingOf(context).bottom;
    switch (state.status) {
      case ReciterDetailsStatus.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64.sp,
                  color: theme.colorScheme.error,
                ),
                SizedBox(height: 16.h),
                Text(
                  state.errorMessage ?? context.l10n.anErrorOccurred,
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ReciterDetailsBloc>().add(
                      LoadSurahList(
                        reciter: reciter,
                        moshaf: reciter.moshaf.first,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.retry),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
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
                    size: 64.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.l10n.noSurahsAvailable,
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
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
                    size: 64.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.l10n.noSurahsMatchSearch,
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.viewMode == ReciterViewMode.grid) {
          return SliverPadding(
            padding: EdgeInsets.only(
              top: 4.h,
              left: 16.w,
              right: 16.w,
              bottom: bottomPadding,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.99,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final SurahEntity surah = filteredSurahs[index];
                final key = surahKeys.putIfAbsent(surah.id, GlobalKey.new);
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
            top: 4.h,
            left: 16.w,
            right: 16.w,
            bottom: bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final SurahEntity surah = filteredSurahs[index];
              final key = surahKeys.putIfAbsent(surah.id, GlobalKey.new);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
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
            top: 16.h,
            left: 16.w,
            right: 16.w,
            bottom: bottomPadding,
          ),
          sliver: SliverSkeletonizer(
            child: SliverList(
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
