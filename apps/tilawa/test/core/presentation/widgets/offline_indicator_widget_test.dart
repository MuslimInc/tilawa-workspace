import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/presentation/widgets/offline_indicator_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa_core/presentation/bloc/internet_status/internet_status_state.dart';

class _MockInternetStatusBloc extends MockCubit<InternetStatusState>
    implements InternetStatusBloc {}

Future<void> _pumpOfflineIndicator(
  WidgetTester tester, {
  required InternetStatusState state,
  EdgeInsets viewPadding = EdgeInsets.zero,
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
      home: MediaQuery(
        data: MediaQueryData(padding: viewPadding),
        child: BlocProvider<InternetStatusBloc>.value(
          value: bloc,
          child: const Scaffold(
            body: OfflineIndicatorWidget(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('OfflineIndicatorWidget', () {
    testWidgets('hides banner when internet is connected', (tester) async {
      await _pumpOfflineIndicator(
        tester,
        state: const InternetStatusState.connected(),
      );

      expect(find.text('No Internet Connection'), findsNothing);
    });

    testWidgets('shows localized message when disconnected', (tester) async {
      await _pumpOfflineIndicator(
        tester,
        state: const InternetStatusState.disconnected(),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
    });

    testWidgets(
      'positions message below top safe area when disconnected',
      (tester) async {
        const double topInset = 44;

        await _pumpOfflineIndicator(
          tester,
          state: const InternetStatusState.disconnected(),
          viewPadding: const EdgeInsets.only(top: topInset),
        );

        final Offset messageTop = tester.getTopLeft(
          find.text('No Internet Connection'),
        );

        expect(messageTop.dy, greaterThanOrEqualTo(topInset));
      },
    );

    testWidgets(
      'extends error background behind status bar when disconnected',
      (tester) async {
        const double topInset = 44;

        await _pumpOfflineIndicator(
          tester,
          state: const InternetStatusState.disconnected(),
          viewPadding: const EdgeInsets.only(top: topInset),
        );

        final Finder background = find.descendant(
          of: find.byType(OfflineIndicatorWidget),
          matching: find.byType(ColoredBox),
        );
        final Offset backgroundTop = tester.getTopLeft(background);
        final Offset messageTop = tester.getTopLeft(
          find.text('No Internet Connection'),
        );

        expect(backgroundTop.dy, 0);
        expect(messageTop.dy, greaterThan(backgroundTop.dy + topInset - 1));
      },
    );
  });
}
