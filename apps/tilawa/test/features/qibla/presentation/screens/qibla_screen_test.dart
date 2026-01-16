import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:tilawa/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:tilawa/features/qibla/presentation/widgets/qibla_compass_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockQiblaBloc extends MockBloc<QiblaEvent, QiblaState>
    implements QiblaBloc {}

void main() {
  late MockQiblaBloc mockQiblaBloc;
  final GetIt getIt = GetIt.instance;

  setUp(() {
    mockQiblaBloc = MockQiblaBloc();
    if (getIt.isRegistered<QiblaBloc>()) {
      getIt.unregister<QiblaBloc>();
    }
    getIt.registerSingleton<QiblaBloc>(mockQiblaBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestWidget() {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      builder: (_, _) => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QiblaScreen(),
      ),
    );
  }

  testWidgets('renders loading state', (tester) async {
    when(
      () => mockQiblaBloc.state,
    ).thenReturn(const QiblaState(status: QiblaStatus.loading));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders success state with compass', (tester) async {
    const direction = QiblaDirectionEntity(
      qibla: 100,
      direction: 90,
      offset: 10,
    );
    when(() => mockQiblaBloc.state).thenReturn(
      const QiblaState(status: QiblaStatus.success, direction: direction),
    );

    // Mock asset loading might be needed if QiblaCompassWidget uses assets.
    // Assuming assets exist or using a mock bundle if not.
    // QiblaCompassWidget uses 'assets/images/qibla_dial.png' etc.
    // If specific tests failed before for assets, we might need a workaround.

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(QiblaCompassWidget), findsOneWidget);
  });

  testWidgets('renders service disabled error', (tester) async {
    when(
      () => mockQiblaBloc.state,
    ).thenReturn(const QiblaState(status: QiblaStatus.serviceDisabled));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.location_off_rounded), findsOneWidget);
    // Button check
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('renders permission denied error', (tester) async {
    when(
      () => mockQiblaBloc.state,
    ).thenReturn(const QiblaState(status: QiblaStatus.permissionDenied));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.security_rounded), findsOneWidget);
  });
}
