import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/bootstrap/launch_splash_canvas.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('LaunchSplashCanvas.freezeLayoutMetrics', () {
    test('expands to full logical window from frame padding', () {
      const MediaQueryData before = MediaQueryData(
        size: Size(392.7, 761.5),
        padding: EdgeInsets.only(top: 24),
      );
      final MediaQueryData frozen =
          LaunchSplashCanvas.freezeLayoutMetrics(before);

      expect(frozen.size.width, 392.7);
      expect(frozen.size.height, 785.5);
      expect(frozen.padding, EdgeInsets.zero);
    });

  });

  group('LaunchSplashCanvas widget', () {
    const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: AppColors.launchSplashBackground,
      systemNavigationBarColor: AppColors.launchSplashBackground,
    );

    testWidgets('wordmark center stable when bottom padding settles', (
      WidgetTester tester,
    ) async {
      final GlobalKey wordmarkKey = GlobalKey();
      final GlobalKey<_InsetHostState> hostKey = GlobalKey<_InsetHostState>();

      await tester.pumpWidget(
        _InsetHost(
          key: hostKey,
          padding: const EdgeInsets.only(top: 24),
          size: const Size(392.7, 761.5),
          child: LaunchSplashCanvas(
            backgroundColor: AppColors.launchSplashBackground,
            overlayStyle: overlayStyle,
            child: SizedBox(
              key: wordmarkKey,
              width: AppColors.launchSplashLogoSize,
              height: AppColors.launchSplashLogoSize,
            ),
          ),
        ),
      );
      await tester.pump();

      final Offset centerBefore = tester.getCenter(find.byKey(wordmarkKey));

      hostKey.currentState!.settleBottomInset();
      await tester.pump();

      final Offset centerAfter = tester.getCenter(find.byKey(wordmarkKey));

      expect(centerBefore.dy, centerAfter.dy);
      expect(centerBefore.dx, centerAfter.dx);
    });

    testWidgets(
      'wordmark center stable when parent max height grows but MediaQuery does not',
      (WidgetTester tester) async {
        final GlobalKey wordmarkKey = GlobalKey();
        final GlobalKey<_TightParentHostState> hostKey =
            GlobalKey<_TightParentHostState>();

        await tester.pumpWidget(
          _TightParentHost(
            key: hostKey,
            maxHeight: 761.5,
            mediaQuery: const MediaQueryData(
              size: Size(392.7, 785.5),
            ),
            child: LaunchSplashCanvas(
              backgroundColor: AppColors.launchSplashBackground,
              overlayStyle: overlayStyle,
              child: SizedBox(
                key: wordmarkKey,
                width: AppColors.launchSplashLogoSize,
                height: AppColors.launchSplashLogoSize,
              ),
            ),
          ),
        );
        await tester.pump();

        final Offset centerTight = tester.getCenter(find.byKey(wordmarkKey));

        hostKey.currentState!.expandParent();
        await tester.pump();

        final Offset centerExpanded = tester.getCenter(find.byKey(wordmarkKey));

        expect(centerTight.dy, centerExpanded.dy);
        expect(centerTight.dx, centerExpanded.dx);
      },
    );
  });
}

/// Simulates Android edge-to-edge padding settling after the first frame.
class _InsetHost extends StatefulWidget {
  const _InsetHost({
    super.key,
    required this.padding,
    required this.size,
    required this.child,
  });

  final EdgeInsets padding;
  final Size size;
  final Widget child;

  @override
  State<_InsetHost> createState() => _InsetHostState();
}

/// Parent [BoxConstraints] change while [MediaQueryData.size] stays constant.
class _TightParentHost extends StatefulWidget {
  const _TightParentHost({
    super.key,
    required this.maxHeight,
    required this.mediaQuery,
    required this.child,
  });

  final double maxHeight;
  final MediaQueryData mediaQuery;
  final Widget child;

  @override
  State<_TightParentHost> createState() => _TightParentHostState();
}

class _TightParentHostState extends State<_TightParentHost> {
  late double _maxHeight;

  @override
  void initState() {
    super.initState();
    _maxHeight = widget.maxHeight;
  }

  void expandParent() {
    setState(() => _maxHeight = 785.5);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: widget.mediaQuery,
      child: Material(
        child: SizedBox(
          width: 392.7,
          height: _maxHeight,
          child: widget.child,
        ),
      ),
    );
  }
}

class _InsetHostState extends State<_InsetHost> {
  late EdgeInsets _padding;
  late Size _size;

  @override
  void initState() {
    super.initState();
    _padding = widget.padding;
    _size = widget.size;
  }

  void settleBottomInset() {
    setState(() {
      _padding = const EdgeInsets.only(top: 24, bottom: 24);
      _size = const Size(392.7, 785.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: _size, padding: _padding),
      child: Material(child: widget.child),
    );
  }
}
