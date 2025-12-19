import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'bottom_player_widget.dart';

class AppWithBottomPlayer extends StatelessWidget {
  const AppWithBottomPlayer({super.key, required this.child});
  final Widget child;

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
                      ? 120.0
                      : 0.0, // Add padding when player is visible
                ),
                child: child,
              ),

              // Bottom player
              if (state.hasMediaItem)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      kBottomNavigationBarHeight, // Account for bottom nav bar
                  child: BottomPlayerWidget(),
                ),
            ],
          ),
        );
      },
    );
  }
}
