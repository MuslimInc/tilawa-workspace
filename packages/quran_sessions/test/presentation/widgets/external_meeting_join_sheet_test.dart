import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const _meetingUrl = 'https://meet.google.com/room';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('external meeting join sheet returns true when Open tapped', (
    tester,
  ) async {
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    confirmed = await showExternalMeetingJoinSheet(
                      context,
                      meetingUrl: _meetingUrl,
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Join outside Tilawa?'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Copy URL'), findsOneWidget);
    expect(
      find.textContaining('Come back here anytime'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('copy URL copies link and shows toast without closing sheet', (
    tester,
  ) async {
    String? clipboardText;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (message) async {
        if (message.method == 'Clipboard.setData') {
          clipboardText =
              (message.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TilawaFeedbackHost(child: child!),
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: const [
          QuranSessionsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showExternalMeetingJoinSheet(
                      context,
                      meetingUrl: _meetingUrl,
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy URL'));
    await tester.pumpAndSettle();

    expect(clipboardText, _meetingUrl);
    expect(find.text('Link copied'), findsOneWidget);
    expect(find.text('Join outside Tilawa?'), findsOneWidget);
  });

  testWidgets('external meeting join sheet can be dismissed', (tester) async {
    bool? confirmed;

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
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    confirmed = await showExternalMeetingJoinSheet(
                      context,
                      meetingUrl: _meetingUrl,
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
  });
}
