import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/preloading_screen.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image_flutter/quran_image_reader.dart';

import 'core/di/dependency_injection.dart';
import 'domain/repositories/verse_marker_repository.dart';

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
    final repo = sl<VerseMarkerRepository>();
    // Check if already preloaded (production mode) or needs waiting
    _isPreloaded = !repo.isDebugMode || repo.isPreloaded;
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
              child: BlocBuilder<NavigationBloc, NavigationState>(
                buildWhen: (previous, current) {
                  // Only rebuild when transitioning to a loaded/error state for the first time
                  if (previous is NavigationLoaded) return false;
                  return current is NavigationLoaded ||
                      current is NavigationError;
                },
                builder: (context, state) {
                  if (state is NavigationLoaded) {
                    return const QuranImageReader();
                  }
                  if (state is NavigationError) {
                    return Scaffold(body: Center(child: Text(state.message)));
                  }
                  // Silent loading state with matching background
                  return const Scaffold(backgroundColor: Color(0xFFFBF4E4));
                },
              ),
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
