import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: brightness,
  );
  final designTokens = brightness == Brightness.dark
      ? MeMuslimDesignTokens.dark()
      : MeMuslimDesignTokens.light();
  final componentTokens = brightness == Brightness.dark
      ? MeMuslimComponentTokens.dark(colorScheme: colorScheme)
      : MeMuslimComponentTokens.light(colorScheme: colorScheme);

  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      extensions: [designTokens, componentTokens],
    ),
    home: Directionality(
      textDirection: textDirection,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

void main() {
  group('TilawaSkeletonBone', () {
    testWidgets('renders a static block outside a TilawaSkeleton scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TilawaSkeletonBone(width: 100, height: 16)),
      );

      expect(find.byType(TilawaSkeletonBone), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TilawaSkeletonBone),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
      );
    });

    testWidgets('uses skeleton tokens for the resting fill', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaSkeletonBone(width: 100, height: 16)),
      );

      final BuildContext context = tester.element(
        find.byType(TilawaSkeletonBone),
      );
      final theme = Theme.of(context);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TilawaSkeletonBone),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      // Opaque composite: srcATop shader strength is capped by child alpha,
      // so bones must be solid for the shimmer band to stay visible.
      expect(
        decoration.color,
        Color.alphaBlend(
          theme.colorScheme.onSurface.withValues(
            alpha: theme.componentTokens.skeleton.baseAlpha,
          ),
          theme.colorScheme.surface,
        ),
      );
      expect(decoration.color!.a, 1.0);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(theme.tokens.radiusSmall),
      );
    });

    testWidgets('circle constructor renders a circular bone', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaSkeletonBone.circle(dimension: 40)),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TilawaSkeletonBone),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.shape, BoxShape.circle);
      expect(
        tester.getSize(find.byType(TilawaSkeletonBone)),
        const Size(40, 40),
      );
    });
  });

  group('TilawaSkeleton', () {
    testWidgets('shimmers descendant bones', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSkeleton(
            child: TilawaSkeletonBone(width: 100, height: 16),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(TilawaSkeletonBone),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
    });

    testWidgets('animate: false renders static bones', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSkeleton(
            animate: false,
            child: TilawaSkeletonBone(width: 100, height: 16),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('reduced motion renders static bones', (tester) async {
      await tester.pumpWidget(
        _wrap(
          disableAnimations: true,
          const TilawaSkeleton(
            child: TilawaSkeletonBone(width: 100, height: 16),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('semanticLabel labels the region and hides bones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaSkeleton(
            semanticLabel: 'Loading',
            child: TilawaSkeletonBone(width: 100, height: 16),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });
  });

  group('TilawaSkeletonLine', () {
    testWidgets('matches the resolved text style line height', (tester) async {
      await tester.pumpWidget(_wrap(const TilawaSkeletonLine(width: 120)));

      final BuildContext context = tester.element(
        find.byType(TilawaSkeletonLine),
      );
      final TextStyle style = Theme.of(context).textTheme.bodyMedium!;
      final TextPainter painter = TextPainter(
        text: TextSpan(text: 'Hg', style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final double expectedHeight = painter.height;
      painter.dispose();

      expect(
        tester.getSize(find.byType(TilawaSkeletonLine)),
        Size(120, expectedHeight),
      );
    });
  });
}
