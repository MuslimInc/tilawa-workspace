import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';

import '../../core/entities/audio.dart';
import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../features/audio_player/presentation/widgets/sleep_timer_dialog.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final AudioEntity? audio = state.currentAudio;

        // Hide if no media, error, or manually dismissed
        if (!state.shouldShowBottomPlayer || audio == null) {
          return const SizedBox.shrink();
        }

        // Load reciter ID if it's not cached or if the reciter name changed
        if (_currentReciterId == null || _currentReciterName != audio.artist) {
          _loadReciterId(audio);
        }

        final PositionData position =
            state.positionData ??
            const PositionData(
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              duration: Duration.zero,
            );

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.surface),
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Dismissible(
            key: Key(audio.id),
            direction: DismissDirection.down,
            onDismissed: (direction) {
              context.read<AudioPlayerBloc>().add(
                const AudioPlayerEvent.stopAudio(),
              );
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                8.h,
                16.w,
                20.h + MediaQuery.paddingOf(context).bottom,
              ),
              child: BottomPlayerUi(
                audio: audio,
                positionData: position,
                isPlaying: state.isPlaying,
                canGoPrevious: state.canGoPrevious,
                canGoNext: state.canGoNext,
                isSleepTimerActive: state.isSleepTimerActive,
                isSleepTimerEnabled: context
                    .watch<SettingsCubit>()
                    .state
                    .isSleepTimerEnabled,
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
                onSleepTimerTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SleepTimerDialog(),
                  );
                },
                onClose: () {
                  // Provide haptic feedback for consistency
                  HapticFeedback.lightImpact();
                  context.read<AudioPlayerBloc>().add(
                    const AudioPlayerEvent.stopAudio(),
                  );
                },
                onTap: () => const ExpandedPlayerRoute().push(context),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Load reciter ID asynchronously and cache it
  void _loadReciterId(AudioEntity audio) {
    if (audio.artist == null) {
      return;
    }

    _currentReciterName = audio.artist;

    // Load reciter ID asynchronously
    ReciterHelper.getReciterFromAudioEntity(audio)
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
