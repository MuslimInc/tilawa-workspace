import 'package:flutter/material.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/audio_player/presentation/player_presentation_controller.dart';
import 'package:tilawa/shared/widgets/quran_player_widget.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Root overlay page for [QuranPlayerExpandedRoute] (`/player`).
class QuranPlayerExpandedPage extends StatefulWidget {
  const QuranPlayerExpandedPage({super.key});

  @override
  State<QuranPlayerExpandedPage> createState() =>
      _QuranPlayerExpandedPageState();
}

class _QuranPlayerExpandedPageState extends State<QuranPlayerExpandedPage> {
  PlayerPresentationController get _controller =>
      getIt<PlayerPresentationController>();

  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.onRouteOpened();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Animation<double>? routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation != null && routeAnimation != _routeAnimation) {
      _routeAnimation?.removeListener(_onAnimationTick);
      _routeAnimation?.removeStatusListener(_onAnimationStatus);
      _routeAnimation = routeAnimation;
      _routeAnimation!.addListener(_onAnimationTick);
      _routeAnimation!.addStatusListener(_onAnimationStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeListener(_onAnimationTick);
    _routeAnimation?.removeStatusListener(_onAnimationStatus);
    super.dispose();
  }

  void _onAnimationTick() {
    final Animation<double>? animation = _routeAnimation;
    if (animation == null) {
      return;
    }
    _controller.onRouteAnimationTick(animation.value, animation.status);
  }

  void _onAnimationStatus(AnimationStatus status) {
    _onAnimationTick();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation =
        _routeAnimation ?? const AlwaysStoppedAnimation<double>(0);

    return QuranPlayerExpandedPageContent(
      expandAnimation: animation,
      onCollapse: _controller.collapse,
      onDismiss: _controller.dismissPlayer,
      onExpandDragStart: _controller.onHeroExpandedDragStart,
      onExpandDragUpdate: _controller.onHeroExpandedDragUpdate,
      onExpandDragEnd: (details) {
        final tokens = Theme.of(context).tokens;
        _controller.onHeroExpandedDragEnd(
          primaryVelocity: details.primaryVelocity ?? 0,
          progressThreshold: tokens.playerProgressThreshold,
          velocityThreshold: tokens.playerVelocityThreshold,
        );
      },
    );
  }
}
