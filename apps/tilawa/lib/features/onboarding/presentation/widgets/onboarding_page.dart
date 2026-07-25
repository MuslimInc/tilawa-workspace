import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'onboarding_content.dart';
import 'onboarding_hero_visual.dart';
import 'onboarding_title_block.dart';

/// Single onboarding slide — spacing aligned with [TilawaIllustratedState].
///
/// Plays a one-shot staggered fade/slide-in for hero → title → body when the
/// page becomes active. No looping. Instant under reduced motion.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.content,
    required this.semanticsLabel,
    this.isActive = true,
  });

  final OnboardingContent content;
  final String semanticsLabel;

  /// When true, runs the entrance once the page settles.
  final bool isActive;

  /// Test keys for entrance layers.
  static const Key heroMotionKey = Key('onboarding_page_hero_motion');
  static const Key titleMotionKey = Key('onboarding_page_title_motion');
  static const Key bodyMotionKey = Key('onboarding_page_body_motion');

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  static const double _slideBegin = 0.035;

  late final AnimationController _controller;
  late final Animation<double> _heroOpacity;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _bodyOpacity;
  late final Animation<Offset> _bodySlide;
  bool _hasPlayedEntrance = false;
  bool _entranceScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _heroOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, _slideBegin),
      end: Offset.zero,
    ).animate(_heroOpacity);
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.72, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, _slideBegin),
      end: Offset.zero,
    ).animate(_titleOpacity);
    _bodyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 1, curve: Curves.easeOutCubic),
    );
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, _slideBegin),
      end: Offset.zero,
    ).animate(_bodyOpacity);
    // Inactive pages stay at 0 until first activation so the stagger can
    // play as they settle — viewport clips them while off-screen.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    _controller.duration = tokens.durationMedium;
    if (widget.isActive) {
      _scheduleEntrance();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleEntrance();
    }
  }

  void _scheduleEntrance() {
    if (_hasPlayedEntrance || _entranceScheduled) {
      return;
    }
    _entranceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _playEntrance());
  }

  void _playEntrance() {
    if (!mounted || _hasPlayedEntrance) {
      return;
    }
    _hasPlayedEntrance = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaEmptyStateTokens stateTokens = theme.componentTokens.emptyState;

    return Semantics(
      label: widget.semanticsLabel,
      child: TilawaContentBounds(
        kind: TilawaContentKind.form,
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: stateTokens.padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FadeTransition(
                      key: OnboardingPage.heroMotionKey,
                      opacity: _heroOpacity,
                      child: SlideTransition(
                        position: _heroSlide,
                        child: OnboardingHeroVisual(
                          assetPath: widget.content.imagePath,
                          style: widget.content.heroStyle,
                        ),
                      ),
                    ),
                    SizedBox(height: stateTokens.titleSpacing),
                    FadeTransition(
                      key: OnboardingPage.titleMotionKey,
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: OnboardingTitleBlock(
                          title: widget.content.title,
                          lineSpacing: tokens.spaceSmall,
                        ),
                      ),
                    ),
                    if (widget.content.visualHint != null) ...<Widget>[
                      SizedBox(height: tokens.spaceExtraSmall),
                      FadeTransition(
                        opacity: _bodyOpacity,
                        child: Text(
                          widget.content.visualHint!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            height: tokens.textHeightLoose,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: stateTokens.subtitleSpacing),
                    FadeTransition(
                      key: OnboardingPage.bodyMotionKey,
                      opacity: _bodyOpacity,
                      child: SlideTransition(
                        position: _bodySlide,
                        child: TilawaReservedTextLines(
                          text: widget.content.description,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ) ??
                              TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                                fontSize: 14,
                              ),
                          maxLines: 3,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
