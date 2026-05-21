import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:tilawa_core/di/injection.dart';

import '../../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/downloads/domain/repositories/downloads_repository.dart';
import '../../features/downloads/presentation/bloc/downloads_bloc.dart';
import '../../features/localization/presentation/bloc/localization_bloc.dart';
import '../../features/playlists/presentation/bloc/playlists_bloc.dart';
import '../../features/quran_reader/presentation/bloc/quran_font_loader_bloc.dart';
import '../../features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import '../../features/quran_reader/presentation/cubit/quran_settings_cubit.dart';
import '../../features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import '../../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../../features/reciters/presentation/bloc/reciters_bloc.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/share/presentation/cubit/share_cubit.dart';
import '../../features/theme/presentation/cubit/theme_cubit.dart';
import '../presentation/cubit/ui_visibility_cubit.dart';
import '../../shared/widgets/quran_player_chrome.dart';

/// Centralized configuration for all BlocProviders in the application.
/// This class provides a single place to manage all state management providers.
class AppProviders {
  /// Returns a list of all BlocProviders used throughout the application.
  ///
  /// This method centralizes the provider configuration, making it easier to:
  /// - Add new providers
  /// - Remove existing providers
  /// - Modify provider configurations
  /// - Maintain consistency across the app
  static List<BlocProvider> get providers => [
    // Core app providers
    BlocProvider<ThemeCubit>(create: (context) => getIt<ThemeCubit>()),
    BlocProvider<LocalizationBloc>(
      create: (context) => getIt<LocalizationBloc>(),
    ),
    BlocProvider<SettingsCubit>(
      create: (context) => getIt<SettingsCubit>(),
      lazy: false,
    ),

    // Feature providers
    BlocProvider<RecitersBloc>(create: (context) => getIt<RecitersBloc>()),
    BlocProvider<ReciterDetailsBloc>(
      create: (context) => getIt<ReciterDetailsBloc>(),
    ),
    BlocProvider<AlphabetScrollbarBloc>(
      create: (context) => getIt<AlphabetScrollbarBloc>(),
    ),
    BlocProvider<AudioPlayerBloc>(
      create: (context) => getIt<AudioPlayerBloc>(),
    ),
    BlocProvider<PlayerBackgroundCubit>(
      create: (context) => getIt<PlayerBackgroundCubit>(),
    ),
    BlocProvider<DownloadsBloc>(create: (context) => getIt<DownloadsBloc>()),
    BlocProvider<PlaylistsBloc>(create: (context) => getIt<PlaylistsBloc>()),
    BlocProvider<QiblaBloc>(create: (context) => getIt<QiblaBloc>()),

    // Auth provider with initialization
    BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>()..add(const CheckAuthStatusEvent()),
    ),

    // Font Loader provider — lazy so font-checking I/O only runs when the
    // QuranFontLoaderScreen is first accessed, not at app startup.
    BlocProvider<QuranFontLoaderBloc>(
      create: (context) => getIt<QuranFontLoaderBloc>(),
    ),

    // Quran Reader provider — lazy so last-read loading only runs when the
    // Quran reader is first accessed, not at app startup.
    BlocProvider<QuranReaderBloc>(
      create: (context) =>
          getIt<QuranReaderBloc>()..add(const QuranReaderEvent.loadLastRead()),
    ),
    // Settings cubit — lazy, loads persisted settings on first access.
    BlocProvider<QuranSettingsCubit>(
      create: (context) => getIt<QuranSettingsCubit>()..load(),
    ),
    // UI Visibility provider (Global for immersive mode across routes)
    BlocProvider<UiVisibilityCubit>(
      create: (context) => getIt<UiVisibilityCubit>(),
    ),

    // Share provider — ephemeral cubit for screenshot & audio clip sharing
    BlocProvider<ShareCubit>(create: (context) => getIt<ShareCubit>()),
  ];

  static List<RepositoryProvider> get repositories => [
    RepositoryProvider<DownloadsRepository>(
      create: (context) => getIt<DownloadsRepository>(),
    ),
  ];

  /// Creates a widget tree with all configured providers (Blocs and Repositories).
  static Widget create({required Widget child}) {
    return MultiRepositoryProvider(
      providers: repositories,
      child: MultiBlocProvider(
        providers: providers,
        child: ChangeNotifierProvider<QuranPlayerChromeNotifier>(
          create: (_) => QuranPlayerChromeNotifier(),
          child: child,
        ),
      ),
    );
  }
}
