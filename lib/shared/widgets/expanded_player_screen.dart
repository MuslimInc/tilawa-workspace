import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../helpers/show_slider_dialog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart';
import '../models/position_data.dart';
import '../models/queue_state.dart';
import 'seek_bar.dart';

class ExpandedPlayerScreen extends StatefulWidget {
  const ExpandedPlayerScreen({super.key});

  @override
  State<ExpandedPlayerScreen> createState() => _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends State<ExpandedPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 && _dragOffset >= 0) {
      // Dragging down
      setState(() {
        _dragOffset += details.delta.dy;
      });
    } else if (_dragOffset > 0) {
      // Dragging up but still below 0
      setState(() {
        _dragOffset += details.delta.dy;
        if (_dragOffset < 0) {
          _dragOffset = 0;
        }
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 150 ||
        (details.primaryVelocity != null && details.primaryVelocity! > 500)) {
      // Dismiss
      Navigator.of(context).pop();
    } else {
      // Snap back
      _animation = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _controller.reset();
      _controller.forward().then((_) {
        setState(() {
          _dragOffset = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final MediaItem? mediaItem = state.mediaItem;
        if (state.status != AudioPlayerStatus.success || mediaItem == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return GestureDetector(
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Scaffold(
              backgroundColor: Colors.transparent, // Important for drag visual
              body: Stack(
                children: [
                  // 1. Background Image with Blur
                  if (mediaItem.artUri != null)
                    Positioned.fill(
                      child: Image.network(
                        mediaItem.artUri.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                    ),

                  // 2. Blur Effect
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // 3. Content
                  SafeArea(
                    child: Column(
                      children: [
                        // AppBar
                        AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: IconButton(
                            icon: Icon(
                              FluentIcons.chevron_down_24_regular,
                              color: Colors.white,
                              size: 28.sp,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.currentPlaying,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // Artwork
                        Expanded(
                          child: Center(
                            child: Hero(
                              tag: 'audio_player',
                              child: Container(
                                width: 280.w,
                                height: 280.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 30.r,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24.r),
                                  child: mediaItem.artUri != null
                                      ? Image.network(
                                          mediaItem.artUri.toString(),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return _buildDefaultArt(
                                                  context,
                                                );
                                              },
                                        )
                                      : _buildDefaultArt(context),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Meta Data
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              Text(
                                mediaItem.title,
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                mediaItem.artist ??
                                    mediaItem.album ??
                                    'Unknown',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Progress
                        _buildProgressBar(context, state),

                        SizedBox(height: 24.h),

                        // Controls
                        _buildControls(context, state),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultArt(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.1),
      child: Icon(
        FluentIcons.music_note_1_24_regular,
        color: Colors.white,
        size: 80.sp,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioPlayerState state) {
    final PositionData positionData =
        state.positionData ??
        const PositionData(
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          duration: Duration.zero,
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SeekBar(
            duration: positionData.duration,
            position: positionData.position,
            bufferedPosition: positionData.bufferedPosition,
            onChangeEnd: (newPosition) {
              context.read<AudioPlayerBloc>().add(
                AudioPlayerEvent.seekTo(newPosition),
              );
            },
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(positionData.position),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.sp,
                ),
              ),
              Text(
                _formatDuration(positionData.duration),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerState state) {
    final QueueState queueState = state.queueState ?? QueueState.empty;
    final bool isPlaying = state.isPlaying;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Volume
            IconButton(
              icon: Icon(
                FluentIcons.speaker_2_24_regular,
                color: Colors.white,
                size: 24.sp,
              ),
              onPressed: () {
                showSliderDialog(
                  context: context,
                  title: 'Adjust volume',
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: state.volume,
                  onChanged: (newVolume) {
                    logger.d('Volume changed to: $newVolume');
                    context.read<AudioPlayerBloc>().add(
                      AudioPlayerEvent.setVolume(newVolume),
                    );
                  },
                );
              },
            ),

            // Previous
            IconButton(
              icon: Icon(
                FluentIcons.previous_24_filled,
                color: state.canGoPrevious
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                size: 32.sp,
              ),
              onPressed: state.canGoPrevious
                  ? () {
                      if (queueState.hasPrevious) {
                        context.read<AudioPlayerBloc>().add(
                          const AudioPlayerEvent.skipToPrevious(),
                        );
                      }
                    }
                  : null,
            ),

            // Play/Pause
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20.r,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying
                      ? FluentIcons.pause_24_filled
                      : FluentIcons.play_24_filled,
                  color: Colors.black, // Dark icon on white button
                  size: 32.sp,
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

            // Next
            IconButton(
              icon: Icon(
                FluentIcons.next_24_filled,
                color: state.canGoNext
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                size: 32.sp,
              ),
              onPressed: state.canGoNext
                  ? () {
                      context.read<AudioPlayerBloc>().add(
                        const AudioPlayerEvent.skipToNext(),
                      );
                    }
                  : null,
            ),

            // Speed
            IconButton(
              icon: Text(
                '${state.speed.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              onPressed: () {
                showSliderDialog(
                  context: context,
                  title: 'Adjust speed',
                  divisions: 10,
                  min: 0.5,
                  max: 1.5,
                  value: state.speed,
                  onChanged: (newSpeed) {
                    context.read<AudioPlayerBloc>().add(
                      AudioPlayerEvent.setSpeed(newSpeed),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
