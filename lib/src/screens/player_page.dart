import 'package:flutter/material.dart';

import 'play_online.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({required this.surah, required this.reciterName});
  final String surah;
  final String reciterName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF212121),
        body: PlayOnline(
          surahTitle: 'titiiitle',
          rewaya: 'reewayaa',
          singleSurahUrl: surah,
          reciterName: reciterName,
        ),
      ),
    );
  }
}
