import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        TilawaDesignTokens.light(),
        TilawaComponentTokens.light(),
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
    expect(find.byType(SvgPicture), findsWidgets);
    expect(find.text('270°'), findsOneWidget);
  });
}
