import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_state.dart';
import 'package:muzakri/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:muzakri/features/settings/presentation/screens/settings_screen.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router.dart';
import 'package:muzakri/screens/playlists_screen.dart';
import 'package:muzakri/screens/reciters_screen.dart';
import 'package:muzakri/shared/widgets/bottom_player.dart';

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
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          authenticated: (user) {
            // User is authenticated, stay on current screen
          },
          unauthenticated: () {
            // Redirect to login if not authenticated
            context.go(AppRouter.login);
          },
          error: (message) {
            // Show error and redirect to login
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
            context.go(AppRouter.login);
          },
        );
      },
      child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
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
                    child: BottomPlayer(),
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
                  label: AppLocalizations.of(context)?.reciters ?? 'Reciters',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.download),
                  activeIcon: const Icon(Icons.download),
                  label: AppLocalizations.of(context)?.downloads ?? 'Downloads',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.playlist_play),
                  activeIcon: const Icon(Icons.playlist_play),
                  label: AppLocalizations.of(context)?.playlists ?? 'Playlists',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings),
                  activeIcon: const Icon(Icons.settings),
                  label: AppLocalizations.of(context)?.settings ?? 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
