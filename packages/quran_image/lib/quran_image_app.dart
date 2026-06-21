import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/preloading_screen.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_event.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:quran_image/presentation/mappers/app_message_mapper.dart';
import 'package:quran_image/quran_image_reader.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart'
    show TilawaComponentTokens, TilawaDesignTokens;

import 'core/di/dependency_injection.dart';
import 'domain/entities/app_message.dart';
import 'l10n/quran_image_localizations.dart';

class QuranImageApp extends StatefulWidget {
  const QuranImageApp({super.key});

  @override
  State<QuranImageApp> createState() => _QuranImageAppState();
}

class _QuranImageAppState extends State<QuranImageApp> {
  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
  );

  static final ThemeData _appTheme = ThemeData(
    colorScheme: _colorScheme,
    extensions: <ThemeExtension<dynamic>>[
      TilawaDesignTokens.light(),
      TilawaComponentTokens.light(colorScheme: _colorScheme),
    ],
    useMaterial3: true,
  );

  bool _isPreloaded = false;
  NavigationBloc? _navigationBloc;

  @override
  void initState() {
    super.initState();
    final sw = PerfLogger.startTimer();
    final repo = sl<AssetVerseMarkerRepository>();
    final imageCacheRepository = sl<QuranImageCacheRepository>();
    _isPreloaded = repo.isInitialized && imageCacheRepository.status.isReady;

    if (_isPreloaded) {
      _ensureNavigationBlocInitialized(reason: 'initState-cache-ready');
    }

    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImageApp',
      message:
          'initState completed isPreloaded=$_isPreloaded '
          'navigationBlocReady=${_navigationBloc != null}',
    );
  }

  @override
  void dispose() {
    _navigationBloc?.close();
    super.dispose();
  }

  NavigationBloc _ensureNavigationBlocInitialized({required String reason}) {
    final existingBloc = _navigationBloc;
    if (existingBloc != null) return existingBloc;

    final sw = PerfLogger.startTimer();
    final bloc = NavigationBloc()..add(const NavigationInitialized());
    _navigationBloc = bloc;
    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImageApp',
      message: 'navigation bloc initialized reason=$reason',
    );
    return bloc;
  }

  void _handlePreloadComplete() {
    if (!mounted) return;
    PerfLogger.log(
      widgetName: 'QuranImageApp',
      message:
          'preload complete received navigationBlocReady=${_navigationBloc != null}',
    );
    _ensureNavigationBlocInitialized(reason: 'preload-complete');
    setState(() {
      _isPreloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    final bloc = _ensureNavigationBlocInitialized(reason: 'app-build');

    final app = BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        onGenerateTitle: (context) => const AppTitleMessage().localize(
          QuranImageLocalizations.of(context),
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: QuranImageLocalizations.localizationsDelegates,
        supportedLocales: QuranImageLocalizations.supportedLocales,
        locale: const Locale('ar'),
        theme: _appTheme,
        home: _isPreloaded
            ? const _QuranReaderHome()
            : PreloadingScreen(onPreloadComplete: _handlePreloadComplete),
      ),
    );

    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImageApp',
      message:
          'build isPreloaded=$_isPreloaded '
          'navigationBlocReady=${_navigationBloc != null}',
    );
    return app;
  }
}

class _QuranReaderHome extends StatelessWidget {
  const _QuranReaderHome();

  @override
  Widget build(BuildContext context) {
    final sw = PerfLogger.startTimer();
    final child = BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (previous, current) {
        // Rebuild on initial load, error, or recovery from error.
        if (previous is NavigationLoaded && current is NavigationLoaded) {
          return false;
        }
        return current is NavigationLoaded || current is NavigationError;
      },
      builder: (context, state) {
        final builderSw = PerfLogger.startTimer();
        late final Widget result;

        if (state is NavigationLoaded) {
          result = const QuranImageReader();
        } else if (state is NavigationError) {
          final l10n = QuranImageLocalizations.of(context);
          result = Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      onPressed: () => context.read<NavigationBloc>().add(
                        const NavigationRetryRequested(),
                      ),
                      child: Text(const RetryMessage().localize(l10n)),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Silent loading state with matching background.
          result = Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        }

        PerfLogger.logElapsed(
          builderSw,
          widgetName: 'QuranReaderHome',
          message: 'builder state=${state.runtimeType}',
        );
        return result;
      },
    );

    PerfLogger.logElapsed(sw, widgetName: 'QuranReaderHome', message: 'build');
    return child;
  }
}
