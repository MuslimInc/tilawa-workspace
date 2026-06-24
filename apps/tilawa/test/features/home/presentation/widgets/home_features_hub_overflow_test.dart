import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/home/presentation/widgets/home_features_hub.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa/screens/cubit/main_screen_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockMainScreenCubit extends MockCubit<MainScreenState>
    implements MainScreenCubit {}

void main() {
  testWidgets('category grid tiles fit fixed height without overflow', (
    tester,
  ) async {
    final mainScreenCubit = _MockMainScreenCubit();
    when(() => mainScreenCubit.state).thenReturn(const MainScreenState());
    when(() => mainScreenCubit.stream).thenAnswer((_) => const Stream.empty());

    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    addTearDown(view.resetDevicePixelRatio);
    addTearDown(view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider<MainScreenCubit>.value(
              value: mainScreenCubit,
              child: HomeFeaturesHub(onOpenPrayer: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TilawaFeatureCategoryTile), findsNWidgets(8));
  });
}
