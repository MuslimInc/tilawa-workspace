import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../cubit/recitation_practice_cubit.dart';
import '../cubit/recitation_practice_state.dart';
import 'recitation_practice_panel.dart';

typedef RecitationPracticeBuilder =
    Widget Function(
      BuildContext context,
      Future<void> Function(int pageNumber) openPractice,
    );

/// Provides [RecitationPracticeCubit], pauses playback while listening, and
/// overlays the practice panel (and optional mic FAB) on a Mushaf reader.
class RecitationPracticeHost extends StatefulWidget {
  const RecitationPracticeHost({
    super.key,
    required this.builder,
    this.currentPageListenable,
    this.showFloatingMic = false,
  });

  final RecitationPracticeBuilder builder;
  final ValueListenable<int>? currentPageListenable;
  final bool showFloatingMic;

  @override
  State<RecitationPracticeHost> createState() => _RecitationPracticeHostState();
}

class _RecitationPracticeHostState extends State<RecitationPracticeHost> {
  late final RecitationPracticeCubit _cubit = getIt<RecitationPracticeCubit>();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  Future<void> _openPractice(int pageNumber) {
    return _cubit.openForPage(pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecitationPracticeCubit>.value(
      value: _cubit,
      child: BlocListener<RecitationPracticeCubit, RecitationPracticeState>(
        listenWhen: (RecitationPracticeState previous, current) =>
            previous.phase != RecitationPracticePhase.listening &&
            current.phase == RecitationPracticePhase.listening,
        listener: (BuildContext context, RecitationPracticeState state) {
          context.read<AudioPlayerBloc>().add(
            const AudioPlayerEvent.pauseAudio(),
          );
        },
        child: Stack(
          children: [
            widget.builder(context, _openPractice),
            const RecitationPracticePanel(),
            if (widget.showFloatingMic && widget.currentPageListenable != null)
              ValueListenableBuilder<int>(
                valueListenable: widget.currentPageListenable!,
                builder: (BuildContext context, int currentPage, _) {
                  return _RecitationPracticeFab(
                    currentPage: currentPage,
                    onPressed: () => unawaited(_openPractice(currentPage)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RecitationPracticeFab extends StatelessWidget {
  const _RecitationPracticeFab({
    required this.currentPage,
    required this.onPressed,
  });

  final int currentPage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Positioned(
      left: tokens.spaceMedium,
      bottom: context.floatingBottomPadding + 120,
      child: FloatingActionButton.small(
        heroTag: 'recitation-practice-$currentPage',
        tooltip: context.l10n.recitationPracticeTooltip,
        onPressed: onPressed,
        child: const Icon(Icons.mic_rounded),
      ),
    );
  }
}
