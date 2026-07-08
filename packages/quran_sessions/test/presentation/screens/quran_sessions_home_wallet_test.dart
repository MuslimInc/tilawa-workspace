import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_pricing_quote_gateway.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

const _paidUnavailableQuote = SessionPricingQuote(
  pricingType: SessionPricingType.fixedPerSession,
  amount: 100,
  currencyCode: 'EGP',
  paymentRequired: true,
  paymentProviderAvailable: false,
  bookingEnabled: true,
  quranSessionsEnabled: true,
  effectivePricingSource: EffectivePricingSource.marketConfig,
  blockReason: BookingBlockReason.paymentProviderUnavailable,
);

GetTeacherAvailabilityUseCase _availabilityUseCase() {
  return GetTeacherAvailabilityUseCase(
    scheduleRepository: FakeScheduleRepository(),
    bookedSlotLocks: FakeBookedSlotLockRepository(),
  );
}

void main() {
  testWidgets('hides wallet action when walletEnabled is false', (
    tester,
  ) async {
    final repo = FakeTeacherRepository();

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
          create: (_) => TeacherListBloc(
            ResolveTeacherListUseCase(GetTeachersUseCase(repo)),
            _availabilityUseCase(),
          )..add(const LoadTeachersRequested()),
          child: QuranSessionsHomeScreen(
            featureConfig: const QuranSessionsFeatureConfig(
              walletEnabled: false,
            ),
            onMySessions: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Wallet'), findsNothing);
    expect(find.text('My sessions'), findsOneWidget);
  });

  testWidgets('shows wallet action when walletEnabled is true', (tester) async {
    final repo = FakeTeacherRepository();

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
          create: (_) => TeacherListBloc(
            ResolveTeacherListUseCase(GetTeachersUseCase(repo)),
            _availabilityUseCase(),
          )..add(const LoadTeachersRequested()),
          child: QuranSessionsHomeScreen(
            featureConfig: const QuranSessionsFeatureConfig(
              walletEnabled: true,
            ),
            onWallet: () {},
            onMySessions: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Wallet'), findsOneWidget);
  });

  testWidgets('shows no-bookable empty reason when quotes block all teachers', (
    tester,
  ) async {
    final repo = FakeTeacherRepository()
      ..teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];

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
          create: (_) => TeacherListBloc(
            ResolveTeacherListUseCase(
              GetTeachersUseCase(repo),
              getPricingQuote: GetBookingPricingQuoteUseCase(
                FakeSessionPricingQuoteGateway(quote: _paidUnavailableQuote),
              ),
            ),
            _availabilityUseCase(),
          )..add(const LoadTeachersRequested()),
          child: QuranSessionsHomeScreen(
            featureConfig: const QuranSessionsFeatureConfig(
              walletEnabled: true,
            ),
            onWallet: () {},
            onMySessions: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Paid booking is currently unavailable.'), findsOneWidget);
    expect(
      find.text(
        'Paid bookings are temporarily unavailable. Please try again later.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Free teachers are not available at the moment. Please check back later.',
      ),
      findsNothing,
    );
  });
}
