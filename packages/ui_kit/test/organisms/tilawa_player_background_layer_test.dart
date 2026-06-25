import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/organisms/tilawa_player_background_layer.dart';

// Minimal 1×1 transparent PNG bytes.
final Uint8List _transparentPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
  0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,
  0x0D, 0x0A, 0x2D, 0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82, // IEND
]);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(),
      ],
    ),
    home: Scaffold(body: SizedBox(width: 400, height: 400, child: child)),
  );
}

void main() {
  group('TilawaBackdropImageLayer', () {
    testWidgets('null image returns SizedBox.shrink without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TilawaBackdropImageLayer(image: null)),
      );
      await tester.pump();

      // Widget tree should be present (no exception thrown).
      expect(find.byType(TilawaBackdropImageLayer), findsOneWidget);
      // With null image the widget renders a SizedBox.shrink — no Image widget.
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('non-null image renders without throwing', (tester) async {
      final provider = MemoryImage(_transparentPng);

      await tester.pumpWidget(_wrap(TilawaBackdropImageLayer(image: provider)));
      await tester.pump();

      expect(find.byType(TilawaBackdropImageLayer), findsOneWidget);
      // Stack with image + overlay layers should be present.
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('blurAmount zero path does not insert BackdropFilter', (
      tester,
    ) async {
      final provider = MemoryImage(_transparentPng);

      await tester.pumpWidget(
        _wrap(TilawaBackdropImageLayer(image: provider, blurAmount: 0)),
      );
      await tester.pump();

      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('positive blurAmount inserts BackdropFilter', (tester) async {
      final provider = MemoryImage(_transparentPng);

      await tester.pumpWidget(
        _wrap(TilawaBackdropImageLayer(image: provider, blurAmount: 8)),
      );
      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('image errorBuilder keeps widget intact on load failure', (
      tester,
    ) async {
      // A custom ImageProvider that always fails to exercise the errorBuilder.
      final provider = _AlwaysFailImageProvider();

      await tester.pumpWidget(_wrap(TilawaBackdropImageLayer(image: provider)));
      // Allow the error to fire and the errorBuilder to run.
      await tester.pump();
      await tester.pump();

      // Consume the image-stream error that was reported internally — the
      // errorBuilder returns SizedBox.shrink() so the widget tree survives.
      tester.takeException();

      // Widget tree is intact; the scaffold did not rethrow.
      expect(find.byType(TilawaBackdropImageLayer), findsOneWidget);
    });
  });
}

/// An [ImageProvider] that always throws during resolve to exercise
/// [Image.errorBuilder].
class _AlwaysFailImageProvider extends ImageProvider<_AlwaysFailImageProvider> {
  @override
  Future<_AlwaysFailImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _AlwaysFailImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return _FailingImageStreamCompleter();
  }

  @override
  bool operator ==(Object other) => other is _AlwaysFailImageProvider;

  @override
  int get hashCode => runtimeType.hashCode;
}

class _FailingImageStreamCompleter extends ImageStreamCompleter {
  _FailingImageStreamCompleter() {
    reportError(
      context: ErrorDescription('_AlwaysFailImageProvider: simulated error'),
      exception: Exception('Simulated image load failure'),
      silent: true,
    );
  }
}
