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
  testWidgets('renders four-column category grid labels', (tester) async {
    final mainScreenCubit = _MockMainScreenCubit();
    when(() => mainScreenCubit.state).thenReturn(const MainScreenState());
    when(() => mainScreenCubit.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('en'),
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

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeFeaturesHub)),
    );

    expect(find.text(l10n.homeExploreTitle), findsOneWidget);
    expect(find.text(l10n.homeQuickAthkar), findsOneWidget);
    expect(find.text(l10n.homeQuickQibla), findsOneWidget);
    expect(find.text(l10n.homeQuickTasbeeh), findsOneWidget);
    expect(find.text(l10n.homeQuickPrayer), findsOneWidget);
    expect(find.text(l10n.bookmarks), findsOneWidget);
    expect(find.text(l10n.homeQuickQuran), findsOneWidget);
    expect(find.text(l10n.homeQuickReciters), findsOneWidget);
    expect(find.text(l10n.supportTilawa), findsOneWidget);
    expect(find.byType(TilawaFeatureCategoryTile), findsNWidgets(8));
  });
}
