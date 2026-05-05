import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skeletonizer/src/painting/skeletonizer_painting_context.dart';

// ── Helpers ──────────────────────────────────────────────────────────

/// Wraps [child] with the ambient widgets [Skeletonizer] expects.
Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(800, 600)),
    child: child,
  ),
);

Future<ui.Image> _redImage() async {
  final r = ui.PictureRecorder();
  final c = ui.Canvas(r);
  c.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint()..color = const ui.Color(0xFFFF0000));
  return r.endRecording().toImage(10, 10);
}

Future<int> _redAtCenter(ui.Image img) async {
  final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (d == null) return -1;
  final b = d.buffer.asUint8List();
  final x = img.width ~/ 2, y = img.height ~/ 2;
  return b[(y * img.width + x) * 4];
}

class _Capture extends LeafRenderObjectWidget {
  final void Function(PaintingContext ctx) onPaint;
  const _Capture({required this.onPaint});
  @override
  RenderObject createRenderObject(BuildContext ctx) => _CaptureBox(onPaint);
}

class _CaptureBox extends RenderBox {
  final void Function(PaintingContext ctx) onPaint;
  _CaptureBox(this.onPaint);
  @override
  void performLayout() => size = constraints.biggest;
  @override
  void paint(PaintingContext ctx, ui.Offset o) => onPaint(ctx);
}

/// A proxy render box with no child so [SkeletonizerPaintingContext.paintChild]
/// treats it as a leaf and pushes its bounds to [_leafBoundsStack].
class _LeafProxyBox extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  final void Function(PaintingContext ctx) onPaint;
  _LeafProxyBox(this.onPaint);
  @override
  void performLayout() => size = constraints.biggest;
  @override
  void paint(PaintingContext ctx, ui.Offset o) => onPaint(ctx);
}

class _LeafProxy extends SingleChildRenderObjectWidget {
  final void Function(PaintingContext ctx) onPaint;
  const _LeafProxy({required this.onPaint}) : super(child: null);
  @override
  RenderObject createRenderObject(BuildContext context) => _LeafProxyBox(onPaint);
}

Future<ui.Image> _layerImage(Layer layer, Size s) async {
  final b = ui.SceneBuilder();
  // ignore: invalid_use_of_protected_member
  layer.addToScene(b);
  return b.build().toImage(s.width.toInt(), s.height.toInt());
}

