import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tilawa/core/bootstrap/startup_blur_shader_warmup.dart';
import 'package:tilawa/core/telemetry/startup_perf_log.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Frosted glass panel for readable hero metrics on the neutral canvas.
class HomeHeroGlassSurface extends StatelessWidget {
  const HomeHeroGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;
    final BorderRadius resolvedRadius =
        borderRadius ?? BorderRadius.circular(tokens.radiusLarge);
    final Color fill = colorScheme.surface.withValues(alpha: 0.90);
    final Color border = colorScheme.outlineVariant.withValues(alpha: 0.48);

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

    final Widget frostedPanel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: tokens.opacityShadowStrong,
            ),
            blurRadius: tokens.blurShadow * 1.35,
            offset: Offset(0, tokens.shadowOffsetMedium.dy),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.04),
            blurRadius: tokens.blurShadow * 0.6,
            offset: Offset(0, tokens.shadowOffsetSmall.dy),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: tokens.blurGlass * 1.1,
            sigmaY: tokens.blurGlass * 1.1,
          ),
          child: decoratedChild,
        ),
      ),
    );

    final Widget panel = _DeferredHomeHeroBlur(
      placeholder: ClipRRect(
        borderRadius: resolvedRadius,
        child: decoratedChild,
      ),
      child: frostedPanel,
    );

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
