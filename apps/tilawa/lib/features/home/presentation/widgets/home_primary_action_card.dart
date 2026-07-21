import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_state.dart';
import 'package:tilawa/features/home/presentation/cubit/home_primary_action_state.dart';
import 'package:tilawa_core/entities/entities.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';
import 'home_quran_resume_card.dart';

/// Featured primary action card — gradient only for Quran resume.
class HomePrimaryActionCard extends StatelessWidget {
  const HomePrimaryActionCard({super.key, required this.state});

  final HomePrimaryActionState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.kind) {
      HomePrimaryActionKind.quran => const HomeQuranResumeCard(
        featured: true,
      ),
      HomePrimaryActionKind.listening => const _HomePrimaryListeningCard(),
      HomePrimaryActionKind.athkar => const HomeQuranResumeCard(
        featured: true,
      ),
    };
  }
}

/// Subtle press feedback: scales down to 0.98 on tap-down, returns on
/// tap-up. Gives tactile micro-interaction per emotional design principles.
class HomePrimaryCardPressWrapper extends StatefulWidget {
  const HomePrimaryCardPressWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<HomePrimaryCardPressWrapper> createState() =>
      _HomePrimaryCardPressWrapperState();
}

class _HomePrimaryCardPressWrapperState
    extends State<HomePrimaryCardPressWrapper>
    with SingleTickerProviderStateMixin {
  static const double _pressedScale = 0.98;

  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1, end: _pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) => _controller.reverse();

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _HomePrimaryListeningCard extends StatelessWidget {
  const _HomePrimaryListeningCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeListeningResumeCubit, HomeListeningResumeState>(
      builder: (context, listeningState) {
        if (!listeningState.isVisible) {
          return const HomeQuranResumeCard(featured: true);
        }

        final tokens = context.tokens;
        final theme = Theme.of(context);
        final cardTokens = theme.componentTokens.homeDashboardCard;
        final Color foreground = theme.colorScheme.onSurface;

        return HomePrimaryCardPressWrapper(
          child: Semantics(
            button: true,
            label: context.l10n.continueListening,
            value: context.l10n.homeListeningResumeSubtitle(
              listeningState.reciterName!,
              listeningState.surahName!,
            ),
            child: HomeDashboardCard(
              surface: TilawaCardSurface.raised,
              onTap: () => _resumePlayback(context, listeningState),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    color: theme.colorScheme.primary,
                    size: tokens.iconSizeLarge,
                  ),
                  SizedBox(width: tokens.spaceMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.continueListening,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: tokens.spaceExtraSmall),
                        Text(
                          context.l10n.homeListeningResumeSubtitle(
                            listeningState.reciterName!,
                            listeningState.surahName!,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: foreground.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cardTokens.foregroundColor.withValues(alpha: 0.82),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resumePlayback(
    BuildContext context,
    HomeListeningResumeState state,
  ) {
    final audio = AudioEntity(
      id: state.audioUrl!,
      title: state.surahName!,
      url: state.audioUrl!,
      duration: Duration(milliseconds: state.durationMs),
      artist: state.reciterName,
      album: state.moshafName,
      artUri: state.artworkUrl,
      extras: {
        'surahId': state.surahId,
        'reciterId': state.reciterId,
        'moshafId': state.moshafId,
      },
    );

    context.read<AudioPlayerBloc>().add(
      AudioPlayerEvent.playFromQueue(
        [audio],
        0,
        initialPosition: state.resumeInitialPosition,
      ),
    );
  }
}
