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
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);

    final voiceSemantics = tester.getSemantics(find.text('Voice'));
    final videoSemantics = tester.getSemantics(find.text('Video'));
    expect(voiceSemantics.flagsCollection.isEnabled, Tristate.isFalse);
    expect(videoSemantics.flagsCollection.isEnabled, Tristate.isFalse);

    await tester.tap(find.text('Voice'));
    await tester.pump();

    final externalSemantics = tester.getSemantics(find.text('External link'));
    expect(externalSemantics.flagsCollection.isSelected, Tristate.isTrue);

    expect(
      find.text(
        'Voice sessions are not available yet. Choose external link.',
      ),
      findsOneWidget,
    );
  });

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
}
