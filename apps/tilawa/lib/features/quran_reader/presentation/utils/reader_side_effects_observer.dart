import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa_core/services/interfaces/keep_awake_service.dart';

import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';

/// Mixin that manages audio-pause and keep-awake side effects for the
/// Quran reader lifecycle.
///
/// Separates these cross-feature concerns from [QuranReaderScreen] so the
/// screen only handles UI composition.
///
/// Usage: mix into a [State] that also has [WidgetsBindingObserver].
mixin ReaderSideEffectsObserver<T extends StatefulWidget> on State<T> {
  late final KeepAwakeService _keepAwakeService;

  @protected
  void initSideEffects() {
    _keepAwakeService = getIt<KeepAwakeService>();
    _keepAwakeService.enable();

    final audioBloc = context.read<AudioPlayerBloc>();
    if (audioBloc.state.isPlaying) {
      audioBloc.add(const AudioPlayerEvent.pauseAudio());
    }
  }

  @protected
  void disposeSideEffects() {
    _keepAwakeService.disable();
  }

  @protected
  void onResumedSideEffects() {
    _keepAwakeService.enable();
  }

  @protected
  void onPausedSideEffects() {
    _keepAwakeService.disable();
  }
}
