import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/core/di/injection.dart';
import '../core/presentation/cubit/ui_visibility_cubit.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/downloads/domain/repositories/downloads_repository.dart';
import '../features/downloads/presentation/bloc/downloads_bloc.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';
import '../features/playlists/presentation/bloc/playlists_bloc.dart';
import '../features/quran_reader/presentation/bloc/quran_font_loader_bloc.dart';
import '../features/quran_reader/presentation/bloc/quran_reader_bloc.dart';
import '../features/quran_reader/presentation/cubit/quran_settings_cubit.dart';
import '../features/reciters/presentation/bloc/reciter_details_bloc.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/share/presentation/cubit/share_cubit.dart';
import '../features/theme/presentation/cubit/theme_cubit.dart';
import '../shared/widgets/quran_player_chrome.dart';

/// App-level [BlocProvider] and [RepositoryProvider] tree (composition root).
///
/// Lives under `lib/app/` so `core/` does not import feature presentation.
class AppProviders {
  /// Returns a list of all BlocProviders used throughout the application.
  static List<BlocProvider> get providers => [
    BlocProvider<ThemeCubit>(create: (context) => getIt<ThemeCubit>()),
    BlocProvider<LocalizationBloc>(
      create: (context) => getIt<LocalizationBloc>(),
    ),
    BlocProvider<SettingsCubit>(
      create: (context) => getIt<SettingsCubit>(),
      lazy: false,
    ),
    BlocProvider<ReciterDetailsBloc>(
      create: (context) => getIt<ReciterDetailsBloc>(),
    ),
    BlocProvider<AudioPlayerBloc>(
      create: (context) => getIt<AudioPlayerBloc>(),
    ),
    BlocProvider<PlayerBackgroundCubit>(
      create: (context) => getIt<PlayerBackgroundCubit>(),
    ),
    BlocProvider<DownloadsBloc>(create: (context) => getIt<DownloadsBloc>()),
    BlocProvider<PlaylistsBloc>(create: (context) => getIt<PlaylistsBloc>()),
    BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>()..add(const CheckAuthStatusEvent()),
    ),
    BlocProvider<QuranFontLoaderBloc>(
      create: (context) => getIt<QuranFontLoaderBloc>(),
    ),
    BlocProvider<QuranReaderBloc>(
      create: (context) =>
          getIt<QuranReaderBloc>()..add(const QuranReaderEvent.loadLastRead()),
    ),
    BlocProvider<QuranSettingsCubit>(
      create: (context) => getIt<QuranSettingsCubit>()..load(),
    ),
    BlocProvider<UiVisibilityCubit>(
      create: (context) => getIt<UiVisibilityCubit>(),
    ),
    BlocProvider<ShareCubit>(create: (context) => getIt<ShareCubit>()),
  ];

  static List<RepositoryProvider> get repositories => [
    RepositoryProvider<DownloadsRepository>(
      create: (context) => getIt<DownloadsRepository>(),
    ),
  ];

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
