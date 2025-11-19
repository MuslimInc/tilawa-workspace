import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/core/di/injection.dart';
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/playlists/presentation/bloc/playlists_bloc.dart';
import 'package:muzakri/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart';

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
    BlocProvider<DownloadsBloc>(create: (context) => getIt<DownloadsBloc>()),
    BlocProvider<PlaylistsBloc>(create: (context) => getIt<PlaylistsBloc>()),
    BlocProvider<PremiumBloc>(create: (context) => getIt<PremiumBloc>()),

    // Auth provider with initialization
    BlocProvider<AuthBloc>(
      create: (context) {
        final authBloc = getIt<AuthBloc>();
        authBloc.add(const CheckAuthStatusEvent());
        return authBloc;
      },
    ),
  ];

  /// Creates a MultiBlocProvider widget with all the configured providers.
  ///
  /// This is a convenience method that wraps all providers in a MultiBlocProvider
  /// and can be used directly in the widget tree.
  static Widget create({required Widget child}) {
    return MultiBlocProvider(providers: providers, child: child);
  }
}
