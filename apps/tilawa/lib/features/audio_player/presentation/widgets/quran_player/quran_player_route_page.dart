part of 'quran_player_widget.dart';

/// Full-screen expanded player presented via [QuranPlayerExpandedRoute].
class QuranPlayerExpandedPageContent extends StatelessWidget {
  const QuranPlayerExpandedPageContent({
    super.key,
    required this.expandAnimation,
    required this.onCollapse,
    required this.onDismiss,
    required this.onExpandDragStart,
    required this.onExpandDragUpdate,
    required this.onExpandDragEnd,
  });

  final Animation<double> expandAnimation;
  final VoidCallback onCollapse;
  final VoidCallback onDismiss;
  final VoidCallback onExpandDragStart;
  final ValueChanged<double> onExpandDragUpdate;
  final ValueChanged<DragEndDetails> onExpandDragEnd;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final String? message = state.failure?.localizedMessage(context);
        if (message != null) {
          TilawaFeedback.showToast(
            context,
            message: message,
            variant: TilawaFeedbackVariant.error,
          );
        }
      },
      buildWhen: QuranPlayerTransportControls.playerTreeBuildWhen,
      builder: (context, state) {
        final AudioEntity? current = state.currentAudio;
        if (current == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) {
              return;
            }
            getIt<PlayerPresentationController>().onRouteClosed();
            if (context.canPop()) {
              context.pop();
            }
          });
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: expandAnimation,
          builder: (context, child) {
            final PlayerExpandTransitionMetrics metrics =
                PlayerExpandTransitionMetrics.compute(
                  progress: expandAnimation.value,
                  miniPlayerHeight: 0,
                );
            return PlayerExpandMetricsScope(
              metrics: metrics,
              child: child!,
            );
          },
          child: _ExpandedPlayerOrganism(
            state: state,
            audio: current,
            expandAnimation: expandAnimation,
            useHeroArtwork: true,
            onCollapse: onCollapse,
            onDismiss: onDismiss,
            onPlayerExpandDragStart: onExpandDragStart,
            onPlayerExpandDragUpdate: onExpandDragUpdate,
            onPlayerExpandDragEnd: onExpandDragEnd,
          ),
        );
      },
    );
  }
}

final class _QuranPlayerShellOverlayHost implements PlayerShellOverlayHost {
  _QuranPlayerShellOverlayHost(this._state);

  final QuranPlayerWidgetState _state;

  @override
  Future<void> expand() => _state._expandShellOverlay();

  @override
  Future<void> collapse() => _state._collapseShellOverlay();
}
