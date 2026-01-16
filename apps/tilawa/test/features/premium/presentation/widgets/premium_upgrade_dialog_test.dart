import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_event.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_state.dart';
import 'package:tilawa/features/premium/presentation/widgets/premium_upgrade_dialog.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';

class MockPremiumBloc extends MockBloc<PremiumEvent, PremiumState>
    implements PremiumBloc {}

void main() {
  late MockPremiumBloc mockPremiumBloc;

  setUp(() {
    mockPremiumBloc = MockPremiumBloc();
    const initialState = PremiumState.initial();
    final streamController = StreamController<PremiumState>.broadcast();
    streamController.add(initialState);

    whenListen(
      mockPremiumBloc,
      streamController.stream,
      initialState: initialState,
    );

    addTearDown(() => streamController.close());
  });

  testWidgets('renders premium upgrade dialog contents inline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PremiumBloc>.value(
          value: mockPremiumBloc,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: PremiumUpgradeDialog(
                title: 'Upgrade Title',
                message: 'Upgrade Message',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upgrade Title'), findsOneWidget);
    expect(find.text('Upgrade Message'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsWidgets);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });
}
