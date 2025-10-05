import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/bloc/audio_player/audio_player_bloc.dart';
import 'package:muzakri/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/screens/playlists_screen.dart';
import 'package:muzakri/screens/reciters_screen.dart';
import 'package:muzakri/widgets/bottom_player.dart';
import 'package:muzakri/widgets/expanded_player_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const RecitersScreen(),
    const DownloadsScreen(),
    const PlaylistsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              // Main content
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),

              // Bottom player when audio is playing
              if (state.hasMediaItem)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: BottomPlayer(
                    onTap: () => _navigateToExpandedPlayer(context),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                activeIcon: const Icon(Icons.person),
                label: AppLocalizations.of(context)!.reciters,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.download),
                activeIcon: const Icon(Icons.download),
                label: AppLocalizations.of(context)!.downloads,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.playlist_play),
                activeIcon: const Icon(Icons.playlist_play),
                label: AppLocalizations.of(context)!.playlists,
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToExpandedPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpandedPlayerScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}
