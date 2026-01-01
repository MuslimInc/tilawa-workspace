import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa/core/presentation/bloc/internet_status/internet_status_event.dart';
import 'package:tilawa/core/presentation/bloc/internet_status/internet_status_state.dart';
import 'package:tilawa/core/presentation/widgets/offline_indicator_widget.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockInternetStatusBloc
    extends MockBloc<InternetStatusEvent, InternetStatusState>
    implements InternetStatusBloc {}

void main() {
  late MockInternetStatusBloc mockBloc;

  setUp(() {
    mockBloc = MockInternetStatusBloc();
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilPlusInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: BlocProvider<InternetStatusBloc>.value(
          value: mockBloc,
          child: const Scaffold(body: OfflineIndicatorWidget()),
        ),
      ),
    );
  }

  group('OfflineIndicatorWidget', () {
    testWidgets('shows nothing when connected', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const InternetStatusState.connected());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Container), findsNothing);
      expect(find.text('No Internet Connection'), findsNothing);
    });

    testWidgets('shows offline message when disconnected', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const InternetStatusState.disconnected());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget); // The red container
    });
  });
}
