import 'package:flutter/material.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/widgets/bottom_player.dart';

class AppWithBottomPlayer extends StatefulWidget {
  final Widget child;

  const AppWithBottomPlayer({super.key, required this.child});

  @override
  State<AppWithBottomPlayer> createState() => _AppWithBottomPlayerState();
}

class _AppWithBottomPlayerState extends State<AppWithBottomPlayer> {
  bool _isPlayerVisible = false;

  @override
  void initState() {
    super.initState();
    _checkPlayerState();
  }

  void _checkPlayerState() {
    globalAudioHandler.mediaItem.listen((mediaItem) {
      if (mounted) {
        setState(() {
          _isPlayerVisible = mediaItem != null;
        });
      }
    });
  }

  void _navigateToExpandedPlayer() {
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
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          widget.child,

          // Bottom player
          if (_isPlayerVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomPlayer(
                isVisible: _isPlayerVisible,
                onTap: _navigateToExpandedPlayer,
              ),
            ),
        ],
      ),
    );
  }
}
