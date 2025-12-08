import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../core/di/injection.dart';
import '../core/utils/toast_utils.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/downloads/domain/entities/download_item.dart';
import '../features/downloads/domain/repositories/downloads_repository.dart';
import '../features/downloads/presentation/bloc/downloads_bloc.dart';
import '../features/downloads/presentation/widgets/download_button.dart';
import '../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../features/surah/domain/entities/surah_entity.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import '../shared/audio/audio_player_handler.dart';
import '../shared/models/reciter_model.dart';
import '../shared/widgets/bottom_player_widget.dart';

class ReciterDetailsScreen extends StatefulWidget {
  const ReciterDetailsScreen({super.key, required this.reciter});
  final Reciter reciter;

  @override
  State<ReciterDetailsScreen> createState() => _ReciterDetailsScreenState();
}

class _ReciterDetailsScreenState extends State<ReciterDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final Mosahf selectedMoshaf = widget.reciter.moshaf.first;
    context.read<ReciterDetailsBloc>().add(
      LoadSurahList(reciter: widget.reciter, moshaf: selectedMoshaf),
    );
  }

  void _handleDownloadsState(
    DownloadsState downloadState,
    BuildContext context,
  ) {
    final ReciterDetailsState currentState = context
        .read<ReciterDetailsBloc>()
        .state;
    if (currentState is! ReciterDetailsLoaded) {
      return;
    }

    if (downloadState is DownloadsLoaded) {
      // Get downloads for this reciter
      final List<DownloadItem>? reciterDownloads =
          downloadState.downloadsByReciter[widget.reciter.name];

      if (reciterDownloads == null || reciterDownloads.isEmpty) {
        return;
      }

      // Check if any downloads have completed or failed (these need immediate refresh)
      final bool hasCompletedOrFailed = reciterDownloads.any(
        (d) =>
            d.status == DownloadStatus.completed ||
            d.status == DownloadStatus.failed,
      );

      // Find surahs that are downloading, completed, or failed
      // Note: download.id is the URL which matches surah.id
      final Set<String> surahsToRefresh = {};
      for (final DownloadItem download in reciterDownloads) {
        if (download.status == DownloadStatus.downloading ||
            download.status == DownloadStatus.completed ||
            download.status == DownloadStatus.failed) {
          // download.id is the URL which matches surah.id
          surahsToRefresh.add(download.id);
        }
      }

      if (surahsToRefresh.isEmpty) {
        return;
      }

      // If downloads completed/failed, reload entire list immediately
      if (hasCompletedOrFailed) {
        context.read<ReciterDetailsBloc>().add(
          LoadSurahList(
            reciter: widget.reciter,
            moshaf: currentState.selectedMoshaf,
          ),
        );
        return;
      }

      // For in-progress downloads, use targeted updates
      // (debounce is handled by bloc_concurrency in the stream)
      for (final surahId in surahsToRefresh) {
        context.read<ReciterDetailsBloc>().add(
          RefreshSurahDownloadStatus(
            surahId: surahId,
            reciterName: widget.reciter.name,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, downloadState) {
        _handleDownloadsState(downloadState, context);
      },
      child: Scaffold(
        body: BlocBuilder<ReciterDetailsBloc, ReciterDetailsState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                if (widget.reciter.moshaf.length > 1)
                  SliverToBoxAdapter(
                    child: _buildMoshafSelector(context, state),
                  ),
                _buildContent(context, state),
              ],
            );
          },
        ),
        bottomNavigationBar: const BottomPlayerWidget(),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        centerTitle: true,
        title: Text(
          widget.reciter.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50.w,
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
    final List<Mosahf> uniqueMoshaf = widget.reciter.moshaf.toSet().toList();
    final Mosahf selectedMoshaf = state is ReciterDetailsLoaded
        ? state.selectedMoshaf
        : uniqueMoshaf.first;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Mosahf>(
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 24.sp),
            value: uniqueMoshaf.contains(selectedMoshaf)
                ? selectedMoshaf
                : uniqueMoshaf.first,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            items: uniqueMoshaf.map((moshaf) {
              return DropdownMenuItem<Mosahf>(
                value: moshaf,
                child: Text(moshaf.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (Mosahf? moshaf) {
              if (moshaf != null) {
                context.read<ReciterDetailsBloc>().add(
                  LoadSurahList(reciter: widget.reciter, moshaf: moshaf),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReciterDetailsState state) {
    if (state is ReciterDetailsError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 16.h),
              Text(state.message, style: TextStyle(fontSize: 16.sp)),
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
                label: const Text('Retry'),
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
    } else if (state is ReciterDetailsLoaded && state.surahList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64.sp, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context)!.noSurahsAvailable,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    } else if (state is ReciterDetailsLoaded) {
      return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, audioState) {
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
                return _buildSurahCard(surah, index, state, audioState);
              }, childCount: state.surahList.length),
            ),
          );
        },
      );
    }
    return const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSurahCard(
    SurahEntity surah,
    int index,
    ReciterDetailsLoaded state,
    AudioPlayerState audioState,
  ) {
    final MediaItem? currentMediaItem = audioState.mediaItem;
    final PlaybackState? playbackState = audioState.playbackState;
    final bool isCurrentlyPlaying =
        currentMediaItem?.id == surah.id ||
        // Also check if originalId in extras matches (for local files)
        currentMediaItem?.extras?['originalId'] == surah.id;

    final bool isPlaying =
        isCurrentlyPlaying && (playbackState?.playing ?? false);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isCurrentlyPlaying
            ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: isCurrentlyPlaying
            ? Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (isCurrentlyPlaying) {
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
              _playSurah(surah, state);
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
                    color: isCurrentlyPlaying
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: isCurrentlyPlaying
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.4),
                              blurRadius: 8.r,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCurrentlyPlaying
                        ? Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
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
                          color: isCurrentlyPlaying
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        surah.reciterName,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Download Status
                    DownloadButton(
                      surahId: surah.id,
                      surahTitle: surah.name,
                      reciterName: widget.reciter.name,
                    ),

                    SizedBox(width: 12.w),

                    // Play Button Container
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: isCurrentlyPlaying
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isCurrentlyPlaying
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isCurrentlyPlaying
                            ? Theme.of(context).primaryColor
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
    );
  }

  /// Check if a surah is downloaded and get its file path
  Future<String?> _getDownloadedFilePath(SurahEntity surah) async {
    try {
      final DownloadsRepository downloadsRepository =
          getIt<DownloadsRepository>();
      // Extract surah ID from the title (assuming format like "001 Al-Fatiha")
      final String surahId = surah.name.split(' ').first;
      final String? filePath = await downloadsRepository.getDownloadedFilePath(
        surahId,
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

  Future<void> _playSurah(SurahEntity surah, ReciterDetailsLoaded state) async {
    try {
      // Check if the surah is downloaded
      final String? downloadedFilePath = await _getDownloadedFilePath(surah);

      // Set the selected surah immediately for instant highlighting
      if (mounted) {
        context.read<ReciterDetailsBloc>().add(SelectSurah(surah.id));
      }

      final AudioPlayerHandler audioHandler = getIt<AudioPlayerHandler>();

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
        // Create a list of surahs, using downloaded files when available
        final List<MediaItem> surahListWithDownloads = [];
        for (var i = 0; i < state.surahList.length; i++) {
          final SurahEntity currentSurah = state.surahList[i];
          if (i == surahIndex && downloadedFilePath != null) {
            // Use downloaded file for the selected surah
            surahListWithDownloads.add(
              _createLocalMediaItem(currentSurah, downloadedFilePath),
            );
          } else {
            // Check if this surah is also downloaded
            final String? otherDownloadedPath = await _getDownloadedFilePath(
              currentSurah,
            );
            if (otherDownloadedPath != null) {
              surahListWithDownloads.add(
                _createLocalMediaItem(currentSurah, otherDownloadedPath),
              );
            } else {
              surahListWithDownloads.add(currentSurah.mediaItem);
            }
          }
        }

        // Update queue with the surah list (with downloaded files where available)
        logger.d(
          '_playSurah: updating queue with ${surahListWithDownloads.length} surahs',
        );

        try {
          await audioHandler.updateQueue(surahListWithDownloads);

          // Ensure we're paused before seeking to prevent unwanted playback
          await audioHandler.pause();

          // Skip to the selected surah
          logger.d('_playSurah: skipping to surah at index $surahIndex');
          await audioHandler.skipToQueueItem(surahIndex);

          // Now start playing the selected surah
          await audioHandler.play();
        } catch (e) {
          logger.d(
            '_playSurah: error playing with downloaded files, falling back to streaming',
          );
          // Fallback to original surah list if downloaded files fail
          await audioHandler.updateQueue(
            state.surahList.map((s) => s.mediaItem).toList(),
          );
          await audioHandler.pause();
          await audioHandler.skipToQueueItem(surahIndex);
          await audioHandler.play();
        }
      } else {
        // Fallback: just play the single surah
        logger.d('_playSurah: surah not found in list, playing single surah');
        final MediaItem surahToPlay = downloadedFilePath != null
            ? _createLocalMediaItem(surah, downloadedFilePath)
            : surah.mediaItem;

        try {
          await audioHandler.updateQueue([surahToPlay]);
          await audioHandler.pause();
          await audioHandler.skipToQueueItem(0);
          await audioHandler.play();
        } catch (e) {
          logger.d(
            '_playSurah: error playing single downloaded surah, falling back to streaming',
          );
          // Fallback to original surah if downloaded file fails
          await audioHandler.updateQueue([surah.mediaItem]);
          await audioHandler.pause();
          await audioHandler.skipToQueueItem(0);
          await audioHandler.play();
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
