import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/core/di/injection.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../features/audio_player/presentation/cubit/player_background_cubit.dart';
import '../features/auth/data/services/pending_session_revoke_store.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/cubit/session_validity_cubit.dart';
import '../features/auth/presentation/cubit/session_verification_cubit.dart';
import '../features/auth/presentation/widgets/account_deletion_navigation_listener.dart';
import '../features/auth/presentation/widgets/device_revoked_sign_out_listener.dart';
import '../features/auth/presentation/widgets/session_revoked_navigation_listener.dart';
import '../features/localization/presentation/bloc/localization_bloc.dart';
import '../features/quran_sessions/quran_sessions_platform_config_store.dart';
import '../features/quran_sessions/presentation/widgets/session_taken_over_listener.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/theme/presentation/cubit/theme_cubit.dart';
import '../shared/widgets/quran_player_chrome.dart';

/// App-level [BlocProvider] tree (composition root).
///
/// Feature-scoped blocs live in `*ScreenScope` widgets at route or tab level.
/// Lives under `lib/app/` so `core/` does not import feature presentation.
class AppProviders {
  /// Returns a list of all app-wide BlocProviders.
  static List<BlocProvider> get providers => [
    BlocProvider<ThemeCubit>(create: (context) => getIt<ThemeCubit>()),
    BlocProvider<LocalizationBloc>(
      create: (context) => getIt<LocalizationBloc>(),
    ),
    BlocProvider<SettingsCubit>(
      create: (context) => getIt<SettingsCubit>(),
      lazy: false,
    ),
    BlocProvider<AudioPlayerBloc>(
      create: (context) => getIt<AudioPlayerBloc>(),
    ),
    BlocProvider<PlayerBackgroundCubit>(
      create: (context) => getIt<PlayerBackgroundCubit>(),
    ),
    BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>()..add(const CheckAuthStatusEvent()),
    ),
    BlocProvider<SessionValidityCubit>(
      create: (_) => getIt<SessionValidityCubit>(),
    ),
    // Non-lazy: must subscribe to authStateChanges at launch so a transient
    // sign-out is caught. Inert unless the hardening flag is on.
    BlocProvider<SessionVerificationCubit>(
      create: (_) => getIt<SessionVerificationCubit>(),
      lazy: false,
    ),
  ];

  static Widget create({required Widget child}) {
    Widget content = MultiBlocProvider(
      providers: providers,
      child: ChangeNotifierProvider<QuranPlayerChromeNotifier>(
        create: (_) => QuranPlayerChromeNotifier(),
        child: BlocListener<SessionValidityCubit, SessionValidityState>(
          listenWhen:
              (SessionValidityState previous, SessionValidityState current) =>
                  !previous.revoked && current.revoked,
          listener: (BuildContext context, SessionValidityState state) {
            context.read<AuthBloc>().add(const SessionInvalidatedEvent());
          },
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                (previous is! AuthAuthenticated &&
                    current is AuthAuthenticated) ||
                (previous is AuthAuthenticated &&
                    current is AuthUnauthenticated),
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                // Confirmed/intentional sign-out — suppress the transient
                // "verifying" banner for the null that follows.
                context.read<SessionVerificationCubit>().noteSessionEnded();
                return;
              }
              context.read<SessionValidityCubit>().resetRevocation();
              unawaited(PendingSessionRevokeStore.clear());
            },
            child: DeviceRevokedSignOutListener(
              child: SessionRevokedNavigationListener(
                child: SessionTakenOverListener(
                  child: AccountDeletionNavigationListener(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (getIt.isRegistered<QuranSessionsPlatformConfigStore>()) {
      content = ChangeNotifierProvider<QuranSessionsPlatformConfigStore>.value(
        value: getIt<QuranSessionsPlatformConfigStore>(),
        child: content,
      );
    }
    return content;
  }
}
