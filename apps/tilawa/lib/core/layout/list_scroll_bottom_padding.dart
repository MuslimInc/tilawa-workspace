import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/audio_player/presentation/widgets/quran_player/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Bottom padding for scrollable lists so the last item clears shell chrome
/// and/or the mini-player.
double listScrollBottomPadding(BuildContext context) {
  final double shell = context.shellHostedScrollBottomPadding;
  if (shell > 0) {
    return shell;
  }
  return _standaloneScrollBottomPadding(context);
}

/// Extra bottom inset for [TilawaBottomActionInset] above
/// [TilawaSafeAreaX.floatingBottomPadding].
double bottomActionExtraInset(BuildContext context) {
  return math.max(
    0,
    listScrollBottomPadding(context) - context.floatingBottomPadding,
  );
}

double _standaloneScrollBottomPadding(BuildContext context) {
  try {
    if (context.read<AudioPlayerBloc>().state.shouldShowBottomPlayer) {
      return QuranPlayerWidget.collapsedFootprint(context);
    }
  } on ProviderNotFoundException {
    // No [AudioPlayerBloc] above this context.
  }
  return context.floatingBottomPadding;
}
