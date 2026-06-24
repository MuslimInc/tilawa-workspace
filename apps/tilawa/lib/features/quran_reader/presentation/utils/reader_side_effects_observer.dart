import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';

/// Mixin that pauses background audio when entering the Quran reader.
///
/// Keep-awake is enabled app-wide from [TilawaApp] startup.
mixin ReaderSideEffectsObserver<T extends StatefulWidget> on State<T> {
  @protected
  void initSideEffects() {
    final audioBloc = context.read<AudioPlayerBloc>();
    if (audioBloc.state.isPlaying) {
      audioBloc.add(const AudioPlayerEvent.pauseAudio());
    }
  }
}
