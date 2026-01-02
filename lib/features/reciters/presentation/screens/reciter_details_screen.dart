import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/analytics_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/entities/audio.dart';
import '../../../../core/entities/moshaf_entity.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/extensions.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/color_scheme.dart';
import '../../../../shared/widgets/bottom_player_widget.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../../downloads/presentation/widgets/download_button.dart';
import '../../../surah/domain/entities/surah_entity.dart';
import '../bloc/reciter_details_bloc.dart';
import '../bloc/reciter_download_bloc.dart';
import '../widgets/download_all_button.dart';

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
                      _ReciterAppBar(reciter: widget.reciter),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          minHeight: 60.h,
                          maxHeight: 60.h,
                          child: ColoredBox(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: _ReciterSearchField(
                              controller: _searchController,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (widget.reciter.moshaf.length > 1)
                              _MoshafSelector(
                                reciter: widget.reciter,
                                state: state,
                              ),
                            if (state.status == ReciterDetailsStatus.loaded &&
                                state.surahList.isNotEmpty &&
                                state.searchQuery.isEmpty)
                              DownloadAllButton(
                                reciter: widget.reciter,
                                surahs: state.surahList,
                              ),
                          ],
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

class _ReciterAppBar extends StatelessWidget {
  const _ReciterAppBar({required this.reciter});
  final ReciterEntity reciter;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      // Remove text title here to avoid duplication
      // title: ...
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
        title: Text(
          reciter.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp, // Reduced slightly as it scales up
          ),
          textAlign: TextAlign.center,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    Theme.of(context).colorScheme.secondary,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Decorative Icon
            Positioned(
              right: -40.w,
              bottom: -10.h,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.mic_none_outlined,
                  size: 200.sp,
                  color: Colors.white.withValues(alpha: 0.05), // Subtle
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
            // Avatar in background
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 30.h,
                ), // Push up to make room for title
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      reciter.name[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: context.l10n.searchSurah,
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          fillColor: context.primaryColor.withValues(alpha: 0.1),
          filled: true,
          isDense: true,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).hintColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.clear_rounded),
                color: Theme.of(context).hintColor,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ButtonTheme(
          alignedDropdown: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MoshafEntity>(
              isExpanded: true,
              dropdownColor: theme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24.sp,
                color: theme.primaryColor,
              ),
              value: uniqueMoshaf.contains(selectedMoshaf)
                  ? selectedMoshaf
                  : uniqueMoshaf.first,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                    context.l10n.noSurahsAvailable,
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
    return Padding(
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
    final (
      bool isPlaying,
      bool isCurrentItem,
    ) = context.select<AudioPlayerBloc, (bool, bool)>((bloc) {
      final AudioEntity? currentAudio = bloc.state.currentAudio;
      final PlaybackStateEntity? playbackState = bloc.state.playbackState;

      final bool isCurrent =
          currentAudio?.id == surah.id || currentAudio?.url == surah.audio.url;

      final bool playing = isCurrent && (playbackState?.isPlaying ?? false);

      return (playing, isCurrent);
    });

    return RepaintBoundary(
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
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isCurrentItem
                        ? theme.primaryColor
                        : theme.disabledColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCurrentItem
                        ? Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          )
                        : Text(
                            surah.formattedId.isNotEmpty
                                ? surah.formattedId
                                : '${index + 1}',
                            style: TextStyle(
                              color: isCurrentItem
                                  ? Colors.white
                                  : theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
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
                          fontWeight: isCurrentItem
                              ? FontWeight.bold
                              : FontWeight.w500,
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
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.6,
                          ),
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

                    SizedBox(width: 8.w),

                    // Play Button with cleaner look
                    if (!isCurrentItem)
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryColor.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: theme.primaryColor,
                          size: 20.sp,
                        ),
                      )
                    else
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryColor,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20.sp,
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
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
