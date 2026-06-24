import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('End call invokes leave callback before popping route', (
    tester,
  ) async {
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return TilawaButton(
              text: 'Open call',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InAppCallShellScreen(
                      sessionId: 'session_1',
                      onLeaveCall: () async {
                        events.add('leave');
                      },
                      onSetMicrophoneMuted: ({required bool muted}) async {
                        events.add(muted ? 'mute' : 'unmute');
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open call'));
    await tester.pumpAndSettle();

    expect(find.text('Leave call'), findsOneWidget);

    await tester.tap(find.text('Leave call'));
    await tester.pumpAndSettle();

    check(events).deepEquals(['leave']);
    expect(find.text('Leave call'), findsNothing);
    expect(find.text('Open call'), findsOneWidget);
  });

  testWidgets('Mute toggles injected callback before updating label', (
    tester,
  ) async {
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: InAppCallShellScreen(
          sessionId: 'session_1',
          onSetMicrophoneMuted: ({required bool muted}) async {
            events.add(muted ? 'mute' : 'unmute');
          },
        ),
      ),
    );

    expect(find.text('Mute microphone'), findsOneWidget);

    await tester.tap(find.text('Mute microphone'));
    await tester.pumpAndSettle();

    check(events).deepEquals(['mute']);
    expect(find.text('Unmute microphone'), findsOneWidget);

    await tester.tap(find.text('Unmute microphone'));
    await tester.pumpAndSettle();

    check(events).deepEquals(['mute', 'unmute']);
  });

  testWidgets('Mute control hidden when mute callback not injected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: const InAppCallShellScreen(sessionId: 'session_1'),
      ),
    );

    expect(find.text('Mute microphone'), findsNothing);
    expect(find.text('Unmute microphone'), findsNothing);
    expect(find.text('Leave call'), findsOneWidget);
  });

  testWidgets('Injected call surface fills body above controls', (
    tester,
  ) async {
    const surfaceKey = Key('fake_call_surface');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: InAppCallShellScreen(
          sessionId: 'session_1',
          callProviderKind: SessionCallProviderKind.agora,
          callType: SessionCallType.videoCall,
          callSurface: const SizedBox(
            key: surfaceKey,
            child: Text('Video area'),
          ),
          onSetMicrophoneMuted: ({required bool muted}) async {},
        ),
      ),
    );

    expect(find.byKey(surfaceKey), findsOneWidget);
    expect(find.text('Video area'), findsOneWidget);
    expect(find.text('Mute microphone'), findsOneWidget);
    expect(find.text('You are connected'), findsNothing);
  });

  testWidgets('Mock provider shows beta preview banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: const InAppCallShellScreen(
          sessionId: 'session_mock',
          callProviderKind: SessionCallProviderKind.mock,
        ),
      ),
    );

    expect(find.textContaining('Beta preview'), findsOneWidget);
  });
}
