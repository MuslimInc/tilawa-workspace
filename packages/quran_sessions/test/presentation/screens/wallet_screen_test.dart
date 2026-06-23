import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fakes/fake_wallet_repository.dart';

void main() {
  testWidgets('WalletScreen shows empty state when no wallet', (tester) async {
    final repository = FakeWalletRepository.empty();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => WalletBloc(
            getWalletSnapshot: GetWalletSnapshotUseCase(repository),
          )..add(const WalletLoadRequested(userId: 'student1')),
          child: const WalletScreen(userId: 'student1'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('My wallet'), findsOneWidget);
    expect(
      find.text('Credits appear when refunds are processed.'),
      findsOneWidget,
    );
  });
}
