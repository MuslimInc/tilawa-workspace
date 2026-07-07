import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'seeded_booking_bloc.dart';
import 'success_emitting_booking_bloc.dart';

TeacherAvailability _slot(int day) {
  final start = DateTime.utc(2026, 7, day, 10);
  return TeacherAvailability(
    slotId: 'slot_$day',
    teacherId: 'teacher_1',
    startsAt: start,
    endsAt: start.add(const Duration(hours: 1)),
    isBooked: false,
  );
}

void main() {
  testWidgets('invokes onBookingStarted with the teacher id on open', (
    tester,
  ) async {
    String? startedTeacherId;
    final slots = [_slot(1)];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<BookingBloc>(
          create: (_) => SeededBookingBloc(
            seed: BookingSelecting(
              teacherId: 'teacher_1',
              availableSlots: slots,
              selectedSlot: slots.first,
              selectedCallType: SessionCallType.externalMeeting,
            ),
          ),
          child: BookingScreen(
            teacherId: 'teacher_1',
            studentId: 'student_1',
            analytics: QuranSessionsAnalyticsCallbacks(
              onBookingStarted: (id) => startedTeacherId = id,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(startedTeacherId, 'teacher_1');
  });

  testWidgets('invokes onBookingCompleted with safe properties on success', (
    tester,
  ) async {
    String? capturedTeacherId;
    String? capturedBookingId;
    bool? capturedIsPaid;
    String? capturedPricingType;
    String? capturedCallType;

    final bloc = SuccessEmittingBookingBloc();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        home: BlocProvider<BookingBloc>.value(
          value: bloc,
          child: BookingScreen(
            teacherId: 'teacher_1',
            studentId: 'student_1',
            onBookingSuccess: (_) {},
            analytics: QuranSessionsAnalyticsCallbacks(
              onBookingCompleted:
                  ({
                    required teacherId,
                    required bookingId,
                    required isPaid,
                    pricingType,
                    callType,
                  }) {
                    capturedTeacherId = teacherId;
                    capturedBookingId = bookingId;
                    capturedIsPaid = isPaid;
                    capturedPricingType = pricingType;
                    capturedCallType = callType;
                  },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    bloc.emitSuccess(
      QuranBooking(
        id: 'b1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        slotId: 'slot_1',
        requestedCallType: SessionCallType.voiceCall,
        pricingType: SessionPricingType.fixedPerSession,
        status: BookingStatus.confirmed,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(capturedTeacherId, 'teacher_1');
    expect(capturedBookingId, 'b1');
    expect(capturedIsPaid, isTrue);
    expect(capturedPricingType, 'fixedPerSession');
    expect(capturedCallType, 'voiceCall');
  });

  testWidgets('booking confirm stays visible with many slots', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final slots = List.generate(20, (index) => _slot(index + 1));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<BookingBloc>(
          create: (_) => SeededBookingBloc(
            seed: BookingSelecting(
              teacherId: 'teacher_1',
              availableSlots: slots,
              selectedSlot: slots.first,
              selectedCallType: SessionCallType.externalMeeting,
            ),
          ),
          child: const BookingScreen(
            teacherId: 'teacher_1',
            studentId: 'student_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TilawaBottomActionArea), findsOneWidget);
    expect(find.text('Confirm booking'), findsOneWidget);
    expect(find.text('Choose a time'), findsOneWidget);
    expect(find.text('Session type'), findsOneWidget);
  });

  testWidgets('externalOnly policy shows disabled voice and video segments', (
    tester,
  ) async {
    final slots = [_slot(1)];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<BookingBloc>(
          create: (_) => SeededBookingBloc(
            seed: BookingSelecting(
              teacherId: 'teacher_1',
              availableSlots: slots,
              selectedSlot: slots.first,
              selectedCallType: SessionCallType.externalMeeting,
              teacherExternalMeetingUrl: 'https://meet.example.com/room',
            ),
          ),
          child: const BookingScreen(
            teacherId: 'teacher_1',
            studentId: 'student_1',
            sessionModePolicy: SessionModePolicy.externalOnly,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('External link'), findsOneWidget);
    // Voice and Video are no longer rendered as disabled segments; the control is hidden.
    expect(find.text('Voice'), findsNothing);
    expect(find.text('Video'), findsNothing);
    expect(find.byType(TilawaSegmentedControl<SessionCallType>), findsNothing);
  });

  testWidgets(
    'videoOnly policy shows static label instead of segmented control',
    (
      tester,
    ) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                teacherExternalMeetingUrl: null,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
              sessionModePolicy: SessionModePolicy.videoOnly,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Video session'), findsOneWidget);
      // Should NOT show segments for other types
      expect(find.text('External link'), findsNothing);
      expect(find.text('Voice'), findsNothing);
      expect(
        find.byType(TilawaSegmentedControl<SessionCallType>),
        findsNothing,
      );
    },
  );

  testWidgets('teacher without meeting URL disables external and selects voice', (
    tester,
  ) async {
    final slots = [_slot(1)];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: BlocProvider<BookingBloc>(
          create: (_) => SeededBookingBloc(
            seed: BookingSelecting(
              teacherId: 'teacher_1',
              availableSlots: slots,
              selectedSlot: slots.first,
              selectedCallType: SessionCallType.voiceCall,
              teacherExternalMeetingUrl: null,
            ),
          ),
          child: const BookingScreen(
            teacherId: 'teacher_1',
            studentId: 'student_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final externalSemantics = tester.getSemantics(find.text('External link'));
    final voiceSemantics = tester.getSemantics(find.text('Voice'));
    expect(externalSemantics.flagsCollection.isEnabled, Tristate.isFalse);
    expect(voiceSemantics.flagsCollection.isSelected, Tristate.isTrue);

    expect(
      find.text(
        'Your teacher has not added a meeting link yet. Choose voice or video.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'paid session shows price summary and price is visible before booking',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                pricingType: SessionPricingType.fixedPerSession,
                sessionPrice: const SessionPrice(
                  amount: 50,
                  currencyCode: 'EGP',
                  countryCode: 'EG',
                  cityId: 'cairo',
                ),
                paymentProviderAvailable: true,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session price'), findsOneWidget);
      expect(find.textContaining('50'), findsWidgets);
      // Provider available: the confirm CTA stays enabled.
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'free session with payment provider disabled shows no payment error '
    'and enables submit once a slot is selected',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                pricingType: SessionPricingType.free,
                sessionPrice: null,
                // Provider off must not surface any payment error for free.
                paymentProviderAvailable: false,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free'), findsOneWidget);
      expect(
        find.textContaining('payment is not available'),
        findsNothing,
      );
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'paid session with payment provider disabled blocks booking in the UI',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                pricingType: SessionPricingType.fixedPerSession,
                sessionPrice: const SessionPrice(
                  amount: 50,
                  currencyCode: 'EGP',
                  countryCode: 'EG',
                  cityId: 'cairo',
                ),
                paymentProviderAvailable: false,
                blockReason: BookingBlockReason.paymentProviderUnavailable,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The server-reported typed block reason maps to the paid-unavailable
      // banner — not the old generic "payment not available" string.
      expect(
        find.text('Paid booking is currently unavailable.'),
        findsOneWidget,
      );
      expect(
        find.text('You can choose a free teacher or try again later.'),
        findsOneWidget,
      );
      // The confirm CTA must be disabled even with a slot selected.
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'free session shows no payment error and enables the CTA even when the '
    'payment provider is unavailable',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                // Free session: no price, provider unavailability is irrelevant.
                pricingType: SessionPricingType.free,
                sessionPrice: null,
                paymentProviderAvailable: false,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The paid-session payment-unavailable notice must NOT appear.
      expect(
        find.text(
          'This session requires payment, but payment is not available '
          'yet. Booking is temporarily unavailable.',
        ),
        findsNothing,
      );
      // The price summary shows the session as free.
      expect(find.text('Free'), findsOneWidget);
      // A valid slot alone enables submission for a free session.
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'pricing quote unavailable shows retry copy and blocks submit',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                blockReason: BookingBlockReason.pricingQuoteUnavailable,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('We could not verify the session price right now.'),
        findsOneWidget,
      );
      expect(
        find.text('Please check your connection and try again.'),
        findsOneWidget,
      );
      expect(
        find.text('Paid booking is currently unavailable.'),
        findsNothing,
      );
      expect(find.text('Session price'), findsNothing);
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'admin booking disabled shows the admin-disabled banner and blocks submit',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                blockReason: BookingBlockReason.bookingDisabledByAdmin,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Booking is currently unavailable.'),
        findsOneWidget,
      );
      expect(
        find.text('Booking has been temporarily paused by the admin.'),
        findsOneWidget,
      );
      // Admin-disabled must NOT show the paid-unavailable banner.
      expect(
        find.text('Paid booking is currently unavailable.'),
        findsNothing,
      );
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'pricing config missing shows the pricing-incomplete banner and blocks submit',
    (tester) async {
      final slots = [_slot(1)];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: const [
            QuranSessionsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<BookingBloc>(
            create: (_) => SeededBookingBloc(
              seed: BookingSelecting(
                teacherId: 'teacher_1',
                availableSlots: slots,
                selectedSlot: slots.first,
                selectedCallType: SessionCallType.videoCall,
                blockReason: BookingBlockReason.pricingConfigMissing,
              ),
            ),
            child: const BookingScreen(
              teacherId: 'teacher_1',
              studentId: 'student_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Booking is unavailable right now.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Pricing configuration is incomplete. Please try again later.',
        ),
        findsOneWidget,
      );
      final button = tester.widget<TilawaButton>(
        find.byWidgetPredicate(
          (w) => w is TilawaButton && w.text == 'Confirm booking',
        ),
      );
      expect(button.onPressed, isNull);
    },
  );
}
