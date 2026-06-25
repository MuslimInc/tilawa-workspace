import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/telemetry/startup_perf_log.dart';

/// Schedules offscreen Skia shader warmup after the app shell mounts.
///
/// Splash-time full-screen warmup was removed: it compiled shaders in a layer
/// tree that did not cache-hit on the real home hero, and overlapped splash
/// teardown raster spikes. Production geometry is painted once, far off-screen.
class StartupBlurShaderWarmup {
  StartupBlurShaderWarmup._();

  static const int _maxScheduleRetries = 60;

  static bool _inserted = false;
  static int _retryCount = 0;
  static OverlayEntry? _entry;

  /// True after offscreen warmup finishes or scheduling gives up.
  static final ValueNotifier<bool> completed = ValueNotifier<bool>(false);

  /// Whether hero blur may enable without racing offscreen warmup.
  static bool get isComplete => completed.value;

  static void _markComplete() {
    if (completed.value) {
      return;
    }
    completed.value = true;
  }

  /// Inserts a one-shot offscreen warmup overlay; safe to call multiple times.
  ///
  /// [resolveOverlay] should return the root navigator overlay (e.g.
  /// [NavigatorState.overlay] from the app root key). [MaterialApp.builder]
  /// runs above the navigator, so the first call often retries post-frame.
  static void scheduleOnce({
    required OverlayState? Function() resolveOverlay,
  }) {
    if (_inserted) {
      StartupPerfLog.log(
        'blur_warmup_schedule_skipped',
        detail: 'already_scheduled',
      );
      return;
    }
    _tryInsert(resolveOverlay);
  }

  static void _tryInsert(OverlayState? Function() resolveOverlay) {
    if (_inserted) {
      return;
    }
    final OverlayState? overlay = resolveOverlay();
    if (overlay == null) {
      _scheduleRetry(resolveOverlay, reason: 'overlay_unavailable');
      return;
    }
    _inserted = true;
    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return const _OffscreenWarmupHost();
      },
    );
    overlay.insert(_entry!);
    StartupPerfLog.log('blur_warmup_overlay_inserted');
  }

  static void _scheduleRetry(
    OverlayState? Function() resolveOverlay, {
    required String reason,
  }) {
    if (_retryCount >= _maxScheduleRetries) {
      StartupPerfLog.log(
        'blur_warmup_schedule_skipped',
        detail: 'max_retries reason=$reason',
      );
      _markComplete();
      return;
    }
    _retryCount++;
    StartupPerfLog.log(
      'blur_warmup_schedule_retry',
      detail: 'attempt=$_retryCount reason=$reason',
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _tryInsert(resolveOverlay);
    });
  }

  @visibleForTesting
  static void resetForTest() {
    _inserted = false;
    _retryCount = 0;
    _entry?.remove();
    _entry = null;
    completed.value = false;
  }

  @visibleForTesting
  static void completeForTest() {
    _markComplete();
  }
}

/// Phases hero blur then nav shadow for widget tests and offscreen host.
class StartupBlurShaderWarmupWidget extends StatefulWidget {
  const StartupBlurShaderWarmupWidget({super.key});

  @override
  State<StartupBlurShaderWarmupWidget> createState() =>
      _StartupBlurShaderWarmupWidgetState();
}

enum _WarmupPhase {
  heroBlurPanel,
  navShadow,
  complete,
}

class _StartupBlurShaderWarmupWidgetState
    extends State<StartupBlurShaderWarmupWidget> {
  _WarmupPhase _phase = _WarmupPhase.heroBlurPanel;

  @override
  void initState() {
    super.initState();
    _scheduleNextPhase();
  }

  void _scheduleNextPhase() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final _WarmupPhase? next = switch (_phase) {
        _WarmupPhase.heroBlurPanel => _WarmupPhase.navShadow,
        _WarmupPhase.navShadow => _WarmupPhase.complete,
        _WarmupPhase.complete => null,
      };
      if (next == null) {
        return;
      }
      setState(() => _phase = next);
      if (next != _WarmupPhase.complete) {
        _scheduleNextPhase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _WarmupLayerStack(phase: _phase),
    );
  }
}

class _OffscreenWarmupHost extends StatefulWidget {
  const _OffscreenWarmupHost();

  @override
  State<_OffscreenWarmupHost> createState() => _OffscreenWarmupHostState();
}

class _OffscreenWarmupHostState extends State<_OffscreenWarmupHost> {
  _WarmupPhase _phase = _WarmupPhase.heroBlurPanel;

  @override
  void initState() {
    super.initState();
    StartupPerfLog.log('blur_warmup_host_init', detail: 'phase=heroBlurPanel');
    _scheduleNextPhase();
  }

  void _scheduleNextPhase() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_phase == _WarmupPhase.complete) {
        StartupPerfLog.log('blur_warmup_overlay_removed');
        StartupBlurShaderWarmup._markComplete();
        StartupBlurShaderWarmup._entry?.remove();
        StartupBlurShaderWarmup._entry = null;
        return;
      }
      final _WarmupPhase next = switch (_phase) {
        _WarmupPhase.heroBlurPanel => _WarmupPhase.navShadow,
        _WarmupPhase.navShadow => _WarmupPhase.complete,
        _WarmupPhase.complete => _WarmupPhase.complete,
      };
      StartupPerfLog.log('blur_warmup_phase', detail: 'next=${next.name}');
      setState(() => _phase = next);
      _scheduleNextPhase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.translate(
          offset: const Offset(-10000, 0),
          child: _WarmupLayerStack(phase: _phase),
        ),
      ),
    );
  }
}

class _WarmupLayerStack extends StatelessWidget {
  const _WarmupLayerStack({required this.phase});

  final _WarmupPhase phase;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        if (phase.index >= _WarmupPhase.heroBlurPanel.index)
          const _HeroBlurPanelWarmup(),
        if (phase.index >= _WarmupPhase.navShadow.index)
          const _NavShadowWarmup(),
      ],
    );
  }
}

/// Matches [HomeHeroGlassSurface] clip + blur + bordered fill at token sizes.
class _HeroBlurPanelWarmup extends StatelessWidget {
  const _HeroBlurPanelWarmup();

  // MeMuslimDesignTokens defaults — keep in sync with ui_kit tokens.
  static const double _blurSigma = 12;
  static const double _spaceMedium = 12;
  static const double _radiusLarge = 20;
  static const double _borderWidthThin = 0.5;
  static const double _panelHeight = 132;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width - (2 * _spaceMedium);
    final BorderRadius radius = BorderRadius.circular(_radiusLarge);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _blurSigma,
              sigmaY: _blurSigma,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppBootstrapShaderWarmupColors.blurPanelFill,
                borderRadius: radius,
                border: Border.all(
                  color: AppBootstrapShaderWarmupColors.blurPanelFill,
                  width: _borderWidthThin,
                ),
              ),
              child: SizedBox(width: width, height: _panelHeight),
            ),
          ),
        ),
      ),
    );
  }
}

/// Matches [TilawaAdaptiveShellTokens] light-chrome bottom-nav shadow.
class _NavShadowWarmup extends StatelessWidget {
  const _NavShadowWarmup();

  static const List<BoxShadow> _navShadow = <BoxShadow>[
    BoxShadow(
      color: AppBootstrapShaderWarmupColors.navShadow,
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: _navShadow,
          color: AppBootstrapShaderWarmupColors.blurPanelFill,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const SizedBox(width: 120, height: 56),
      ),
    );
  }
}
