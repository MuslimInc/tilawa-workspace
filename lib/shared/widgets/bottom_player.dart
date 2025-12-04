import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../helpers/reciter_helper.dart';
import '../../router/app_router_config.dart';
import '../models/position_data.dart';
import '../models/reciter_model.dart';
import 'view_reciter_button.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  int? _currentReciterId;
  String? _currentReciterName;

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
        final MediaItem? mediaItem = state.mediaItem;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }
        if (state.status != AudioPlayerStatus.success) {
          return const SizedBox.shrink();
        }

        // Load reciter ID if it's not cached or if the reciter name changed
        if (_currentReciterId == null ||
            _currentReciterName != mediaItem.artist) {
          _loadReciterId(mediaItem);
        }

        final PositionData? positionData = state.positionData;

        final bool isPlaying = state.isPlaying;
        final PositionData position =
            positionData ??
            const PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );

        // Check if next/previous buttons should be enabled
        final bool canGoNext = state.canGoNext;
        final bool canGoPrevious = state.canGoPrevious;

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
                onTap: () => const ExpandedPlayerRoute().push(context),
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
                        ],

                        // Progress bar - Real time
                        Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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

  /// Load reciter ID asynchronously and cache it
  void _loadReciterId(MediaItem mediaItem) {
    if (mediaItem.artist == null) {
      return;
    }

    _currentReciterName = mediaItem.artist;

    // Load reciter ID asynchronously
    ReciterHelper.getReciterFromMediaItem(mediaItem).then((reciter) {
      if (mounted && reciter != null) {
        setState(() {
          _currentReciterId = reciter.id;
        });
      }
    });
  }

  /// Check if the current route is already viewing the reciter's details
  bool isCurrentRouteAlreadyViewing(BuildContext context) {
    try {
      final GoRouterState routerState = GoRouterState.of(context);

      // Check if we're on the reciter details route by checking path parameters
      final String? currentReciterId = routerState.pathParameters['reciterId'];

      if (currentReciterId == null) {
        // Not on a reciter details route
        return false;
      }

      // Compare with cached reciter ID if available
      if (_currentReciterId != null) {
        return currentReciterId == _currentReciterId.toString();
      }

      // If ID is not cached yet, try to get reciter from query parameters
      // The route includes the reciter object in query parameters
      final String? reciterJson = routerState.uri.queryParameters['reciter'];
      if (reciterJson != null) {
        try {
          final reciter = Reciter.fromJson(
            jsonDecode(reciterJson) as Map<String, dynamic>,
          );
          // Compare by name as fallback
          return reciter.name == _currentReciterName;
        } catch (e) {
          // If parsing fails, fall back to false
          return false;
        }
      }

      // If we can't determine, return false to show the button
      return false;
    } catch (e) {
      // If GoRouterState is not available, return false to show the button
      return false;
    }
  }
}
