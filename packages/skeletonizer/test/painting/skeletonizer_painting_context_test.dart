import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skeletonizer/src/painting/skeletonizer_painting_context.dart';
import 'package:skeletonizer/src/skeletonizer_config.dart';

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
    shader = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero, const ui.Offset(100, 0),
        [const ui.Color(0xFFE0E0E0), const ui.Color(0xFFF5F5F5), const ui.Color(0xFFE0E0E0)],
        const [0.0, 0.5, 1.0],
      );
  });

  group('constructor', () {
    test('stores arguments', () {
      final l = ContainerLayer();
      final c = SkeletonizerPaintingContext(
        layer: l, estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader, config: cfg, isZone: true, animationValue: 0.75,
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
        layer: ContainerLayer(), estimatedBounds: ui.Rect.zero,
        shaderPaint: shader, config: cfg, isZone: false, animationValue: 0.3,
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
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        ok = ctx.canvas is SkeletonizerCanvas;
      }))));
      await t.pumpAndSettle();
      expect(ok, isTrue);
    });

    testWidgets('leafBoundsStack drives drawPicture replacement', (t) async {
      await t.pumpWidget(_wrap(SizedBox(
        width: 50, height: 50,
        child: Skeletonizer(enabled: true, child: _Capture(onPaint: (ctx) {
          final canvas = ctx.canvas as SkeletonizerCanvas;
          final r = ui.PictureRecorder();
          ui.Canvas(r).drawCircle(ui.Offset.zero, 10, ui.Paint());
          canvas.drawPicture(r.endRecording());
        })),
      )));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('stopRecordingIfNeeded clears state', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        ctx.canvas.drawRect(ui.Rect.zero, ui.Paint());
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – text', () {
    testWidgets('drawParagraph produces bones', (t) async {
      await t.pumpWidget(_wrap(RepaintBoundary(child: SizedBox(
        width: 200, height: 60,
        child: Skeletonizer(enabled: true, child: const Center(child: Text('X', style: TextStyle(fontSize: 24)))),
      ))));
      await t.pumpAndSettle();
      // ignore: invalid_use_of_protected_member
      final img = await _layerImage(t.renderObject(find.byType(RepaintBoundary)).layer!, const Size(200, 60));
      expect(img.width, 200);
    });
  });

  group('SkeletonizerCanvas – images', () {
    testWidgets('drawImage', (t) async {
      final img = await _redImage();
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawImage(img, ui.Offset.zero, ui.Paint());
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawImageRect', (t) async {
      final img = await _redImage();
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawImageRect(img, ui.Rect.zero, const ui.Rect.fromLTWH(0, 0, 50, 50), ui.Paint());
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawImageNine', (t) async {
      final img = await _redImage();
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawImageNine(img, ui.Rect.zero, const ui.Rect.fromLTWH(0, 0, 50, 50), ui.Paint());
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – containers', () {
    testWidgets('drawRect preserves container color', (t) async {
      await t.pumpWidget(_wrap(RepaintBoundary(child: SizedBox(
        width: 100, height: 100,
        child: Skeletonizer(enabled: true, ignoreContainers: false, child: Container(color: Colors.red)),
      ))));
      await t.pumpAndSettle();
      // ignore: invalid_use_of_protected_member
      final img = await _layerImage(t.renderObject(find.byType(RepaintBoundary)).layer!, const Size(100, 100));
      expect(await _redAtCenter(img), greaterThanOrEqualTo(0));
    });

    testWidgets('drawRRect', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawDRRect', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawDRRect(
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)),
          ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(5, 5, 40, 40), const ui.Radius.circular(4)),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – shapes', () {
    testWidgets('drawCircle', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawCircle(const ui.Offset(25, 25), 20, ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawOval', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawOval(const ui.Rect.fromLTWH(0, 0, 50, 50), ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawArc', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawArc(const ui.Rect.fromLTWH(0, 0, 50, 50), 0, 1, false, ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawLine', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawLine(ui.Offset.zero, const ui.Offset(50, 50), ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPath', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        final p = ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
        (ctx.canvas as SkeletonizerCanvas).drawPath(p, ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPoints', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawPoints(ui.PointMode.points, [ui.Offset.zero], ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawRawPoints', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawRawPoints(ui.PointMode.points, Float32List.fromList([0, 0]), ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('isZone behavior', () {
    test('canvas is plain when isZone=true', () {
      final layer = ContainerLayer();
      final ctx = SkeletonizerPaintingContext(
        layer: layer, estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: shader, config: cfg, isZone: true, animationValue: 0.5,
      );
      expect(ctx.canvas, isNot(isA<SkeletonizerCanvas>()));
    });
  });

  group('ignoreContainers', () {
    testWidgets('drawShadow skipped when ignoreContainers=true', (t) async {
      final newCfg = cfg.copyWith(ignoreContainers: true);
      await t.pumpWidget(_wrap(SkeletonizerConfig(
        data: newCfg,
        child: _Capture(onPaint: (ctx) {
          final c = ctx.canvas as SkeletonizerCanvas;
          c.drawShadow(
            ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50)),
            const ui.Color(0xFF000000), 2, false,
          );
        }),
      )));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('drawPicture fallback', () {
    testWidgets('falls back to parent when no leaf bounds', (t) async {
      await t.pumpWidget(_wrap(SizedBox(
        width: 50, height: 50,
        child: Skeletonizer(enabled: true, child: _Capture(onPaint: (ctx) {
          final c = ctx.canvas as SkeletonizerCanvas;
          final r = ui.PictureRecorder();
          ui.Canvas(r).drawCircle(ui.Offset.zero, 10, ui.Paint());
          c.drawPicture(r.endRecording());
        })),
      )));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – colour / shadow / paint', () {
    testWidgets('drawColor', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawColor(const ui.Color(0xFFFF0000), ui.BlendMode.srcOver);
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawPaint', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawPaint(ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('drawShadow', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).drawShadow(
          ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50)), const ui.Color(0xFF000000), 2, false,
        );
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – transforms', () {
    testWidgets('save/restore/translate/scale/rotate/skew', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        final c = ctx.canvas as SkeletonizerCanvas;
        c.save();
        c.translate(1, 1);
        c.scale(1, 1);
        c.rotate(0.1);
        c.skew(0, 0);
        c.transform(Matrix4.identity().storage);
        c.restore();
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('saveLayer', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).saveLayer(null, ui.Paint());
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – clipping', () {
    testWidgets('clipRect/clipRRect/clipPath', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        final c = ctx.canvas as SkeletonizerCanvas;
        c.clipRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
        c.clipRRect(ui.RRect.fromRectAndRadius(const ui.Rect.fromLTWH(0, 0, 50, 50), const ui.Radius.circular(8)));
        c.clipPath(ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 50, 50)));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – drawRawAtlas', () {
    testWidgets('with leafBoundsStack', (t) async {
      final img = await _redImage();
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        final c = ctx.canvas as SkeletonizerCanvas;
        c.drawRawAtlas(img, Float32List(0), Float32List(0), null, null, null, ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – vertices', () {
    testWidgets('drawVertices', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        final verts = ui.Vertices(ui.VertexMode.triangles, [ui.Offset.zero, const ui.Offset(10, 0), const ui.Offset(0, 10)]);
        (ctx.canvas as SkeletonizerCanvas).drawVertices(verts, ui.BlendMode.srcOver, ui.Paint()..color = const ui.Color(0xFFFF0000));
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('SkeletonizerCanvas – getters', () {
    testWidgets('getSaveCount', (t) async {
      await t.pumpWidget(_wrap(Skeletonizer(child: _Capture(onPaint: (ctx) {
        (ctx.canvas as SkeletonizerCanvas).getSaveCount();
      }))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('LeafPaintingContext', () {
    test('stops after first paint', () {
      final layer = ContainerLayer();
      final paint = ui.Paint();
      final ctx = LeafPaintingContext(
        layer: layer, estimatedBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        shaderPaint: paint, config: cfg,
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
}
