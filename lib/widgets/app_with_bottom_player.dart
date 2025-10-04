import 'package:flutter/material.dart';
import 'package:muzakri/di_container.dart';
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
    return StreamBuilder(
      stream: globalAudioHandler.mediaItem,
      builder: (context, snapshot) {
        final isPlayerVisible = snapshot.data != null;

        return Scaffold(
          body: Stack(
            children: [
              // Main content
              child,

              // Bottom player
              if (isPlayerVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BottomPlayer(
                    isVisible: isPlayerVisible,
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
