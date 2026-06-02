import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen launch splash with layout size frozen on the first valid frame.
///
/// On cold start, Android edge-to-edge can report a stable [MediaQueryData.size]
/// while the parent still passes tighter [BoxConstraints] for a frame or two
/// (e.g. max height 761.5 then 785.5). A [Center] inside [SizedBox.expand]
/// follows those constraints and shifts the logo. This canvas lays out at the
/// frozen logical window height, top-aligned, so the wordmark Y stays fixed.
class LaunchSplashCanvas extends StatefulWidget {
  const LaunchSplashCanvas({
    super.key,
    required this.backgroundColor,
    required this.overlayStyle,
    required this.child,
  });

  final Color backgroundColor;
  final SystemUiOverlayStyle overlayStyle;
  final Widget child;

  /// Expands to the full logical window using padding reported on this frame.
  @visibleForTesting
  static MediaQueryData freezeLayoutMetrics(MediaQueryData data) {
    final double fullWidth =
        data.size.width + data.padding.left + data.padding.right;
    final double fullHeight =
        data.size.height + data.padding.top + data.padding.bottom;
    return data.copyWith(
      size: Size(fullWidth, fullHeight),
      padding: EdgeInsets.zero,
      viewInsets: EdgeInsets.zero,
    );
  }

  @override
  State<LaunchSplashCanvas> createState() => _LaunchSplashCanvasState();
}

class _LaunchSplashCanvasState extends State<LaunchSplashCanvas> {
  MediaQueryData? _frozenLayoutMetrics;

  static bool _hasValidSize(MediaQueryData data) {
    return data.size.width > 0 && data.size.height > 0;
  }

  @override
  void reassemble() {
    super.reassemble();
    _frozenLayoutMetrics = null;
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData live = MediaQuery.of(context);
    if (_frozenLayoutMetrics == null && _hasValidSize(live)) {
      _frozenLayoutMetrics = LaunchSplashCanvas.freezeLayoutMetrics(live);
    }
    final MediaQueryData layoutMetrics = _frozenLayoutMetrics ?? live;
    final Size canvasSize = layoutMetrics.size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: widget.overlayStyle,
      child: MediaQuery(
        data: layoutMetrics,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: widget.backgroundColor,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
