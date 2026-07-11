import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/prayer_alerts_permission_navigation.dart';
import 'package:tilawa/features/shell/presentation/shell_tab_effect_dispatcher.dart';
import 'package:tilawa/features/shell/shell.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'cubit/main_screen_cubit.dart';
import 'cubit/main_screen_state.dart';
import 'widgets/main_tab_viewport.dart';

/// Home tab stack inside [AppShellScreen].
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainScreenCubit, MainScreenState>(
      listenWhen: (MainScreenState prev, MainScreenState next) =>
          !prev.isShellActivated && next.isShellActivated,
      listener: (BuildContext context, MainScreenState state) {
        dispatchShellTabEffects(
          context,
          ShellTabCoordinator().onShellActivated(state.currentIndex),
          isMounted: () => context.mounted,
        );
        if (state.isShellActivated) {
          unawaited(
            PrayerAlertsPermissionNavigation.showIfNeededAfterLaunch(context),
          );
        }
      },
      child: BlocBuilder<MainScreenCubit, MainScreenState>(
        builder: (context, state) {
          if (!state.isShellActivated) {
            return const _MainShellPlaceholderScaffold();
          }

          final bool isKeyboardOpen = context.isKeyboardVisible;
          final bool playerShouldShow =
              !state.isAudioBindingDeferred &&
              context.select((AudioPlayerBloc bloc) {
                final AudioPlayerState audioState = bloc.state;
                return audioState.shouldShowBottomPlayer &&
                    audioState.currentAudio != null;
              });

          final double playerHeight = playerShouldShow && !isKeyboardOpen
              ? context.tokens.playerCollapsedHeight
              : 0;
          final double contentBottomPadding = isKeyboardOpen
              ? 0
              : (playerShouldShow ? playerHeight : 0);

          return state.isInitialTabMounted
              ? MainTabViewport(
                  currentIndex: state.currentIndex,
                  builtTabIndexes: state.builtTabIndexes,
                  contentBottomPadding: contentBottomPadding,
                )
              : TilawaShellPadding(
                  padding: contentBottomPadding,
                  child: const _MainShellPlaceholder(),
                );
        },
      ),
    );
  }
}

class _MainShellPlaceholder extends StatelessWidget {
  const _MainShellPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(child: ColoredBox(color: Colors.transparent));
  }
}

class _MainShellPlaceholderScaffold extends StatelessWidget {
  const _MainShellPlaceholderScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      body: _MainShellPlaceholder(),
    );
  }
}
