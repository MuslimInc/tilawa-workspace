import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/player_background_cubit.dart';
import '../cubit/player_background_state.dart';
import '../../domain/entities/player_background_configuration.dart';

class PlayerBackgroundLayer extends StatelessWidget {
  const PlayerBackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBackgroundCubit, PlayerBackgroundState>(
      builder: (context, state) {
        final config = state.config;

        if (config.type == PlayerBackgroundType.custom &&
            config.customImagePath != null) {
          return _CustomBackground(config: config);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _CustomBackground extends StatelessWidget {
  const _CustomBackground({required this.config});

  final PlayerBackgroundConfiguration config;

  @override
  Widget build(BuildContext context) {
    final file = File(config.customImagePath!);

    return Stack(
      fit: StackFit.expand,
      children: [
        // The image itself
        Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          // Optimize memory usage by caching at screen size
          cacheWidth: MediaQuery.of(context).size.width.toInt() * 2,
        ),

        // Blur effect if requested
        if (config.blurAmount > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: config.blurAmount,
                sigmaY: config.blurAmount,
              ),
              child: const SizedBox.shrink(),
            ),
          ),

        // Darkening overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: config.overlayOpacity),
          ),
        ),
      ],
    );
  }
}
