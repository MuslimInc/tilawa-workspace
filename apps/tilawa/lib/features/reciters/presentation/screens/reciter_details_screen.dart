import 'package:flutter/material.dart';
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
    // Log screen view with reciter name
    getIt<AnalyticsService>().logScreenView(
      widget.reciter.name,
      screenClass: AnalyticsParams.reciterDetailsScreen,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      current.status == ReciterDetailsStatus.loaded),
              listener: (context, state) {
                // Handle search clear
                if (state.searchQuery.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  _searchController.clear();
                }

                // Handle playback command from Bloc
                final PlaySurahCommand? command = state.playCommand;
                if (command != null) {
                  context.read<AudioPlayerBloc>().add(
                    AudioPlayerEvent.playFromQueue(
                      command.playlist,
                      command.initialIndex,
                    ),
                  );
                }

                // Initialize ReciterDownloadBloc when surah list is loaded
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
                }
              },
              builder: (context, state) {
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    restorationId: 'reciter_details_scroll_view',
                    slivers: [
                      ReciterDetailsAppBar(reciter: widget.reciter),
                      ReciterSearchHeader(controller: _searchController),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (widget.reciter.moshaf.length > 1)
                              MoshafSelector(
                                reciter: widget.reciter,
                                state: state,
                              ),
                            if (state.status == ReciterDetailsStatus.loaded &&
                                state.surahList.isNotEmpty &&
                                state.searchQuery.isEmpty) ...[
                              SizedBox(height: 16.h),
                              DownloadAllButton(
                                reciter: widget.reciter,
                                surahs: state.surahList,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (state.listeningHistory.isNotEmpty &&
                          state.searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 24.h),
                            child: ReciterHistorySection(
                              historyList: state.listeningHistory,
                              onPlay: (history) {
                                // Find matching surah in list if available to play
                                // SurahEntity.id corresponds to AudioEntity.id which is the URL
                                // We need to match by actual surah ID (number)
                                final surah = state.surahList.firstWhere(
                                  (s) {
                                    final id = s.audio.extras?['surahId'];
                                    return id != null &&
                                        id.toString() ==
                                            history.surahId.toString();
                                  },
                                  orElse: () => SurahEntity(
                                    audio: AudioEntity(
                                      id: history
                                          .audioUrl, // Use URL as ID to match AudioPlayer handling
                                      url: history.audioUrl,
                                      title: history.surahName,
                                      artist: history.reciterName,
                                      duration: Duration(
                                        milliseconds: history.durationMs,
                                      ),
                                      extras: {
                                        'reciterId': history.reciterId,
                                        'moshafId': history.moshafId,
                                        'surahId': history.surahId,
                                        'url': history.audioUrl,
                                      },
                                    ),
                                    isDownloaded:
                                        false, // Cannot know without lookup
                                    downloadProgress: 0,
                                  ),
                                );

                                context.read<ReciterDetailsBloc>().add(
                                  PlaySurahRequested(surah),
                                );
                              },
                            ),
                          ),
                        ),

                      _ReciterDetailsContent(
                        reciter: widget.reciter,
                        state: state,
                        onPlaySurah: (surah) {
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
          // Bottom player positioned at the bottom
          const BottomPlayerWidget(),
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
  });
  final ReciterEntity reciter;
  final ReciterDetailsState state;
  final Function(SurahEntity) onPlaySurah;

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
              top: 16.h,
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
                return SurahGridItem(
                  key: ValueKey('surah_grid_${surah.id}'),
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
            top: 16.h,
            left: 16.w,
            right: 16.w,
            bottom: bottomPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final SurahEntity surah = filteredSurahs[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: SurahListTile(
                  key: ValueKey('surah_${surah.id}'),
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
