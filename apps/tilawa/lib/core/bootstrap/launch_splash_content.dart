import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilawa/core/bootstrap/logo_height_log.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Branded launch splash artwork shared by the boot gate overlay and
/// [/splash] route so native → Flutter handoff stays pixel-aligned.
class LaunchSplashContent extends StatefulWidget {
  const LaunchSplashContent({
    super.key,
    this.wordmark,
    this.showProgress = false,
    this.progressDelay = const Duration(seconds: 2),
    this.source = 'LaunchSplashContent',
  });

  /// Optional title below the mark (e.g. localized [appTitle] on `/splash`).
  final String? wordmark;

  /// When true, shows a calm indeterminate bar after [progressDelay].
  final bool showProgress;

  /// Delay before the progress indicator fades in.
  final Duration progressDelay;

  /// Passed to [LogoHeightProbe] for cold-start sizing traces.
  final String source;

  static const String logoAsset = 'assets/images/app_logo.png';

  /// One-shot icon animation duration. Android recommends splash icon
  /// animations stay at or below 1000 ms on phones.
  static const Duration iconAnimationDuration = Duration(milliseconds: 1000);

  /// Keys used by widget tests to verify the launch icon handoff animation.
  static const Key logoOpacityKey = Key('launch_splash_logo_opacity');
  static const Key logoScaleKey = Key('launch_splash_logo_scale');

  /// Same 288 dp frame as the Android 12+ splash icon canvas. Android's native
  /// icon is transparent; Flutter draws this padded frame after handoff so the
  /// mark is not OS-scaled into the full splash circle.
  static const double logoBoxSize = AppColors.launchSplashLogoFrameSize;
  static const Color logoForeground = AppColors.launchSplashForeground;

  @override
  State<LaunchSplashContent> createState() => _LaunchSplashContentState();
}

class _LaunchSplashContentState extends State<LaunchSplashContent>
    with SingleTickerProviderStateMixin {
  static const Duration _progressFadeDuration = Duration(milliseconds: 420);
  static const double _initialIconScale = 0.92;

  late final AnimationController _iconController;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _supportingOpacity;
  Timer? _progressDelayTimer;
  bool _showProgressIndicator = false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: LaunchSplashContent.iconAnimationDuration,
    )..forward();
    _iconOpacity = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0, 0.42, curve: Curves.easeOutCubic),
    );
    _iconScale = Tween<double>(begin: _initialIconScale, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _supportingOpacity = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0.32, 0.82, curve: Curves.easeOutCubic),
    );

    if (widget.showProgress) {
      _progressDelayTimer = Timer(widget.progressDelay, () {
        if (mounted) {
          setState(() => _showProgressIndicator = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _progressDelayTimer?.cancel();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FadeTransition(
          key: LaunchSplashContent.logoOpacityKey,
          opacity: _iconOpacity,
          child: ScaleTransition(
            key: LaunchSplashContent.logoScaleKey,
            scale: _iconScale,
            child: LogoHeightProbe(
              source: widget.source,
              boxSize: LaunchSplashContent.logoBoxSize,
              asset: LaunchSplashContent.logoAsset,
              child: Image.asset(
                LaunchSplashContent.logoAsset,
                filterQuality: FilterQuality.high,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
        if (widget.wordmark case final String title) ...<Widget>[
          const SizedBox(height: 28),
          FadeTransition(
            opacity: _supportingOpacity,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: LaunchSplashContent.logoForeground.withValues(
                  alpha: 0.88,
                ),
                height: 1.2,
              ),
            ),
          ),
        ],
        if (widget.showProgress) ...<Widget>[
          const SizedBox(height: 36),
          AnimatedOpacity(
            opacity: _showProgressIndicator ? 1 : 0,
            duration: _progressFadeDuration,
            child: const _LaunchSplashProgressBar(
              key: Key('launch_splash_progress'),
            ),
          ),
        ],
      ],
    );
  }
}

class _LaunchSplashProgressBar extends StatefulWidget {
  const _LaunchSplashProgressBar({super.key});

  @override
  State<_LaunchSplashProgressBar> createState() =>
      _LaunchSplashProgressBarState();
}

class _LaunchSplashProgressBarState extends State<_LaunchSplashProgressBar>
    with SingleTickerProviderStateMixin {
  static const double _barWidth = 120;
  static const double _barHeight = 2;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: SizedBox(
        width: _barWidth,
        height: _barHeight,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            return CustomPaint(
              painter: _ShimmerBarPainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerBarPainter extends CustomPainter {
  const _ShimmerBarPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint track = Paint()
      ..color = LaunchSplashContent.logoForeground.withValues(alpha: 0.22)
      ..strokeCap = StrokeCap.round;
    final Paint highlight = Paint()
      ..color = LaunchSplashContent.logoForeground.withValues(alpha: 0.72)
      ..strokeCap = StrokeCap.round;

    final Offset start = Offset(0, size.height / 2);
    final Offset end = Offset(size.width, size.height / 2);
    canvas.drawLine(start, end, track..strokeWidth = size.height);

    const double highlightWidth = 36;
    final double travel = size.width + highlightWidth;
    final double x = progress * travel - highlightWidth;
    canvas.drawLine(
      Offset(x, size.height / 2),
      Offset(x + highlightWidth, size.height / 2),
      highlight..strokeWidth = size.height,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerBarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
