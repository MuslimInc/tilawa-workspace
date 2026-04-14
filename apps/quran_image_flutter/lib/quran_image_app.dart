import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image_flutter/core/design_tokens/colors.dart';
import 'package:quran_image_flutter/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image_flutter/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image_flutter/preloading_screen.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image_flutter/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image_flutter/presentation/mappers/app_message_mapper.dart';
import 'package:quran_image_flutter/quran_image_reader.dart';

import 'core/di/dependency_injection.dart';
import 'domain/entities/app_message.dart';
import 'l10n/app_localizations.dart';

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
    final repo = sl<AssetVerseMarkerRepository>();
    final imageCacheRepository = sl<QuranImageCacheRepository>();
    _isPreloaded = repo.isInitialized && imageCacheRepository.status.isReady;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Image',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
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
                  // Rebuild on initial load, error, or recovery from error
                  if (previous is NavigationLoaded &&
                      current is NavigationLoaded) {
                    return false;
                  }
                  return current is NavigationLoaded ||
                      current is NavigationError;
                },
                builder: (context, state) {
                  if (state is NavigationLoaded) {
                    return const QuranImageReader();
                  }
                  if (state is NavigationError) {
                    final l10n = AppLocalizations.of(context)!;
                    return Scaffold(
                      backgroundColor: AppColors.pageBackground,
                      body: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.appMessage.localize(l10n),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<NavigationBloc>()
                                    .add(const NavigationRetryRequested()),
                                child: Text(
                                  const RetryMessage().localize(l10n),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  // Silent loading state with matching background
                  return const Scaffold(backgroundColor: Color(0xFFFFF9F2));
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
