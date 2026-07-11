import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/core/telemetry/startup_perf_log.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Frosted glass panel for readable hero metrics on the Home canvas.
class HomeHeroGlassSurface extends StatelessWidget {
  const HomeHeroGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.onTap,
    this.usePrayerHeroTokens = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// When true, reads fill, border, and shadow from [TilawaHomeScreenTokens].
  final bool usePrayerHeroTokens;

  /// Subtle backdrop blur on iOS/desktop; Android uses fill + border + shadow.
  static bool get useBackdropBlur =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final BorderRadius resolvedRadius =
        borderRadius ?? BorderRadius.circular(tokens.radiusExtraLarge);

    final Color fill = usePrayerHeroTokens
        ? screenTokens.homePrayerHeroBackground
        : colorScheme.surface.withValues(alpha: 0.90);
    final Color border = usePrayerHeroTokens
        ? screenTokens.homePrayerHeroBorder
        : colorScheme.outlineVariant.withValues(alpha: 0.48);
    final Color shadowColor = usePrayerHeroTokens
        ? screenTokens.homePrayerHeroShadow.withValues(
            alpha: screenTokens.homePrayerHeroShadowOpacity,
          )
        : colorScheme.shadow.withValues(alpha: tokens.opacityShadowStrong);
    final bool showShadow =
        !usePrayerHeroTokens || screenTokens.homePrayerHeroShadowOpacity > 0;

    final Widget decoratedChild = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: border,
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(tokens.spaceMedium),
        child: child,
      ),
    );

    final Widget frostedPanel = ClipRRect(
      borderRadius: resolvedRadius,
      child: _buildFrostedPanel(context, tokens, decoratedChild),
    );

    final Widget panelBody = showShadow
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: resolvedRadius,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: shadowColor,
                  blurRadius: tokens.blurShadow,
                  offset: Offset(0, tokens.shadowOffsetMedium.dy),
                ),
                if (!usePrayerHeroTokens)
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.04),
                    blurRadius: tokens.blurShadow * 0.6,
                    offset: Offset(0, tokens.shadowOffsetSmall.dy),
                  ),
              ],
            ),
            child: frostedPanel,
          )
        : frostedPanel;

    final Widget panel = useBackdropBlur
        ? _DeferredHomeHeroBlur(
            placeholder: panelBody,
            child: panelBody,
          )
        : panelBody;

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: resolvedRadius,
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: panel,
      ),
    );
  }

  Widget _buildFrostedPanel(
    BuildContext context,
    MeMuslimDesignTokens tokens,
    Widget decoratedChild,
  ) {
    if (!useBackdropBlur) {
      return decoratedChild;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: tokens.blurGlass * 0.45,
        sigmaY: tokens.blurGlass * 0.45,
      ),
      child: decoratedChild,
    );
  }
}

/// Defers [BackdropFilter] until frame 1 and offscreen blur warmup complete.
class _DeferredHomeHeroBlur extends StatefulWidget {
  const _DeferredHomeHeroBlur({
    required this.placeholder,
    required this.child,
  });

  final Widget placeholder;
  final Widget child;

  @override
  State<_DeferredHomeHeroBlur> createState() => _DeferredHomeHeroBlurState();
}

class _DeferredHomeHeroBlurState extends State<_DeferredHomeHeroBlur> {
  static const int _maxWaitFrames = 15;
  static const Duration _maxWaitDuration = Duration(milliseconds: 500);

  bool _ready = false;
  bool _waitingLogged = false;
  VoidCallback? _warmupListener;
  Timer? _timeoutTimer;
  int _waitFrames = 0;

  @override
  void initState() {
    super.initState();
    StartupPerfLog.log('home_hero_glass_blur_deferred');
    SchedulerBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  void _afterFirstFrame() {
    if (!mounted || _ready) {
      return;
    }
    if (StartupBlurShaderWarmup.isComplete) {
      _enable(detail: 'after_warmup');
      return;
    }
    _logWaiting();
    _warmupListener = () {
      if (StartupBlurShaderWarmup.isComplete) {
        _enable(detail: 'after_warmup');
      }
    };
    StartupBlurShaderWarmup.completed.addListener(_warmupListener!);
    _timeoutTimer = Timer(_maxWaitDuration, () {
      _enable(detail: 'timeout_ms');
    });
    _scheduleFrameFallback();
  }

  void _scheduleFrameFallback() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ready) {
        return;
      }
      _waitFrames++;
      if (_waitFrames >= _maxWaitFrames) {
        _enable(detail: 'timeout_frames');
        return;
      }
      _scheduleFrameFallback();
    });
  }

  void _logWaiting() {
    if (_waitingLogged) {
      return;
    }
    _waitingLogged = true;
    StartupPerfLog.log(
      'home_hero_glass_blur_waiting',
      detail: 'warmup_pending',
    );
  }

  void _enable({required String detail}) {
    if (_ready || !mounted) {
      return;
    }
    _ready = true;
    _disposeWaiters();
    StartupPerfLog.log('home_hero_glass_blur_enabled', detail: detail);
    setState(() {});
  }

  void _disposeWaiters() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    final VoidCallback? listener = _warmupListener;
    if (listener != null) {
      StartupBlurShaderWarmup.completed.removeListener(listener);
      _warmupListener = null;
    }
  }

  @override
  void dispose() {
    _disposeWaiters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : widget.placeholder;
  }
}
