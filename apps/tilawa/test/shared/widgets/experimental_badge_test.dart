import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MaterialApp(
    theme:
        theme ?? AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TilawaExperimentalBadge', () {
    testWidgets('renders English label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaExperimentalBadge(label: 'Experimental'),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Experimental'), findsOneWidget);
    });

    testWidgets('renders Arabic label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaExperimentalBadge(label: 'تجريبي'),
          locale: const Locale('ar'),
        ),
      );
      expect(find.text('تجريبي'), findsOneWidget);
    });

    testWidgets('renders custom override label', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaExperimentalBadge(label: 'Preview')),
      );
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Experimental'), findsNothing);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TilawaExperimentalBadge(
            label: 'Experimental',
            icon: Icons.science_outlined,
          ),
        ),
      );
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    });

    testWidgets('does not render icon when omitted', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaExperimentalBadge(label: 'Experimental')),
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('uses foregroundColor override for label text', (tester) async {
      final lightTheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      await tester.pumpWidget(
        _wrap(
          TilawaExperimentalBadge(
            label: 'Experimental',
            foregroundColor: lightTheme.colorScheme.onSurface,
          ),
          theme: lightTheme,
        ),
      );

      final text = tester.widget<Text>(find.text('Experimental'));
      expect(text.style?.color, lightTheme.colorScheme.onSurface);
    });

    testWidgets('applies light theme caution background color', (tester) async {
      final lightTheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      await tester.pumpWidget(
        _wrap(
          const TilawaExperimentalBadge(label: 'Experimental'),
          theme: lightTheme,
        ),
      );
      final tokens = lightTheme.componentTokens.experimentalBadge;
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, tokens.backgroundColor);
    });

    testWidgets('applies dark theme caution background color', (tester) async {
      final darkTheme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: Center(child: TilawaExperimentalBadge(label: 'Experimental')),
          ),
        ),
      );
      final tokens = darkTheme.componentTokens.experimentalBadge;
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, tokens.backgroundColor);
    });

    testWidgets('fires onTap callback when tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          TilawaExperimentalBadge(
            label: 'Experimental',
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(TilawaExperimentalBadge));
      expect(tapped, isTrue);
    });

    testWidgets('no interactive surface when onTap is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaExperimentalBadge(label: 'Experimental')),
      );
      expect(find.byType(TilawaInteractiveSurface), findsNothing);
    });

    testWidgets('has interactive surface when onTap is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TilawaExperimentalBadge(label: 'Experimental', onTap: () {}),
        ),
      );
      expect(find.byType(TilawaInteractiveSurface), findsOneWidget);
    });

    testWidgets('semantics label matches rendered text', (tester) async {
      await tester.pumpWidget(
        _wrap(const TilawaExperimentalBadge(label: 'Experimental')),
      );
      final semanticsNodes = tester.semantics
          .simulatedAccessibilityTraversal()
          .where((n) => n.label == 'Experimental');
      expect(semanticsNodes, isNotEmpty);
    });

    testWidgets('token lerp produces finite values', (tester) async {
      final light = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final dark = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final a = light.componentTokens.experimentalBadge;
      final b = dark.componentTokens.experimentalBadge;
      final mid = TilawaExperimentalBadgeTokens.lerp(a, b, 0.5);
      expect(mid.borderWidth.isFinite, isTrue);
      expect(mid.iconSize.isFinite, isTrue);
      expect(mid.iconGap.isFinite, isTrue);
      expect(mid.letterSpacing.isFinite, isTrue);
    });
  });
}
