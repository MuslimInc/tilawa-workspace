import 'dart:ui' as ui show Image;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Cold-start logo sizing traces. Filter logcat / console with `[LogoHeight]`.
void logoHeightLog(String message) {
  debugPrint('[LogoHeight] $message');
}

/// Wraps the launch wordmark and logs layout vs painted size each frame.
class LogoHeightProbe extends StatefulWidget {
  const LogoHeightProbe({
    super.key,
    required this.source,
    required this.boxSize,
    required this.asset,
    required this.child,
  });

  final String source;
  final double boxSize;
  final String asset;
  final Widget child;

  @override
  State<LogoHeightProbe> createState() => _LogoHeightProbeState();
}

class _LogoHeightProbeState extends State<LogoHeightProbe> {
  final GlobalKey _boxKey = GlobalKey(debugLabel: 'logo_box');
  final GlobalKey _imageKey = GlobalKey(debugLabel: 'logo_image');
  int _buildCount = 0;
  int _postFrameCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final MediaQueryData mq = MediaQuery.of(context);
    logoHeightLog(
      '${widget.source} build#$_buildCount '
      'configuredBox=${widget.boxSize}dp asset=${widget.asset} '
      'dpr=${mq.devicePixelRatio.toStringAsFixed(3)} '
      'logicalScreen=${mq.size.width.toStringAsFixed(1)}×'
      '${mq.size.height.toStringAsFixed(1)} '
      'padding=top:${mq.padding.top.toStringAsFixed(1)} '
      'bottom:${mq.padding.bottom.toStringAsFixed(1)} '
      'viewInsets=top:${mq.viewInsets.top.toStringAsFixed(1)} '
      'bottom:${mq.viewInsets.bottom.toStringAsFixed(1)}',
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _logAfterFrame();
    });

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        logoHeightLog(
          '${widget.source} build#$_buildCount layoutConstraints '
          'max=${constraints.maxWidth.toStringAsFixed(1)}×'
          '${constraints.maxHeight.toStringAsFixed(1)} '
          'tight=${constraints.minWidth.toStringAsFixed(1)}×'
          '${constraints.minHeight.toStringAsFixed(1)}',
        );
        return SizedBox.square(
          key: _boxKey,
          dimension: widget.boxSize,
          child: KeyedSubtree(
            key: _imageKey,
            child: widget.child,
          ),
        );
      },
    );
  }

  void _logAfterFrame() {
    _postFrameCount++;
    final MediaQueryData mq = MediaQuery.of(context);
    final String boxPainted = _formatRenderBox(_boxKey.currentContext);
    final String imagePainted = _formatRenderBox(_imageKey.currentContext);
    final String imageExtra = _formatRenderImage(_imageKey.currentContext);

    logoHeightLog(
      '${widget.source} postFrame#$_postFrameCount '
      '(after build#$_buildCount) '
      'boxRender=$boxPainted imageRender=$imagePainted$imageExtra '
      'physicalBoxHeight=${_physicalHeight(_boxKey.currentContext, mq)}',
    );
  }

  String? _physicalHeight(BuildContext? context, MediaQueryData mq) {
    final RenderBox? box = _asRenderBox(context);
    if (box == null || !box.hasSize) {
      return null;
    }
    return (box.size.height * mq.devicePixelRatio).toStringAsFixed(1);
  }

  String _formatRenderBox(BuildContext? context) {
    final RenderBox? box = _asRenderBox(context);
    if (box == null) {
      return 'null';
    }
    if (!box.hasSize) {
      return 'noSize';
    }
    final Size size = box.size;
    return '${size.width.toStringAsFixed(2)}×'
        '${size.height.toStringAsFixed(2)}';
  }

  String _formatRenderImage(BuildContext? context) {
    final RenderObject? renderObject = context?.findRenderObject();
    if (renderObject is! RenderImage) {
      return '';
    }
    final ui.Image? image = renderObject.image;
    if (image == null) {
      return ' imageIntrinsic=loading';
    }
    return ' imageIntrinsic=${image.width}×${image.height} '
        'scale=${renderObject.scale.toStringAsFixed(4)}';
  }

  RenderBox? _asRenderBox(BuildContext? context) {
    final RenderObject? renderObject = context?.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
  }
}
