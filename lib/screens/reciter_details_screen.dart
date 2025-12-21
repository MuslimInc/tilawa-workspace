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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: DownloadButton gets its state directly from DownloadsBloc,
    // so no need to listen to DownloadsBloc here and update surah list
    return Scaffold(
      body: BlocBuilder<ReciterDetailsBloc, ReciterDetailsState>(
        buildWhen: (previous, current) {
          return previous.status != current.status ||
              previous.surahList != current.surahList ||
              previous.selectedMoshaf != current.selectedMoshaf ||
              previous.searchQuery != current.searchQuery ||
              previous.errorMessage != current.errorMessage;
        },
        builder: (context, state) {
          return BlocListener<ReciterDetailsBloc, ReciterDetailsState>(
            listenWhen: (previous, current) =>
                previous.searchQuery != current.searchQuery &&
                current.searchQuery.isEmpty,
            listener: (context, state) {
              if (_searchController.text.isNotEmpty) {
                _searchController.clear();
              }
            },
            child: CustomScrollView(
              restorationId: 'reciter_details_scroll_view',
              slivers: [
                _ReciterAppBar(reciter: widget.reciter),
                SliverToBoxAdapter(
                  child: _ReciterSearchField(controller: _searchController),
                ),
                if (widget.reciter.moshaf.length > 1)
                  SliverToBoxAdapter(
                    child: _MoshafSelector(
                      reciter: widget.reciter,
                      state: state,
                    ),
                  ),
                if (state.status == ReciterDetailsStatus.loaded &&
                    state.surahList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _DownloadAllButton(
                      reciter: widget.reciter,
                      parentState: state,
                    ),
                  ),
                _ReciterDetailsContent(
                  reciter: widget.reciter,
                  state: state,
                  onPlaySurah: (surah) => _playSurah(surah, state),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomPlayerWidget(),
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

class _ReciterAppBar extends StatelessWidget {
  const _ReciterAppBar({required this.reciter});
  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140.h,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
      title: Text(
        reciter.name,
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
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.mic_none_outlined,
              size: 80.sp,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReciterSearchField extends StatelessWidget {
  const _ReciterSearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: context.l10n.searchSurah,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  controller.clear();
                  context.read<ReciterDetailsBloc>().add(
                    const FilterSurahs(''),
                  );
                },
              );
            },
          ),
        ),
        onChanged: (query) {
          context.read<ReciterDetailsBloc>().add(FilterSurahs(query));
        },
      ),
    );
  }
}

class _MoshafSelector extends StatelessWidget {
  const _MoshafSelector({required this.reciter, required this.state});
  final ReciterEntity reciter;
  final ReciterDetailsState state;

  @override
  Widget build(BuildContext context) {
    final List<MoshafEntity> uniqueMoshaf = reciter.moshaf.toSet().toList();
    final MoshafEntity selectedMoshaf =
        state.selectedMoshaf ?? uniqueMoshaf.first;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                    LoadSurahList(reciter: reciter, moshaf: moshaf),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadAllButton extends StatelessWidget {
  const _DownloadAllButton({required this.reciter, required this.parentState});
  final ReciterEntity reciter;
  final ReciterDetailsState parentState;

  @override
  Widget build(BuildContext context) {
    if (parentState.surahList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: BlocBuilder<ReciterDetailsBloc, ReciterDetailsState>(
        buildWhen: (previous, current) =>
            previous.isDownloadingAll != current.isDownloadingAll ||
            previous.downloadProgress != current.downloadProgress,
        builder: (context, state) {
          final bool isDownloading = state.isDownloadingAll;
          final double progress = state.downloadProgress;

          return ElevatedButton.icon(
            onPressed: () {
              if (isDownloading) {
                context.read<ReciterDetailsBloc>().add(
                  CancelDownloadAllSurahs(reciter.name),
                );
              } else {
                context.read<ReciterDetailsBloc>().add(
                  DownloadAllSurahs(
                    reciter: reciter,
                    surahs: state.filteredSurahs,
                  ),
                );
                ToastUtils.showToast(msg: context.l10n.downloadingAllSurahs);
              }
            },
            icon: isDownloading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              isDownloading
                  ? '${context.l10n.cancel} ${(progress * 100).toInt()}%'
                  : (progress > 0 && progress < 1.0)
                  ? context.l10n.completeDownloading
                  : context.l10n.downloadAll,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        },
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
                    'No surahs found for "${state.searchQuery}"',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.only(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            bottom: 30.h,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final SurahEntity surah = filteredSurahs[index];
              return _SurahCard(
                key: ValueKey('surah_${surah.id}'),
                surah: surah,
                index: index,
                reciterName: reciter.name,
                reciterId: reciter.id,
                onTap: () => onPlaySurah(surah),
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
            bottom: 30.h,
          ),
          sliver: SliverSkeletonizer(
            child: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _SkeletonSurahCard(),
                childCount: 8,
              ),
            ),
          ),
        );
    }
  }
}

class _SkeletonSurahCard extends StatelessWidget {
  const _SkeletonSurahCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 80.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required super.key,
    required this.surah,
    required this.index,
    required this.reciterName,
    required this.reciterId,
    required this.onTap,
  });

  final SurahEntity surah;
  final int index;
  final String reciterName;
  final int reciterId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Combine selectors to reduce overhead and subscription count
    final (bool isPlaying, bool isCurrentItem) = context
        .select<AudioPlayerBloc, (bool, bool)>((bloc) {
          final MediaItem? currentMediaItem = bloc.state.mediaItem;
          final PlaybackState? playbackState = bloc.state.playbackState;

          final bool isCurrent =
              currentMediaItem?.id == surah.id ||
              currentMediaItem?.extras?['originalId'] == surah.id;

          final bool playing = isCurrent && (playbackState?.playing ?? false);

          return (playing, isCurrent);
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
                              surah.formattedId.isNotEmpty
                                  ? surah.formattedId
                                  : '${index + 1}',
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
                        reciterId: reciterId,
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
