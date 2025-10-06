import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/shared/widgets/bottom_player.dart';
import 'package:muzakri/shared/widgets/expanded_player_screen.dart';

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
          // body: child,
          // bottomNavigationBar: state.hasMediaItem
          //     ? BottomPlayer(
          //         isVisible: state.hasMediaItem,
          //         onTap: () => _navigateToExpandedPlayer(context),
          //       )
          //     : null,
          body: Stack(
            children: [
              // Main content with padding for bottom player
              Padding(
                padding: EdgeInsets.only(
                  bottom: state.hasMediaItem
                      ? 80.0
                      : 0.0, // Add padding when player is visible
                ),
                child: child,
              ),

              // Bottom player
              if (state.hasMediaItem)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      kBottomNavigationBarHeight, // Account for bottom nav bar
                  child: BottomPlayer(
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
