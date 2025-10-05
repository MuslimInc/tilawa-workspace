import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/bloc/audio_player/audio_player_bloc.dart';
import 'package:muzakri/position_data.dart';

class BottomPlayer extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onTap;

  const BottomPlayer({super.key, this.isVisible = true, this.onTap});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }

    // Initialize the AudioPlayerBloc
    context.read<AudioPlayerBloc>().add(
      const AudioPlayerEvent.loadAudioPlayerData(),
    );
  }

  @override
  void didUpdateWidget(BottomPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        if (state.status != AudioPlayerStatus.success) {
          return const SizedBox.shrink();
        }

        final mediaItem = state.mediaItem!;
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

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 100),
              child: Hero(
                tag: 'bottom_player',
                child: Material(
                  elevation: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
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
                      onTap: widget.onTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar - Real time (YouTube Music style)
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

                          // Main controls
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                // Album art or icon
                                Container(
                                  width: 60.w,
                                  height: 60.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                  ),
                                  child: mediaItem.artUri != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                                    size: 30,
                                                  );
                                                },
                                          ),
                                        )
                                      : Icon(
                                          Icons.music_note,
                                          color: Theme.of(context).primaryColor,
                                          size: 30,
                                        ),
                                ),

                                const SizedBox(width: 12),

                                // Song info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 2),
                                      Text(
                                        mediaItem.artist ??
                                            mediaItem.album ??
                                            'Unknown',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Previous button
                                IconButton(
                                  icon: const Icon(
                                    FluentIcons.arrow_left_24_regular,
                                    size: 20,
                                  ),
                                  onPressed: canGoPrevious
                                      ? () => context.read<AudioPlayerBloc>().add(
                                          const AudioPlayerEvent.skipToPrevious(),
                                        )
                                      : null,
                                ),

                                // Play/Pause button - YouTube Music style
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
                                      size: 24,
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
                                    size: 20,
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
            );
          },
        );
      },
    );
  }
}
