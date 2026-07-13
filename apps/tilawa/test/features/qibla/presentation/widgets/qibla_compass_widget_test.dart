import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/widgets/qibla_compass_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/shared/widgets/kaaba_icon.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(),
      ],
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('renders inside a narrow premium panel without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 280,
          child: QiblaCompassWidget(
            qiblaDirection: QiblaDirectionEntity(
              qibla: 136,
              direction: 270,
              offset: 226,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(QiblaCompassWidget), findsOneWidget);
    expect(find.byType(KaabaIcon), findsOneWidget);
    expect(find.text('226°'), findsOneWidget);
  });

  testWidgets('hides compass content when heading is NaN', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const QiblaCompassWidget(
          qiblaDirection: QiblaDirectionEntity(
            qibla: 0,
            direction: double.nan,
            offset: 136,
          ),
        ),
      ),
    );

    expect(find.byType(KaabaIcon), findsNothing);
  });

  testWidgets('uses primary color for bearing when aligned', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 280,
          child: QiblaCompassWidget(
            qiblaDirection: QiblaDirectionEntity(
              qibla: 0,
              direction: 136,
              offset: 136,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final Text bearingText = tester.widget<Text>(find.text('136°'));
    final ColorScheme scheme = Theme.of(
      tester.element(find.byType(QiblaCompassWidget)),
    ).colorScheme;

    expect(bearingText.style?.color, scheme.primary);
  });

  testWidgets('uses viewport shortest side when width is unbounded', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: QiblaCompassWidget(
            qiblaDirection: QiblaDirectionEntity(
              qibla: 0,
              direction: 136,
              offset: 136,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(QiblaCompassWidget), findsOneWidget);
  });

  testWidgets('repaints bezel marker when tertiary color changes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final ThemeData lightTheme = ThemeData(
      extensions: [
        MeMuslimDesignTokens.light(),
        MeMuslimComponentTokens.light(),
      ],
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final ThemeData darkTheme = ThemeData(
      extensions: [
        MeMuslimDesignTokens.dark(),
        MeMuslimComponentTokens.dark(),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ThemeSwapHost(
          lightTheme: lightTheme,
          darkTheme: darkTheme,
          child: const SizedBox(
            width: 280,
            child: QiblaCompassWidget(
              qiblaDirection: QiblaDirectionEntity(
                qibla: 0,
                direction: 136,
                offset: 136,
              ),
            ),
          ),
        ),
      ),
    );

    final Finder host = find.byType(_ThemeSwapHost);
    await tester.tap(host);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}

class _ThemeSwapHost extends StatefulWidget {
  const _ThemeSwapHost({
    required this.lightTheme,
    required this.darkTheme,
    required this.child,
  });

  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final Widget child;

  @override
  State<_ThemeSwapHost> createState() => _ThemeSwapHostState();
}

class _ThemeSwapHostState extends State<_ThemeSwapHost> {
  bool _useDark = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _useDark = !_useDark),
      child: Theme(
        data: _useDark ? widget.darkTheme : widget.lightTheme,
        child: Scaffold(body: Center(child: widget.child)),
      ),
    );
  }
}
