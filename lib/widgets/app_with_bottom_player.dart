import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/bloc/audio_player/audio_player_bloc.dart';
import 'package:muzakri/widgets/bottom_player.dart';
import 'package:muzakri/widgets/expanded_player_screen.dart';

class AppWithBottomPlayer extends StatelessWidget {
  final Widget child;

  const AppWithBottomPlayer({super.key, required this.child});

  void _navigateToExpandedPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpandedPlayerScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Main content
              child,

              // Bottom player
              if (state.isPlaying)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BottomPlayer(
                    isVisible: state.isPlaying,
                    onTap: () => _navigateToExpandedPlayer(context),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
