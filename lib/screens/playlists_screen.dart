import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Playlists"), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text("Playlists Screen")),
          ElevatedButton(
            onPressed: () {
              context.pop();
            },
            child: Text("Back"),
          ),
        ],
      ),
    );
  }
}
