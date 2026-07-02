import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wraps route destinations for Sentry Time to Full Display (TTFD).
///
/// Requires [SentryConfig.applyFlutterOptions] with
/// `enableTimeToFullDisplayTracing` and [TilawaSentryNavigatorObserver].
class TilawaSentryRouteDisplay extends StatelessWidget {
  const TilawaSentryRouteDisplay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SentryDisplayWidget(
      child: _TilawaSentryDisplayChild(child: child),
    );
  }

  /// Reports TTFD when async route content is ready.
  static Future<void> reportFullyDisplayed(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    try {
      await SentryDisplayWidget.of(context).reportFullyDisplayed();
    } on Object {
      // Route was not wrapped in [TilawaSentryRouteDisplay].
    }
  }
}

/// Reports TTFD once when [when] becomes true.
class TilawaSentryRouteReporter extends StatefulWidget {
  const TilawaSentryRouteReporter({
    super.key,
    required this.when,
    required this.child,
  });

  final bool when;
  final Widget child;

  @override
  State<TilawaSentryRouteReporter> createState() =>
      _TilawaSentryRouteReporterState();
}

class _TilawaSentryRouteReporterState extends State<TilawaSentryRouteReporter> {
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReport());
  }

  @override
  void didUpdateWidget(covariant TilawaSentryRouteReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeReport();
  }

  void _maybeReport() {
    if (_reported || !widget.when || !mounted) {
      return;
    }
    _reported = true;
    unawaited(TilawaSentryRouteDisplay.reportFullyDisplayed(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Prevents [SentryDisplayWidget] from auto-reporting TTFD for stateless
/// route roots that load async content.
class _TilawaSentryDisplayChild extends StatefulWidget {
  const _TilawaSentryDisplayChild({required this.child});

  final Widget child;

  @override
  State<_TilawaSentryDisplayChild> createState() =>
      _TilawaSentryDisplayChildState();
}

class _TilawaSentryDisplayChildState extends State<_TilawaSentryDisplayChild> {
  @override
  Widget build(BuildContext context) => widget.child;
}
