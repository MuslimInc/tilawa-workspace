import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../features/app_review/domain/services/app_review_flow_guard.dart';
import '../features/app_review/domain/services/app_review_trigger_manager.dart';
import '../features/audio_player/presentation/bloc/audio_player_bloc.dart';
import '../shared/widgets/quran_player_widget.dart';
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
      listener: (_, MainScreenState state) {
        getIt<AppReviewFlowGuard>().syncMainShellTab(state.currentIndex);
        unawaited(getIt<AppReviewTriggerManager>().onSessionStarted());
      },
      child: BlocBuilder<MainScreenCubit, MainScreenState>(
        builder: (context, state) {
          if (!state.isShellActivated) {
            return const _MainShellPlaceholderScaffold();
          }

        final bool isKeyboardOpen = context.isKeyboardVisible;
        final bool playerShouldShow = state.isAudioBindingDeferred
            ? false
            : context.select((AudioPlayerBloc bloc) {
                final AudioPlayerState audioState = bloc.state;
                return audioState.shouldShowBottomPlayer &&
                    audioState.currentAudio != null;
              });

        final double playerHeight = playerShouldShow && !isKeyboardOpen
            ? context.tokens.playerCollapsedHeight
            : 0;
        final double overlayBleedBuffer =
            (playerShouldShow && !isKeyboardOpen && !context.isNarrow)
            ? context.tokens.spaceSmall
            : 0;

        final double contentBottomPadding = isKeyboardOpen
            ? 0
            : context.isNarrow
            ? (playerShouldShow ? playerHeight + overlayBleedBuffer : 0)
            : QuranPlayerWidget.collapsedFootprint(context);

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
