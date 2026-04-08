import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/preloading_screen.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image_flutter/quran_image_reader.dart';
import 'package:quran_image_flutter/verse_service.dart';

class QuranImageApp extends StatefulWidget {
  const QuranImageApp({super.key});

  @override
  State<QuranImageApp> createState() => _QuranImageAppState();
}

class _QuranImageAppState extends State<QuranImageApp> {
  bool _isPreloaded = false;

  @override
  void initState() {
    super.initState();
    // Check if already preloaded (production mode) or needs waiting
    _isPreloaded = !verseService.isDebugMode || verseService.isPreloaded;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Image',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: _isPreloaded
          ? BlocProvider(
              create: (_) =>
                  NavigationBloc()..add(const NavigationInitialized()),
              child: const QuranImageReader(),
            )
          : PreloadingScreen(
              onPreloadComplete: () {
                setState(() {
                  _isPreloaded = true;
                });
              },
            ),
    );
  }
}
