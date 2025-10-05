import 'package:flutter/material.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.playlists),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text(AppLocalizations.of(context)!.noPlaylistsYet)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement create playlist functionality
            },
            child: Text(AppLocalizations.of(context)!.createPlaylist),
          ),
        ],
      ),
    );
  }
}
