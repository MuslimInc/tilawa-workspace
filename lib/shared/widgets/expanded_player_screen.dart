import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../services/audio_position_service.dart';
import 'control_buttons.dart';

class ExpandedPlayerScreen extends StatelessWidget {
  const ExpandedPlayerScreen({super.key, this.audioPositionService});

  final AudioPositionService? audioPositionService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final MediaItem? mediaItem = state.mediaItem;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // Blurred Background
              if (mediaItem.artUri != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: mediaItem.artUri.toString(),
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      // Artwork
                      Center(
                        child: Container(
                          width: 300.r,
                          height: 300.r,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: mediaItem.artUri != null
                                ? CachedNetworkImage(
                                    imageUrl: mediaItem.artUri.toString(),
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.grey),
                          ),
                        ),
                      ),
                      SizedBox(height: 48.h),
                      // Info
                      Text(
                        mediaItem.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        mediaItem.artist ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 18.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      // Progress Bar
                      StreamBuilder<Duration>(
                        stream:
                            (audioPositionService ??
                                    getIt<AudioPositionService>())
                                .position,
                        builder: (context, snapshot) {
                          final Duration position =
                              snapshot.data ?? Duration.zero;
                          final Duration duration =
                              mediaItem.duration ?? Duration.zero;
                          return Column(
                            children: [
                              Slider(
                                value: position.inSeconds.toDouble(),
                                max: duration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  context.read<AudioPlayerBloc>().add(
                                    AudioPlayerEvent.seekTo(
                                      Duration(seconds: value.toInt()),
                                    ),
                                  );
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 24.h),
                      // Controls
                      const ControlButtons(),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}
