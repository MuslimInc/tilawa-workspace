import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required ThemeData theme,
    GoogleSignInButtonAppearance appearance = GoogleSignInButtonAppearance.auto,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: TilawaGoogleSignInButton(
            label: 'Sign in with Google',
            appearance: appearance,
            isLoading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Material findButtonMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(
        of: find.byType(TilawaGoogleSignInButton),
        matching: find.byType(Material),
      ),
    );
  }

  testWidgets('uses Google brand fill, border, and pill shape in light mode', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.getLightTheme(
      primaryColor: AppColors.defaultPrimary,
    );

    await pumpButton(
      tester,
      theme: theme,
      appearance: GoogleSignInButtonAppearance.light,
      onPressed: () {},
    );

    final Material material = findButtonMaterial(tester);
    final StadiumBorder shape = material.shape! as StadiumBorder;
    final double expectedRadius = theme.tokens.resolveRadius(
      family: TilawaRadiusFamily.pill,
      height: theme.tokens.minInteractiveDimension,
    );

    expect(material.color, GoogleSignInButtonBrand.lightFill);
    expect(material.elevation, 0);
    expect(shape.side.color, GoogleSignInButtonBrand.lightBorder);
    expect(shape.side.width, GoogleSignInButtonBrand.borderWidth);
    expect(expectedRadius, 24.0);

    final Text label = tester.widget(find.text('Sign in with Google'));
    expect(label.style?.fontFamily, 'Roboto');
    expect(label.style?.fontWeight, FontWeight.w500);
    expect(label.style?.fontSize, GoogleSignInButtonBrand.labelFontSize);
    expect(label.style?.color, GoogleSignInButtonBrand.lightLabel);
  });

  testWidgets('uses Google brand dark theme colors', (
    WidgetTester tester,
  ) async {
    await pumpButton(
      tester,
      theme: AppTheme.getDarkTheme(primaryColor: AppColors.defaultPrimary),
      appearance: GoogleSignInButtonAppearance.dark,
      onPressed: () {},
    );

    final Material material = findButtonMaterial(tester);
    final StadiumBorder shape = material.shape! as StadiumBorder;

    expect(material.color, GoogleSignInButtonBrand.darkFill);
    expect(shape.side.color, GoogleSignInButtonBrand.darkBorder);
  });

  testWidgets('uses neutral fill without stroke', (WidgetTester tester) async {
    await pumpButton(
      tester,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      appearance: GoogleSignInButtonAppearance.neutral,
      onPressed: () {},
    );

    final Material material = findButtonMaterial(tester);
    final StadiumBorder shape = material.shape! as StadiumBorder;

    expect(material.color, GoogleSignInButtonBrand.neutralFill);
    expect(shape.side, BorderSide.none);
  });

  testWidgets('places the logo on the leading edge with centered label', (
    WidgetTester tester,
  ) async {
    await pumpButton(
      tester,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      onPressed: () {},
    );

    expect(find.byType(PositionedDirectional), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('shows loading indicator instead of label when loading', (
    WidgetTester tester,
  ) async {
    await pumpButton(
      tester,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      isLoading: true,
      onPressed: () {},
    );

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });
}
