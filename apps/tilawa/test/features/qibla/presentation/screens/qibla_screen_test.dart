import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:tilawa/features/qibla/presentation/constants/qibla_error_codes.dart';
import 'package:tilawa/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:tilawa/features/qibla/presentation/widgets/qibla_compass_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/shared/widgets/kaaba_icon.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockQiblaBloc extends MockBloc<QiblaEvent, QiblaState>
    implements QiblaBloc {}

const QiblaDirectionEntity _sampleDirection = QiblaDirectionEntity(
  qibla: 1,
  direction: 139,
  offset: 136,
);

const QiblaDirectionEntity _alignedDirection = QiblaDirectionEntity(
  qibla: 0,
  direction: 136,
  offset: 136,
);

const QiblaDirectionEntity _poorAccuracyDirection = QiblaDirectionEntity(
  qibla: 1,
  direction: 120,
  offset: 136,
  accuracy: 50,
);

Future<MockQiblaBloc> _pumpQiblaScreen(
  WidgetTester tester, {
  required QiblaState state,
  Stream<QiblaState>? stateStream,
  Size viewport = const Size(400, 800),
}) async {
  final MockQiblaBloc bloc = MockQiblaBloc();

  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer(
    (_) => stateStream ?? Stream<QiblaState>.value(state),
  );
  when(() => bloc.isClosed).thenReturn(false);
  when(() => bloc.add(any())).thenReturn(null);

  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => TilawaFeedbackHost(child: child!),
      home: BlocProvider<QiblaBloc>.value(
        value: bloc,
        child: const QiblaScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return bloc;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const CheckLocationService());
    registerFallbackValue(const StopQiblaStream());
    registerFallbackValue(const RequestLocationPermission());
    registerFallbackValue(const UpdateQiblaDirection(_sampleDirection));
  });

  group('QiblaScreen lifecycle', () {
    testWidgets('requests location check after first frame', (tester) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.initial),
      );

      verify(() => bloc.add(const CheckLocationService())).called(1);
    });

    testWidgets('stops qibla stream on dispose', (tester) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.initial),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      verify(() => bloc.add(const StopQiblaStream())).called(1);
    });
  });

  group('QiblaScreen portrait states', () {
    testWidgets('shows loading indicator while loading', (tester) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.loading),
      );

      expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows service disabled state with retry', (tester) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.serviceDisabled),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.locationServiceDisabled), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pump();

      verify(() => bloc.add(const CheckLocationService())).called(2);
    });

    testWidgets('shows permission denied state with retry', (tester) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.permissionDenied),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.permissionDenied), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pump();

      verify(() => bloc.add(const RequestLocationPermission())).called(1);
    });

    testWidgets('shows error state with message and retry', (tester) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.error,
          errorMessage: QiblaErrorCodes.sensorFailed,
        ),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.unableToFindQibla), findsOneWidget);
      expect(find.text(l10n.qiblaSensorUnavailableMessage), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pump();

      verify(() => bloc.add(const CheckLocationService())).called(2);
    });

    testWidgets('shows compass when success has direction', (tester) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.success,
          direction: _sampleDirection,
        ),
      );

      expect(find.byType(QiblaCompassWidget), findsOneWidget);
      expect(find.byType(KaabaIcon), findsOneWidget);
      expect(find.text('136°'), findsOneWidget);
    });

    testWidgets('shows loading when success has no direction yet', (
      tester,
    ) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.success),
      );

      expect(find.byType(QiblaCompassWidget), findsNothing);
      expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows rotate-left hint when not aligned', (tester) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.success,
          direction: _sampleDirection,
        ),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.qiblaRotatePhoneLeft(3)), findsOneWidget);
    });

    testWidgets('shows aligned message when facing qibla', (tester) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.success,
          direction: _alignedDirection,
        ),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.qiblaAligned), findsOneWidget);
    });

    testWidgets('shows rotate-right hint when bearing is clockwise', (
      tester,
    ) async {
      const direction = QiblaDirectionEntity(
        qibla: 1,
        direction: 10,
        offset: 50,
      );

      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.success,
          direction: direction,
        ),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.qiblaRotatePhoneRight(40)), findsOneWidget);
    });
  });

  group('QiblaScreen landscape', () {
    testWidgets('renders compass area in landscape success state', (
      tester,
    ) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.success,
          direction: _sampleDirection,
        ),
        viewport: const Size(1280, 720),
      );

      expect(find.byType(QiblaCompassWidget), findsOneWidget);
    });

    testWidgets('renders unavailable state in landscape', (tester) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.serviceDisabled),
        viewport: const Size(1280, 720),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.locationServiceDisabled), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pump();

      verify(() => bloc.add(const CheckLocationService())).called(2);
    });

    testWidgets('shows loading indicator in landscape while loading', (
      tester,
    ) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.loading),
        viewport: const Size(1280, 720),
      );

      expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows permission denied with retry in landscape', (
      tester,
    ) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.permissionDenied),
        viewport: const Size(1280, 720),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.permissionDenied), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pump();

      verify(() => bloc.add(const RequestLocationPermission())).called(1);
    });

    testWidgets('shows error with fallback message in landscape', (
      tester,
    ) async {
      final MockQiblaBloc bloc = await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.error),
        viewport: const Size(1280, 720),
      );

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.unableToFindQibla), findsOneWidget);
      expect(find.text(l10n.qiblaSensorUnavailableMessage), findsOneWidget);
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pump();

      verify(() => bloc.add(const CheckLocationService())).called(2);
    });

    testWidgets('shows loading when success has no direction in landscape', (
      tester,
    ) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.success),
        viewport: const Size(1280, 720),
      );

      expect(find.byType(QiblaCompassWidget), findsNothing);
      expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
    });

    testWidgets('shows initial loading indicator in landscape', (
      tester,
    ) async {
      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(status: QiblaStatus.initial),
        viewport: const Size(1280, 720),
      );

      expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
    });
  });

  group('QiblaScreen accuracy feedback', () {
    testWidgets('shows poor accuracy toast when accuracy degrades', (
      tester,
    ) async {
      final StreamController<QiblaState> controller =
          StreamController<QiblaState>.broadcast();

      await _pumpQiblaScreen(
        tester,
        state: const QiblaState(
          status: QiblaStatus.success,
          direction: _sampleDirection,
        ),
        stateStream: controller.stream,
      );

      controller.add(
        const QiblaState(
          status: QiblaStatus.success,
          direction: _poorAccuracyDirection,
        ),
      );
      await tester.pump();
      await tester.pump();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(QiblaScreen)),
      );

      expect(find.text(l10n.qiblaCompassAccuracyPoor), findsOneWidget);

      await controller.close();
    });
  });
}