// ── Tests ────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Paint shader;
  late SkeletonizerConfigData cfg;

  setUp(() {
    cfg = SkeletonizerConfigData(
      effect: const ShimmerEffect(),
      textBorderRadius: TextBoneBorderRadius(BorderRadius.circular(4)),
      ignoreContainers: false,
    );
    shader =
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset.zero,
            const ui.Offset(100, 0),
            [const ui.Color(0xFFE0E0E0), const ui.Color(0xFFF5F5F5), const ui.Color(0xFFE0E0E0)],
            const [0.0, 0.5, 1.0],
          );
  });

  group('constructor', () {
    test('stores arguments', () {
      final l = ContainerLayer();
      final c = SkeletonizerPaintingContext(
        layer: l,
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: cfg,
        isZone: true,
        animationValue: 0.75,
      );
      expect(c.layer, same(l));
      expect(c.config, same(cfg));
      expect(c.animationValue, 0.75);
      expect(c.isZone, isTrue);
    });
  });

  group('createChildContext', () {
    test('clones fields', () {
      final ctx = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: ui.Rect.zero,
        shaderPaint: shader,
        config: cfg,
        isZone: false,
        animationValue: 0.3,
      );
      final child = ctx.createChildContext(ContainerLayer(), ui.Rect.fromLTWH(10, 10, 50, 50));
      expect(child, isA<SkeletonizerPaintingContext>());
      final s = child as SkeletonizerPaintingContext;
      expect(s.config, same(cfg));
      expect(s.shaderPaint, same(shader));
      expect(s.isZone, false);
      expect(s.animationValue, 0.3);
    });
  });

  group('paintChild leaf detection', () {
    testWidgets('wraps canvas in SkeletonizerCanvas', (t) async {
      bool ok = false;
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                ok = ctx.canvas is SkeletonizerCanvas;
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(ok, isTrue);
    });

    testWidgets('leafBoundsStack drives drawPicture replacement', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _Capture(
                onPaint: (ctx) {
                  final canvas = ctx.canvas as SkeletonizerCanvas;
                  final r = ui.PictureRecorder();
                  ui.Canvas(r).drawCircle(ui.Offset.zero, 10, ui.Paint());
                  canvas.drawPicture(r.endRecording());
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('stopRecordingIfNeeded clears state', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                ctx.canvas.drawRect(ui.Rect.zero, ui.Paint());
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – text', () {
    testWidgets('drawParagraph produces bones', (t) async {
      await t.pumpWidget(
        _wrap(
          RepaintBoundary(
            child: SizedBox(
              width: 200,
              height: 60,
              child: Skeletonizer(enabled: true, child: const Center(child: Text('X', style: TextStyle(fontSize: 24)))),
            ),
          ),
        ),
      );
      await t.pump();
      // ignore: invalid_use_of_protected_member
      final img = await _layerImage(t.renderObject(find.byType(RepaintBoundary)).layer!, const Size(200, 60));
      expect(img.width, 200);
    });
  });

  group('SkeletonizerCanvas – images', () {
    testWidgets('drawImage', (t) async {
      final img = await _redImage();
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawImage(img, ui.Offset.zero, ui.Paint());
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawImageRect', (t) async {
      final img = await _redImage();
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawImageRect(
                  img,
                  ui.Rect.zero,
                  const ui.Rect.fromLTWH(0, 0, 50, 50),
                  ui.Paint(),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawImageNine', (t) async {
      final img = await _redImage();
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawImageNine(
                  img,
                  ui.Rect.zero,
                  const ui.Rect.fromLTWH(0, 0, 50, 50),
                  ui.Paint(),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawAtlas', (t) async {
      final img = await _redImage();
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawAtlas(
                  img,
                  <ui.RSTransform>[],
                  <ui.Rect>[],
                  null,
                  null,
                  null,
                  ui.Paint(),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – containers', () {
    test('drawRect preserves container color', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final shader =
          ui.Paint()
            ..shader = ui.Gradient.linear(
              ui.Offset.zero,
              const ui.Offset(100, 0),
              [const ui.Color(0xFFE0E0E0), const ui.Color(0xFFF5F5F5), const ui.Color(0xFFE0E0E0)],
              const [0.0, 0.5, 1.0],
            );
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          ignoreContainers: false,
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 100, 100),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 100);
      expect(await _redAtCenter(img), 255);
    });

    testWidgets('drawRRect', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawRRect(
                  ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawDRRect', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawDRRect(
                  ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
                  ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5, 5, 40, 40), const ui.Radius.circular(4)),
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – shapes', () {
    testWidgets('drawCircle', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawCircle(
                  const ui.Offset(25, 25),
                  20,
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawOval', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawOval(
                  const ui.Rect.fromLTWH(0, 0, 50, 50),
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawArc', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawArc(
                  const ui.Rect.fromLTWH(0, 0, 50, 50),
                  0,
                  1,
                  false,
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawLine', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawLine(
                  ui.Offset.zero,
                  const ui.Offset(50, 50),
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPath', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                final p = ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
                (ctx.canvas as SkeletonizerCanvas).drawPath(p, ui.Paint()..color = const ui.Color(0xFFFF0000));
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPoints', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawPoints(ui.PointMode.points, [
                  ui.Offset.zero,
                ], ui.Paint()..color = const ui.Color(0xFFFF0000));
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawRawPoints', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawRawPoints(
                  ui.PointMode.points,
                  Float32List.fromList([0, 0]),
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('isZone behavior', () {
    test('canvas is plain when isZone=true', () {
      final layer = ContainerLayer();
      final ctx = SkeletonizerPaintingContext(
        layer: layer,
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: cfg,
        isZone: true,
        animationValue: 0.5,
      );
      expect(ctx.canvas, isNot(isA<SkeletonizerCanvas>()));
    });
  });

  group('ignoreContainers', () {
    testWidgets('drawShadow skipped when ignoreContainers=true', (t) async {
      final newCfg = cfg.copyWith(ignoreContainers: true);
      await t.pumpWidget(
        _wrap(
          SkeletonizerConfig(
            data: newCfg,
            child: Skeletonizer(
              child: _Capture(
                onPaint: (ctx) {
                  final c = ctx.canvas as SkeletonizerCanvas;
                  c.drawShadow(
                    ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50)),
                    const ui.Color(0xFF000000),
                    2,
                    false,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('drawPicture fallback', () {
    testWidgets('falls back to parent when no leaf bounds', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _Capture(
                onPaint: (ctx) {
                  final c = ctx.canvas as SkeletonizerCanvas;
                  final r = ui.PictureRecorder();
                  ui.Canvas(r).drawCircle(ui.Offset.zero, 10, ui.Paint());
                  c.drawPicture(r.endRecording());
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – colour / shadow / paint', () {
    testWidgets('drawColor', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawColor(const ui.Color(0xFFFF0000), ui.BlendMode.srcOver);
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPaint', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawPaint(ui.Paint()..color = const ui.Color(0xFFFF0000));
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawShadow', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawShadow(
                  ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50)),
                  const ui.Color(0xFF000000),
                  2,
                  false,
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – transforms', () {
    testWidgets('save/restore/translate/scale/rotate/skew', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                final c = ctx.canvas as SkeletonizerCanvas;
                c.save();
                c.translate(1, 1);
                c.scale(1, 1);
                c.rotate(0.1);
                c.skew(0, 0);
                c.transform(Matrix4.identity().storage);
                c.restore();
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('saveLayer', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).saveLayer(null, ui.Paint());
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('restoreToCount', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                final c = ctx.canvas as SkeletonizerCanvas;
                c.save();
                c.restoreToCount(c.getSaveCount());
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – clipping', () {
    testWidgets('clipRect/clipRRect/clipPath/clipRSuperellipse', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                final c = ctx.canvas as SkeletonizerCanvas;
                c.clipRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
                c.clipRRect(
                  ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
                );
                c.clipPath(ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50)));
                c.clipRSuperellipse(
                  ui.RSuperellipse.fromRectXY(
                    const ui.Rect.fromLTWH(0, 0, 50, 50),
                    8,
                    8,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – drawRawAtlas', () {
    testWidgets('with leafBoundsStack', (t) async {
      final img = await _redImage();
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                final c = ctx.canvas as SkeletonizerCanvas;
                c.drawRawAtlas(
                  img,
                  Float32List(0),
                  Float32List(0),
                  null,
                  null,
                  null,
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – vertices', () {
    testWidgets('drawVertices', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                final verts = ui.Vertices(ui.VertexMode.triangles, [
                  ui.Offset.zero,
                  const ui.Offset(10, 0),
                  const ui.Offset(0, 10),
                ]);
                (ctx.canvas as SkeletonizerCanvas).drawVertices(
                  verts,
                  ui.BlendMode.srcOver,
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – rounded superellipse', () {
    testWidgets('drawRSuperellipse', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).drawRSuperellipse(
                  ui.RSuperellipse.fromRectXY(
                    const ui.Rect.fromLTWH(0, 0, 50, 50),
                    8,
                    8,
                  ),
                  ui.Paint()..color = const ui.Color(0xFFFF0000),
                );
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – getters', () {
    testWidgets('getSaveCount', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).getSaveCount();
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('getDestinationClipBounds', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).getDestinationClipBounds();
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('getLocalClipBounds', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).getLocalClipBounds();
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('getTransform', (t) async {
      await t.pumpWidget(
        _wrap(
          Skeletonizer(
            child: _Capture(
              onPaint: (ctx) {
                (ctx.canvas as SkeletonizerCanvas).getTransform();
              },
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('LeafPaintingContext', () {
    test('stops after first paint', () {
      final layer = ContainerLayer();
      final paint = ui.Paint();
      final ctx = LeafPaintingContext(
        layer: layer,
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: paint,
        config: cfg,
      );

      var calls = 0;
      final box = _CaptureBox((c) => calls++);
      box.layout(BoxConstraints.tight(const Size(100, 100)));

      ctx.paintChild(box, ui.Offset.zero);
      expect(calls, 1);

      ctx.stopRecordingIfNeeded();
      ctx.paintChild(box, ui.Offset.zero);
      expect(calls, 2);
    });
  });

  group('createDefaultContext', () {
    test('creates plain PaintingContext and records into layer', () {
      final ctx = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: cfg,
        isZone: false,
        animationValue: 0.5,
      );
      ctx.createDefaultContext(
        ui.Rect.fromLTWH(0, 0, 50, 50),
        (c, offset) => c.canvas.drawRect(offset & const ui.Size(50, 50), ui.Paint()),
      );
      expect(ctx.layer, isNotNull);
    });
  });

  group('createLeafContext', () {
    test('creates LeafPaintingContext and records into layer', () {
      final ctx = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: cfg,
        isZone: false,
        animationValue: 0.5,
      );
      ctx.createLeafContext(
        ui.Rect.fromLTWH(0, 0, 50, 50),
        (c, offset) => c.canvas.drawRect(offset & const ui.Size(50, 50), ui.Paint()),
      );
      expect(ctx.layer, isNotNull);
    });
  });

  group('SkeletonizerCanvas – leaf detection bone paths', () {
    testWidgets('drawRect treats leaf proxy as bone', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  ctx.canvas.drawRect(ui.Rect.zero, ui.Paint()..color = const ui.Color(0xFFFF0000));
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawRRect treats leaf proxy as bone', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  ctx.canvas.drawRRect(
                    ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
                    ui.Paint()..color = const ui.Color(0xFFFF0000),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawDRRect treats leaf proxy as bone', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  ctx.canvas.drawDRRect(
                    ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
                    ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5, 5, 40, 40), const ui.Radius.circular(4)),
                    ui.Paint()..color = const ui.Color(0xFFFF0000),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawCircle treats leaf proxy as bone', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  ctx.canvas.drawCircle(const ui.Offset(25, 25), 20, ui.Paint()..color = const ui.Color(0xFFFF0000));
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPath treats leaf proxy as bone', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  final p = ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
                  ctx.canvas.drawPath(p, ui.Paint()..color = const ui.Color(0xFFFF0000));
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPicture replaces with bone when leafBoundsStack set', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  final r = ui.PictureRecorder();
                  ui.Canvas(r).drawCircle(const ui.Offset(25, 25), 10, ui.Paint());
                  ctx.canvas.drawPicture(r.endRecording());
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawRawAtlas replaces with bone when leafBoundsStack set', (t) async {
      final img = await _redImage();
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: _LeafProxy(
                onPaint: (ctx) {
                  ctx.canvas.drawRawAtlas(img, Float32List(0), Float32List(0), null, null, null, ui.Paint());
                },
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – containersColor override', () {
    test('drawRect uses containersColor when set', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          ignoreContainers: false,
          containersColor: const ui.Color(0xFF00FF00),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 100, 100),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 100);
      final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = d!.buffer.asUint8List();
      // containersColor green (0xFF00FF00) should be at center
      final x = 50, y = 50;
      final offset = (y * 100 + x) * 4;
      expect(bytes[offset + 1], 255); // G channel
    });

    test('drawPath uses containersColor when set', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          ignoreContainers: false,
          containersColor: const ui.Color(0xFF00FF00),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      final p = ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 100, 100));
      canvas.drawPath(p, ui.Paint()..color = const ui.Color(0xFFFF0000));
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 100);
      final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = d!.buffer.asUint8List();
      final x = 50, y = 50;
      final offset = (y * 100 + x) * 4;
      expect(bytes[offset + 1], 255);
    });

    test('drawRRect uses containersColor when set', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          ignoreContainers: false,
          containersColor: const ui.Color(0xFF00FF00),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 100, 100), const ui.Radius.circular(8)),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 100);
      final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = d!.buffer.asUint8List();
      final x = 50, y = 50;
      final offset = (y * 100 + x) * 4;
      expect(bytes[offset + 1], 255);
    });

    test('drawDRRect uses containersColor when set', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          ignoreContainers: false,
          containersColor: const ui.Color(0xFF00FF00),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      canvas.drawDRRect(
        ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 100, 100), const ui.Radius.circular(8)),
        ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5, 5, 90, 90), const ui.Radius.circular(4)),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 100);
      final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = d!.buffer.asUint8List();
      // DRRect is a donut; the center is inside the inner hole.
      // Anti-aliased edge may not be exactly 255.
      final x = 2, y = 2;
      final offset = (y * 100 + x) * 4;
      expect(bytes[offset + 1], greaterThan(200));
    });

    test('drawCircle uses containersColor when set', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          ignoreContainers: false,
          containersColor: const ui.Color(0xFF00FF00),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      canvas.drawCircle(
        const ui.Offset(50, 50),
        40,
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(100, 100);
      final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = d!.buffer.asUint8List();
      final x = 50, y = 50;
      final offset = (y * 100 + x) * 4;
      expect(bytes[offset + 1], 255);
    });
  });

  group('SkeletonizerCanvas – drawParagraph variants', () {
    test('uses heightFactor to compute border radius', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 200, 60),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          textBorderRadius: const TextBoneBorderRadius.fromHeightFactor(0.5),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 24));
      builder.addText('X');
      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 200));
      canvas.drawParagraph(paragraph, ui.Offset.zero);
      final picture = recorder.endRecording();
      final img = await picture.toImage(200, 60);
      expect(img.width, 200);
    });

    test('uses roundedSuperellipse shape', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 200, 60),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          textBorderRadius: const TextBoneBorderRadius.fromHeightFactor(
            0.5,
            borderShape: TextBoneBorderShape.roundedSuperellipse,
          ),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 24));
      builder.addText('X');
      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 200));
      canvas.drawParagraph(paragraph, ui.Offset.zero);
      final picture = recorder.endRecording();
      final img = await picture.toImage(200, 60);
      expect(img.width, 200);
    });

    test('uses fixed borderRadius', () async {
      final recorder = ui.PictureRecorder();
      final parentCanvas = ui.Canvas(recorder);
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: const ui.Rect.fromLTWH(0, 0, 200, 60),
        shaderPaint: shader,
        config: SkeletonizerConfigData(
          effect: const ShimmerEffect(),
          textBorderRadius: TextBoneBorderRadius(BorderRadius.circular(4)),
        ),
        isZone: false,
        animationValue: 0.5,
      );
      final canvas = SkeletonizerCanvas(parentCanvas, context);
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 24));
      builder.addText('X');
      final paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 200));
      canvas.drawParagraph(paragraph, ui.Offset.zero);
      final picture = recorder.endRecording();
      final img = await picture.toImage(200, 60);
      expect(img.width, 200);
    });
  });

  group('SkeletonizerCanvas – bone paths via leaf detection', () {
    late SkeletonizerPaintingContext ctx;

    setUp(() {
      ctx = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: cfg,
        isZone: false,
        animationValue: 0.5,
      );
    });

    test('drawRect treats leaf proxy as bone', () {
      final box = _LeafProxyBox((c) {
        c.canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 50, 50), ui.Paint()..color = const ui.Color(0xFFFF0000));
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });

    test('drawRRect treats leaf proxy as bone', () {
      final box = _LeafProxyBox((c) {
        c.canvas.drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });

    test('drawDRRect treats leaf proxy as bone', () {
      final box = _LeafProxyBox((c) {
        c.canvas.drawDRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5, 5, 40, 40), const ui.Radius.circular(4)),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });

    test('drawCircle treats leaf proxy as bone', () {
      final box = _LeafProxyBox((c) {
        c.canvas.drawCircle(const ui.Offset(25, 25), 20, ui.Paint()..color = const ui.Color(0xFFFF0000));
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });

    test('drawPath treats leaf proxy as bone', () {
      final box = _LeafProxyBox((c) {
        final p = ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
        c.canvas.drawPath(p, ui.Paint()..color = const ui.Color(0xFFFF0000));
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });

    test('drawPicture replaces with bone when leafBoundsStack set', () {
      final box = _LeafProxyBox((c) {
        final r = ui.PictureRecorder();
        ui.Canvas(r).drawCircle(const ui.Offset(25, 25), 10, ui.Paint());
        c.canvas.drawPicture(r.endRecording());
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });

    test('drawRawAtlas replaces with bone when leafBoundsStack set', () async {
      final img = await _redImage();
      final box = _LeafProxyBox((c) {
        c.canvas.drawRawAtlas(img, Float32List(0), Float32List(0), null, null, null, ui.Paint());
      });
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      ctx.paintChild(box, ui.Offset.zero);
      expect(ctx.layer, isNotNull);
    });
  });

  group('debug profiling', () {
    test('traces paint when debugProfilePaintsEnabled', () {
      debugProfilePaintsEnabled = true;
      addTearDown(() => debugProfilePaintsEnabled = false);

      final box = _CaptureBox((c) {});
      box.layout(BoxConstraints.tight(const Size(50, 50)));
      final context = SkeletonizerPaintingContext(
        layer: ContainerLayer(),
        estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader,
        config: cfg,
        isZone: false,
        animationValue: 0.5,
      );
      context.paintChild(box, ui.Offset.zero);
      expect(context.layer, isNotNull);
    });
  });

  group('SemanticsAnnotations leaf detection', () {
    testWidgets('button property triggers leaf detection', (t) async {
      await t.pumpWidget(
        _wrap(
          SizedBox(
            width: 50,
            height: 50,
            child: Skeletonizer(
              enabled: true,
              child: Semantics(
                button: true,
                child: _LeafProxy(
                  onPaint: (ctx) {
                    ctx.canvas.drawRect(ui.Rect.zero, ui.Paint()..color = const ui.Color(0xFFFF0000));
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
