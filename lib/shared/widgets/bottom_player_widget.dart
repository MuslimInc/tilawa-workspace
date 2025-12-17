import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../helpers/reciter_helper.dart';
import '../../router/app_router_config.dart';
import '../models/position_data.dart';
import '../models/reciter_model.dart';
import 'bottom_player_ui.dart';

/// Bloc-connected wrapper for BottomPlayerUI that handles state management
class BottomPlayerWidget extends StatefulWidget {
  const BottomPlayerWidget({super.key});

  @override
  State<BottomPlayerWidget> createState() => _BottomPlayerWidgetState();
}

class _BottomPlayerWidgetState extends State<BottomPlayerWidget> {
  int? _currentReciterId;
  String? _currentReciterName;
  bool _manuallyDismissed = false;

  @override
  void initState() {
    super.initState();
    // Initialize the AudioPlayerBloc
    context.read<AudioPlayerBloc>().add(
      const AudioPlayerEvent.loadAudioPlayerData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioPlayerBloc, AudioPlayerState>(
      listenWhen: (previous, current) {
        // Reset manual dismissal if media item changes or we start playing again
        return previous.mediaItem != current.mediaItem ||
            (!previous.isPlaying && current.isPlaying);
      },
      listener: (context, state) {
        if (_manuallyDismissed) {
          setState(() {
            _manuallyDismissed = false;
          });
        }
      },
      child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, state) {
          final MediaItem? mediaItem = state.mediaItem;
          final bool shouldShow =
              mediaItem != null &&
              state.status == AudioPlayerStatus.success &&
              !_manuallyDismissed;

          // Hide if no media, error, or manually dismissed
          if (!shouldShow) {
            return const SizedBox.shrink();
          }

          // Load reciter ID if it's not cached or if the reciter name changed
          if (_currentReciterId == null ||
              _currentReciterName != mediaItem.artist) {
            _loadReciterId(mediaItem);
          }

          final PositionData position =
              state.positionData ??
              const PositionData(
                position: Duration.zero,
                bufferedPosition: Duration.zero,
                duration: Duration.zero,
              );

          return Dismissible(
            key: ValueKey('bottom_player_${mediaItem.id}'),
            direction: DismissDirection.down,
            onDismissed: (direction) {
              setState(() {
                _manuallyDismissed = true;
              });
              context.read<AudioPlayerBloc>().add(
                const AudioPlayerEvent.stopAudio(),
              );
            },
            child: BottomPlayerUi(
              mediaItem: mediaItem,
              positionData: position,
              isPlaying: state.isPlaying,
              canGoPrevious: state.canGoPrevious,
              canGoNext: state.canGoNext,
              onPlayPause: () {
                if (state.isPlaying) {
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.pauseAudio(),
                  );
                } else {
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.playAudio(),
                  );
                }
              },
              onPrevious: () {
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToPrevious(),
                );
              },
              onNext: () {
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.skipToNext(),
                );
              },
              onClose: () {
                // Provide haptic feedback for consistency
                HapticFeedback.lightImpact();
                setState(() {
                  _manuallyDismissed = true;
                });
                context.read<AudioPlayerBloc>().add(
                  const AudioPlayerEvent.stopAudio(),
                );
              },
              onTap: () => const ExpandedPlayerRoute().push(context),
            ),
          );
        },
      ),
    );
  }

  /// Load reciter ID asynchronously and cache it
  void _loadReciterId(MediaItem mediaItem) {
    if (mediaItem.artist == null) {
      return;
    }

    _currentReciterName = mediaItem.artist;

    // Load reciter ID asynchronously
    ReciterHelper.getReciterFromMediaItem(mediaItem)
        .then((reciter) {
          if (mounted && reciter != null) {
            setState(() {
              _currentReciterId = reciter.id;
            });
          }
        })
        .catchError((error) {
          // Silently handle errors (e.g., GetIt not initialized in tests)
          // The reciter ID is optional, so we can continue without it
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
