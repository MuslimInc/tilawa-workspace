import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:quran_sessions/src/presentation/widgets/pending_reschedule_banner.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

PendingRescheduleRequest _sampleRequest({
  String reason = 'Need a later slot.',
}) {
  return PendingRescheduleRequest(
    requestId: 'req_1',
    bookingId: 'booking_1',
    requestedByUserId: 'student_1',
    requestedByRole: ActorRole.student,
    reason: reason,
    newStartsAt: DateTime.utc(2026, 7, 2, 14),
    status: 'pending',
  );
}

Future<void> _pumpBanner(
  WidgetTester tester, {
  required PendingRescheduleRequest request,
  bool canRespond = false,
  bool isAwaitingCounterparty = false,
  bool respondInProgress = false,
  VoidCallback? onAccept,
  VoidCallback? onReject,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      localizationsDelegates: const [
        QuranSessionsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: Scaffold(
        body: PendingRescheduleBanner(
          request: request,
          canRespond: canRespond,
          isAwaitingCounterparty: isAwaitingCounterparty,
          respondInProgress: respondInProgress,
          onAccept: onAccept ?? () {},
          onReject: onReject ?? () {},
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('counterparty sees accept and reject actions with reason', (
    tester,
  ) async {
    final request = _sampleRequest();
    await _pumpBanner(
      tester,
      request: request,
      canRespond: true,
    );

    final context = tester.element(find.byType(PendingRescheduleBanner));
    final material = MaterialLocalizations.of(context);
    final localStart = request.newStartsAt.toLocal();
    final expectedProposedTime =
        '${material.formatFullDate(localStart)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(localStart))}';

    expect(find.text('Reschedule request'), findsOneWidget);
    expect(
      find.textContaining('Proposed time: $expectedProposedTime'),
      findsOneWidget,
    );
    expect(find.textContaining('Need a later slot.'), findsOneWidget);
    expect(find.text('Accept new time'), findsOneWidget);
    expect(find.text('Keep current time'), findsOneWidget);
    expect(find.text('Waiting for the other participant'), findsNothing);
  });

  testWidgets('requester sees awaiting message without respond actions', (
    tester,
  ) async {
    await _pumpBanner(
      tester,
      request: _sampleRequest(reason: '  '),
      isAwaitingCounterparty: true,
    );

    expect(find.text('Reschedule request'), findsOneWidget);
    expect(
      find.text(
        'Waiting for the other participant to confirm your new time.',
      ),
      findsOneWidget,
    );
    expect(find.text('Accept new time'), findsNothing);
    expect(find.text('Keep current time'), findsNothing);
    expect(find.textContaining('Reason:'), findsNothing);
  });

  testWidgets('banner hidden when user cannot respond or await counterparty', (
    tester,
  ) async {
    await _pumpBanner(
      tester,
      request: _sampleRequest(),
    );

    expect(find.byType(TilawaCard), findsNothing);
    expect(find.text('Reschedule request'), findsNothing);
  });

  testWidgets('accept and reject tap invoke callbacks when not in progress', (
    tester,
  ) async {
    var acceptCount = 0;
    var rejectCount = 0;

    await _pumpBanner(
      tester,
      request: _sampleRequest(),
      canRespond: true,
      onAccept: () => acceptCount++,
      onReject: () => rejectCount++,
    );

    await tester.tap(find.text('Accept new time'));
    await tester.pump();
    expect(acceptCount, 1);

    await tester.tap(find.text('Keep current time'));
    await tester.pump();
    expect(rejectCount, 1);
  });

  testWidgets('respond in progress disables accept and reject buttons', (
    tester,
  ) async {
    await _pumpBanner(
      tester,
      request: _sampleRequest(),
      canRespond: true,
      respondInProgress: true,
      settle: false,
    );

    final buttons = tester.widgetList<TilawaButton>(find.byType(TilawaButton));
    expect(buttons.length, 2);
    for (final button in buttons) {
      expect(button.onPressed, isNull);
      expect(button.isLoading, isTrue);
    }
  });
}
