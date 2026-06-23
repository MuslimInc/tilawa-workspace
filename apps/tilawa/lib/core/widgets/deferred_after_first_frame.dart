import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:tilawa/core/telemetry/startup_perf_log.dart';

/// Builds [placeholder] until the first frame completes, then [child].
///
/// Spreads below-the-fold work across frames during cold start.
class DeferredAfterFirstFrame extends StatefulWidget {
  const DeferredAfterFirstFrame({
    super.key,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
    this.perfEvent,
  });

  final Widget child;
  final Widget placeholder;

  /// When set, emits `[StartupPerf]` logs for placeholder vs enabled states.
  final String? perfEvent;

  @override
  State<DeferredAfterFirstFrame> createState() =>
      _DeferredAfterFirstFrameState();
}

class _DeferredAfterFirstFrameState extends State<DeferredAfterFirstFrame> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final String? perfEvent = widget.perfEvent;
    if (perfEvent != null) {
      StartupPerfLog.log('${perfEvent}_deferred');
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (perfEvent != null) {
        StartupPerfLog.log('${perfEvent}_enabled');
      }
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : widget.placeholder;
  }
}
