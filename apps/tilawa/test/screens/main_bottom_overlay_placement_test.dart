import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/widgets/main_bottom_overlay.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_state.dart';

class _MockInternetStatusBloc extends MockCubit<InternetStatusState>
    implements InternetStatusBloc {}

const _destinations = <TilawaNavDestination>[
  TilawaNavDestination(label: 'Home', icon: Icons.home_outlined),
];

Future<void> _pumpShellWithOfflineBanner(
  WidgetTester tester, {
  required InternetStatusState state,
}) async {
  final _MockInternetStatusBloc bloc = _MockInternetStatusBloc();
  when(() => bloc.state).thenReturn(state);
  when(() => bloc.stream).thenAnswer(
    (_) => Stream<InternetStatusState>.value(state),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<InternetStatusBloc>.value(
        value: bloc,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MainBottomOverlay(
              isOfflineIndicatorReady: true,
            ),
            Expanded(
              child: TilawaAdaptiveShell(
                destinations: _destinations,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                bottomPlayer: const SizedBox.shrink(),
                child: Scaffold(
                  appBar: AppBar(title: const Text('Teacher Dashboard')),
                  body: const Center(child: Text('Body')),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('offline banner sits below app bar not over title', (
    tester,
  ) async {
    await _pumpShellWithOfflineBanner(
      tester,
      state: const InternetStatusState.disconnected(),
    );

    final Offset appBarTop = tester.getTopLeft(find.byType(AppBar));
    final Offset bannerBottom = tester.getBottomLeft(
      find.text('No Internet Connection'),
    );

    expect(bannerBottom.dy, lessThanOrEqualTo(appBarTop.dy + 1));
  });
}
