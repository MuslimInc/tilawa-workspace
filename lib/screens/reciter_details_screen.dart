import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/di/injection.dart';
import '../core/entities/moshaf_entity.dart';
import '../core/entities/reciter_entity.dart';
import '../core/extensions.dart';
import '../core/utils/toast_utils.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/downloads/domain/entities/download_item.dart';
import '../features/downloads/domain/repositories/downloads_repository.dart';
import '../features/downloads/presentation/widgets/download_button.dart';
import '../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../features/surah/domain/entities/surah_entity.dart';
import '../main.dart';
import '../shared/widgets/bottom_player_widget.dart';

class ReciterDetailsScreen extends StatefulWidget {
  const ReciterDetailsScreen({super.key, required this.reciter});
  final ReciterEntity reciter;

  @override
  State<ReciterDetailsScreen> createState() => _ReciterDetailsScreenState();
}

class _ReciterDetailsScreenState extends State<ReciterDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final MoshafEntity selectedMoshaf = widget.reciter.moshaf.first;
    context.read<ReciterDetailsBloc>().add(
      LoadSurahList(reciter: widget.reciter, moshaf: selectedMoshaf),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Note: DownloadButton gets its state directly from DownloadsBloc,
    // so no need to listen to DownloadsBloc here and update surah list
    return Scaffold(
      body: BlocBuilder<ReciterDetailsBloc, ReciterDetailsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              if (widget.reciter.moshaf.length > 1)
                SliverToBoxAdapter(child: _buildMoshafSelector(context, state)),
              _buildContent(context, state),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomPlayerWidget(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      stretch: true,
      title: Text(
        widget.reciter.name,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: -50.w,
                bottom: -50.h,
                child: Icon(
                  Icons.mic_external_on,
                  size: 200.sp,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black45],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoshafSelector(BuildContext context, ReciterDetailsState state) {
    // Remove duplicates and get unique moshaf list
    final List<MoshafEntity> uniqueMoshaf = widget.reciter.moshaf
        .toSet()
        .toList();
    final MoshafEntity selectedMoshaf =
        state.selectedMoshaf ?? uniqueMoshaf.first;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        child: ButtonTheme(
          alignedDropdown: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MoshafEntity>(
              isExpanded: true,
              dropdownColor: theme.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              alignment: AlignmentDirectional.center,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 24.sp),
              value: uniqueMoshaf.contains(selectedMoshaf)
                  ? selectedMoshaf
                  : uniqueMoshaf.first,
              style: theme.textTheme.bodyMedium,
              items: uniqueMoshaf.map((moshaf) {
                return DropdownMenuItem<MoshafEntity>(
                  value: moshaf,
                  child: Text(moshaf.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (MoshafEntity? moshaf) {
                if (moshaf != null) {
                  context.read<ReciterDetailsBloc>().add(
                    LoadSurahList(reciter: widget.reciter, moshaf: moshaf),
                  );
                }
              },
            ),
          ),
        ),
      ), // End Material
    );
  }

  Widget _buildContent(BuildContext context, ReciterDetailsState state) {
    final ThemeData theme = Theme.of(context);
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
                        reciter: widget.reciter,
                        moshaf: widget.reciter.moshaf.first,
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
                    Icons.search_off_rounded,
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
        // Removed wrapping BlocBuilder<AudioPlayerBloc> to prevent list-wide rebuilds
        return SliverPadding(
          padding: EdgeInsets.only(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            bottom: 30.h, // Space for bottom player
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final SurahEntity surah = state.surahList[index];
              return _SurahCard(
                key: ValueKey('surah_${surah.id}'),
                surah: surah,
                index: index,
                reciterName: widget.reciter.name,
                onTap: () => _playSurah(surah, state),
              );
            }, childCount: state.surahList.length),
          ),
        );
      case ReciterDetailsStatus.initial:
      case ReciterDetailsStatus.loading:
        // Loading state - show skeleton
        return SliverPadding(
          padding: EdgeInsets.only(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            bottom: 30.h,
          ),
          sliver: SliverSkeletonizer(
            child: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSkeletonSurahCard(),
                childCount: 10, // Show 10 skeleton items
              ),
            ),
          ),
        );
    }
  }

  Widget _buildSkeletonSurahCard() {
    final ThemeData theme = Theme.of(context);
    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Circle placeholder for index
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Text placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surah Name Placeholder',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Reciter Name',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Button placeholders
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.download_outlined,
                      color: Colors.grey,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.grey,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if a surah is downloaded and get its file path
  Future<String?> _getDownloadedFilePath(SurahEntity surah) async {
    try {
      final DownloadsRepository downloadsRepository =
          getIt<DownloadsRepository>();
      // Use surah.id which contains the download URL
      final String? filePath = await downloadsRepository.getDownloadedFilePath(
        surah.id,
        widget.reciter.name,
      );

      if (filePath != null) {
        // Validate that the file actually exists
        final file = File(filePath);
        if (file.existsSync()) {
          logger.d('_getDownloadedFilePath: file exists at $filePath');
          return filePath;
        } else {
          logger.d('_getDownloadedFilePath: file does not exist at $filePath');
          return null;
        }
      }

      return null;
    } catch (e) {
      logger.d('Error checking downloaded file: $e');
      return null;
    }
  }

  /// Create a MediaItem with local file path for downloaded surahs
  MediaItem _createLocalMediaItem(SurahEntity originalSurah, String filePath) {
    try {
      // Convert file path to proper file:// URI
      final fileUri = Uri.file(filePath).toString();

      logger.d('_createLocalMediaItem: original file path: $filePath');
      logger.d('_createLocalMediaItem: file URI: $fileUri');

      return MediaItem(
        id: fileUri, // Use file URI as ID for local files
        title: originalSurah.name,
        artist: originalSurah.reciterName,
        album: originalSurah.reciterName,
        duration: originalSurah.mediaItem.duration,
        artUri: originalSurah.mediaItem.artUri,
        extras: {
          ...?originalSurah.mediaItem.extras,
          'isDownloaded': true,
          'originalId': originalSurah.id, // Keep original ID for reference
          'localFilePath': filePath, // Keep original file path for reference
        },
      );
    } catch (e) {
      logger.d('_createLocalMediaItem error: $e');
      logger.d('_createLocalMediaItem: falling back to original surah');
      // Fallback to original surah if file URI creation fails
      return originalSurah.mediaItem;
    }
  }

  Future<void> _playSurah(SurahEntity surah, ReciterDetailsState state) async {
    try {
      // Check if the surah is downloaded
      final String? downloadedFilePath = await _getDownloadedFilePath(surah);

      // Set the selected surah immediately for instant highlighting
      if (mounted) {
        context.read<ReciterDetailsBloc>().add(SelectSurah(surah.id));
      }

      // Validate surah data
      if (surah.id.isEmpty) {
        throw Exception('Invalid surah: missing ID');
      }

      // Find the index of the selected surah in the full list
      final int surahIndex = state.surahList.indexWhere(
        (item) => item.id == surah.id,
      );

      logger.d(
        '_playSurah: selected surah=${surah.name}, index=$surahIndex, total surahs=${state.surahList.length}',
      );
      logger.d('_playSurah: downloaded file path: $downloadedFilePath');

      if (downloadedFilePath != null) {
        final fileUri = Uri.file(downloadedFilePath).toString();
        logger.d('_playSurah: file URI: $fileUri');
      }

      if (surahIndex != -1) {
        // Optimization: Fetch all downloads for this reciter ONCE to avoid N database queries
        final DownloadsRepository downloadsRepository =
            getIt<DownloadsRepository>();
        final List<DownloadItem> reciterDownloads = await downloadsRepository
            .getDownloadsForReciter(widget.reciter.name);

        // Create a map of Surah ID -> File Path for fast lookup
        final Map<String, String> downloadMap = {};
        for (final item in reciterDownloads) {
          if (item.status == DownloadStatus.completed) {
            final file = File(item.filePath);
            if (file.existsSync()) {
              downloadMap[item.url] = item.filePath;
            }
          }
        }

        // Create a list of surahs, using downloaded files when available
        final List<MediaItem> surahListWithDownloads = [];
        for (var i = 0; i < state.surahList.length; i++) {
          final SurahEntity currentSurah = state.surahList[i];
          final String? localPath = downloadMap[currentSurah.id];

          if (localPath != null) {
            surahListWithDownloads.add(
              _createLocalMediaItem(currentSurah, localPath),
            );
          } else {
            surahListWithDownloads.add(currentSurah.mediaItem);
          }
        }

        // Update queue with the surah list (with downloaded files where available)
        logger.d(
          '_playSurah: updating queue with ${surahListWithDownloads.length} surahs',
        );

        if (mounted) {
          context.read<AudioPlayerBloc>().add(
            AudioPlayerEvent.playFromQueue(surahListWithDownloads, surahIndex),
          );
        }
      } else {
        // Fallback: just play the single surah
        logger.d('_playSurah: surah not found in list, playing single surah');
        final MediaItem surahToPlay = downloadedFilePath != null
            ? _createLocalMediaItem(surah, downloadedFilePath)
            : surah.mediaItem;

        if (mounted) {
          context.read<AudioPlayerBloc>().add(
            AudioPlayerEvent.playFromQueue([surahToPlay], 0),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.d('_playSurah error: $e');
      logger.d('Stack trace: $stackTrace');
      if (mounted) {
        ToastUtils.showErrorToast('Error playing surah: $e');
      }
    }
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required super.key,
    required this.surah,
    required this.index,
    required this.reciterName,
    required this.onTap,
  });

  final SurahEntity surah;
  final int index;
  final String reciterName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Select specific values to minimize rebuilds
    final bool isPlaying = context.select<AudioPlayerBloc, bool>((bloc) {
      final MediaItem? currentMediaItem = bloc.state.mediaItem;
      final PlaybackState? playbackState = bloc.state.playbackState;

      final bool isCurrentlyPlaying =
          currentMediaItem?.id == surah.id ||
          currentMediaItem?.extras?['originalId'] == surah.id;

      return isCurrentlyPlaying && (playbackState?.playing ?? false);
    });

    final bool isCurrentItem = context.select<AudioPlayerBloc, bool>((bloc) {
      final MediaItem? currentMediaItem = bloc.state.mediaItem;
      return currentMediaItem?.id == surah.id ||
          currentMediaItem?.extras?['originalId'] == surah.id;
    });

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isCurrentItem
              ? theme.primaryColor.withValues(alpha: 0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: isCurrentItem
              ? Border.all(color: theme.primaryColor.withValues(alpha: 0.3))
              : Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () {
              if (isCurrentItem) {
                if (isPlaying) {
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.pauseAudio(),
                  );
                } else {
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.playAudio(),
                  );
                }
              } else {
                onTap();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: isCurrentItem
                          ? theme.primaryColor
                          : theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCurrentItem
                          ? Icon(
                              Icons.graphic_eq_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isCurrentItem
                                ? theme.primaryColor
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          surah.reciterName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Download Status
                      DownloadButton(
                        url: surah.id,
                        surahTitle: surah.name,
                        reciterName: reciterName,
                        initialIsDownloaded: surah.isDownloaded,
                        initialIsDownloading: surah.isDownloading,
                        initialProgress: surah.downloadProgress,
                      ),

                      SizedBox(width: 12.w),

                      // Play Button Container
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: isCurrentItem
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isCurrentItem
                                ? theme.primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isCurrentItem
                              ? theme.primaryColor
                              : Colors.grey,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
