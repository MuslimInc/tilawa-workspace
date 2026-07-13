import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A developer tool widget that overlays a specified reference image (like an Ayah
/// app screenshot) on top of your live UI. Allows tuning the layout pixel by pixel.
///
/// Note: Only visible in debug mode.
class ReferenceOverlayValidator extends StatefulWidget {
  const ReferenceOverlayValidator({
    super.key,
    required this.child,
    this.referenceImagePath,
    this.initialOpacity = 0.5,
  });

  final Widget child;

  /// The local asset path of the reference screenshot (e.g., 'assets/images/ayah_page_207.png')
  final String? referenceImagePath;

  final double initialOpacity;

  @override
  State<ReferenceOverlayValidator> createState() =>
      _ReferenceOverlayValidatorState();
}

class _ReferenceOverlayValidatorState extends State<ReferenceOverlayValidator> {
  late double _opacity;
  bool _isVisible = false;
  Offset _offset = Offset.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _opacity = widget.initialOpacity;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || widget.referenceImagePath == null) {
      return widget.child;
    }

    final tokens = Theme.of(context).tokens;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        widget.child,

        if (_isVisible && widget.referenceImagePath != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: _opacity,
                child: Transform.translate(
                  offset: _offset,
                  child: Transform.scale(
                    scale: _scale,
                    child: Image.asset(
                      widget.referenceImagePath!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          bottom: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isVisible)
                  Container(
                    width: 280,
                    padding: EdgeInsets.all(tokens.spaceSmall),
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface,
                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pixel Alignment Overlay',
                          style: TextStyle(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Opacity',
                              style: TextStyle(
                                color: scheme.onInverseSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _opacity,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (v) => setState(() => _opacity = v),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Scale',
                              style: TextStyle(
                                color: scheme.onInverseSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _scale,
                                min: 0.8,
                                max: 1.2,
                                onChanged: (v) => setState(() => _scale = v),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_up,
                                color: scheme.onInverseSurface,
                              ),
                              onPressed: () => setState(
                                () => _offset += const Offset(0, -1),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: scheme.onInverseSurface,
                              ),
                              onPressed: () =>
                                  setState(() => _offset += const Offset(0, 1)),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_left,
                                color: scheme.onInverseSurface,
                              ),
                              onPressed: () => setState(
                                () => _offset += const Offset(-1, 0),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_right,
                                color: scheme.onInverseSurface,
                              ),
                              onPressed: () =>
                                  setState(() => _offset += const Offset(1, 0)),
                            ),
                          ],
                        ),
                        TilawaButton(
                          text: 'Reset Overlay',
                          variant: TilawaButtonVariant.ghost,
                          foregroundColor: scheme.onInverseSurface.withValues(
                            alpha: 0.7,
                          ),
                          onPressed: () {
                            setState(() {
                              _offset = Offset.zero;
                              _scale = 1.0;
                              _opacity = 0.5;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'reference_overlay_validator_fab',
                  mini: true,
                  backgroundColor: _isVisible
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  onPressed: () {
                    setState(() {
                      _isVisible = !_isVisible;
                    });
                  },
                  child: const Icon(Icons.compare),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
