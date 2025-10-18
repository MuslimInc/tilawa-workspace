import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/helpers/reciter_helper.dart';
import 'package:muzakri/position_data.dart';
import 'package:muzakri/router/app_router.dart';
import 'package:muzakri/shared/widgets/view_reciter_button.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  @override
  void initState() {
    super.initState();

    // Initialize the AudioPlayerBloc
    context.read<AudioPlayerBloc>().add(
      const AudioPlayerEvent.loadAudioPlayerData(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final mediaItem = state.mediaItem;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }
        if (state.status != AudioPlayerStatus.success) {
          return const SizedBox.shrink();
        }

        final positionData = state.positionData;

        final isPlaying = state.isPlaying;
        final position =
            positionData ??
            PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );

        // Check if next/previous buttons should be enabled
        final canGoNext = state.canGoNext;
        final canGoPrevious = state.canGoPrevious;

        return Hero(
          tag: 'audio_player',
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => context.push(AppRouter.expandedPlayer),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // View Reciter button
                        if (ReciterHelper.hasReciterInfo(mediaItem) &&
                            !isCurrentRouteAlreadyViewing(context)) ...[
                          ViewReciterButton(mediaItem: mediaItem),
                          SizedBox(height: 4.h),
                        ],

                        // Progress bar - Real time
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: position.duration.inMilliseconds > 0
                                  ? position.position.inMilliseconds /
                                        position.duration.inMilliseconds
                                  : 0.0,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Main controls
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          child: Row(
                            children: [
                              // Album art or icon
                              Container(
                                width: 48.w,
                                height: 48.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                ),
                                child: mediaItem.artUri != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          mediaItem.artUri.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.music_note,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 22,
                                                );
                                              },
                                        ),
                                      )
                                    : Icon(
                                        Icons.music_note,
                                        color: Theme.of(context).primaryColor,
                                        size: 22,
                                      ),
                              ),

                              const SizedBox(width: 8),

                              // Song info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      mediaItem.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // const SizedBox(height: 1),
                                    // Text(
                                    //   mediaItem.artist ??
                                    //       mediaItem.album ??
                                    //       'Unknown',
                                    //   style: Theme.of(context).textTheme.bodySmall
                                    //       ?.copyWith(color: Colors.black),
                                    //   maxLines: 1,
                                    //   overflow: TextOverflow.ellipsis,
                                    // ),
                                  ],
                                ),
                              ),

                              // Previous button
                              IconButton(
                                icon: const Icon(
                                  FluentIcons.arrow_left_24_regular,
                                  size: 18,
                                ),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                onPressed: canGoPrevious
                                    ? () => context.read<AudioPlayerBloc>().add(
                                        const AudioPlayerEvent.skipToPrevious(),
                                      )
                                    : null,
                              ),

                              // Play/Pause button
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying
                                        ? FluentIcons.pause_24_regular
                                        : FluentIcons.play_24_regular,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 34,
                                    minHeight: 34,
                                  ),
                                  onPressed: () {
                                    if (isPlaying) {
                                      context.read<AudioPlayerBloc>().add(
                                        const AudioPlayerEvent.pauseAudio(),
                                      );
                                    } else {
                                      context.read<AudioPlayerBloc>().add(
                                        const AudioPlayerEvent.playAudio(),
                                      );
                                    }
                                  },
                                ),
                              ),

                              // Next button
                              IconButton(
                                icon: const Icon(
                                  FluentIcons.arrow_right_24_regular,
                                  size: 18,
                                ),
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                onPressed: canGoNext
                                    ? () => context.read<AudioPlayerBloc>().add(
                                        const AudioPlayerEvent.skipToNext(),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Check if the current route is already viewing the reciter's details
  bool isCurrentRouteAlreadyViewing(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final mediaItem = context.read<AudioPlayerBloc>().state.mediaItem;

    if (mediaItem == null) return false;

    // Extract reciter name from mediaItem
    final reciterName = mediaItem.artist;
    if (reciterName == null) return false;

    // Check if current route matches the reciter details route pattern: /reciter/:reciterId
    if (currentLocation.contains('/reciter/')) {
      // Extract the reciter ID from the current path
      final pathSegments = currentLocation.split('/');
      final reciterIndex = pathSegments.indexOf('reciter');

      if (reciterIndex != -1 && reciterIndex + 1 < pathSegments.length) {
        /// Compare the reciter id with the current reciter name
        final reciterId = pathSegments[reciterIndex + 1];
        return reciterId.toLowerCase() == reciterName.toLowerCase();
      }
    }

    return false;
  }
}
