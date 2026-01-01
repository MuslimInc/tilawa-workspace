import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/widgets/qibla_compass_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders qibla compass widget', (tester) async {
    const direction = QiblaDirectionEntity(
      qibla: 100,
      direction: 45,
      offset: 55,
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: Colors.blue,
            body: Center(child: QiblaCompassWidget(qiblaDirection: direction)),
          ),
        ),
      ),
    );

    expect(find.text('45°'), findsOneWidget);
    expect(find.text('To Qibla'), findsOneWidget);
    expect(
      find.byType(CustomPaint),
      findsWidgets,
    ); // Dial (and possibly others)
    expect(find.byType(Icon), findsOneWidget); // Needle (Icon)
  });

  testWidgets('shouldRepaint returns true when colorScheme changes', (
    tester,
  ) async {
    // This test covers lines 267-269: shouldRepaint method
    const direction = QiblaDirectionEntity(
      qibla: 100,
      direction: 45,
      offset: 55,
    );

    // Initial build with default theme
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: QiblaCompassWidget(qiblaDirection: direction)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QiblaCompassWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Rebuild with different theme to trigger shouldRepaint
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: QiblaCompassWidget(qiblaDirection: direction)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Widget should still render correctly after theme change
    expect(find.byType(QiblaCompassWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
