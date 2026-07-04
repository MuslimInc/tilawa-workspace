import 'dart:ui' show Tristate;

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('End call invokes gateway leave before popping route', (
    tester,
  ) async {
    final gateway = _RecordingCallControlGateway();

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
        home: Builder(
          builder: (context) {
            return TilawaButton(
              text: 'Open call',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InAppCallShellScreen(
                      sessionId: 'session_1',
                      callControlGateway: gateway,
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

    await tester.tap(find.byKey(const Key('call_shell_end')));
    await tester.pumpAndSettle();

    check(gateway.leaveCount).equals(1);
    expect(find.byKey(const Key('call_shell_end')), findsNothing);
    expect(find.text('Open call'), findsOneWidget);
  });

  testWidgets('Mute toggles gateway before updating label', (tester) async {
    final gateway = _RecordingCallControlGateway();

    await tester.pumpWidget(
      _shellApp(
        InAppCallShellScreen(
          sessionId: 'session_1',
          callControlGateway: gateway,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Mute microphone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('call_shell_mute')));
    await tester.pumpAndSettle();

    check(gateway.microphoneEnabledCalls).deepEquals([false]);
    expect(find.bySemanticsLabel('Unmute microphone'), findsOneWidget);
  });

  testWidgets('Mute control hidden when gateway not injected', (tester) async {
    await tester.pumpWidget(
      _shellApp(const InAppCallShellScreen(sessionId: 'session_1')),
    );

    expect(find.byKey(const Key('call_shell_mute')), findsNothing);
    expect(find.byKey(const Key('call_shell_end')), findsOneWidget);
  });

  testWidgets('Toggle controls swap active background on state change', (
    tester,
  ) async {
    final gateway = _RecordingCallControlGateway();
    late ThemeData theme;

    await tester.pumpWidget(
      _shellApp(
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return InAppCallShellScreen(
              sessionId: 'session_1',
              callControlGateway: gateway,
            );
          },
        ),
      ),
    );

    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        theme.componentTokens.iconToggle.inactiveBackgroundColor;
    final activeIconColor = theme.colorScheme.onPrimary;

    expect(
      _callControlMaterialColor(tester, const Key('call_shell_mute')),
      activeColor,
    );
    expect(
      _callControlIconColor(tester, const Key('call_shell_mute')),
      activeIconColor,
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('call_shell_mute')))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );

    await tester.tap(find.byKey(const Key('call_shell_mute')));
    await tester.pumpAndSettle();

    expect(
      _callControlMaterialColor(tester, const Key('call_shell_mute')),
      inactiveColor,
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('call_shell_mute')))
          .flagsCollection
          .isToggled,
      Tristate.isFalse,
    );

    expect(
      _callControlMaterialColor(tester, const Key('call_shell_speaker')),
      inactiveColor,
    );

    await tester.tap(find.byKey(const Key('call_shell_speaker')));
    await tester.pumpAndSettle();

    expect(
      _callControlMaterialColor(tester, const Key('call_shell_speaker')),
      activeColor,
    );
    expect(
      _callControlIconColor(tester, const Key('call_shell_speaker')),
      activeIconColor,
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('call_shell_speaker')))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
  });

  testWidgets('Flip camera disabled when video is off', (tester) async {
    final gateway = _RecordingCallControlGateway();

    await tester.pumpWidget(
      _shellApp(
        InAppCallShellScreen(
          sessionId: 'session_1',
          callType: SessionCallType.videoCall,
          callProviderKind: SessionCallProviderKind.agora,
          callControlGateway: gateway,
        ),
      ),
    );

    final flipButton = find.byKey(const Key('call_shell_flip'));
    expect(flipButton, findsOneWidget);
    expect(
      find.bySemanticsLabel('Switch camera'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('call_shell_video')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(flipButton, warnIfMissed: false);
    await tester.pump();

    check(gateway.switchCameraCount).equals(0);
  });

  testWidgets('Switch camera keeps unified label and icon after switch', (
    tester,
  ) async {
    final gateway = _RecordingCallControlGateway(delaySwitchCamera: true);
    late ThemeData theme;

    await tester.pumpWidget(
      _shellApp(
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return InAppCallShellScreen(
              sessionId: 'session_1',
              callType: SessionCallType.videoCall,
              callProviderKind: SessionCallProviderKind.agora,
              callControlGateway: gateway,
            );
          },
        ),
      ),
    );

    final inactiveColor =
        theme.componentTokens.iconToggle.inactiveBackgroundColor;
    final frontIconColor = theme.colorScheme.onSurface;
    final backIconColor = theme.colorScheme.onSurfaceVariant;

    expect(find.bySemanticsLabel('Switch camera'), findsOneWidget);
    expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
    expect(
      _callControlMaterialColor(tester, const Key('call_shell_flip')),
      inactiveColor,
    );
    expect(
      _callControlIconColor(tester, const Key('call_shell_flip')),
      frontIconColor,
    );

    await tester.tap(find.byKey(const Key('call_shell_flip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Switch camera'), findsOneWidget);
    expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
    expect(find.byIcon(Icons.camera_rear_outlined), findsNothing);
    expect(find.byIcon(Icons.camera_front_outlined), findsNothing);
    expect(
      _callControlMaterialColor(tester, const Key('call_shell_flip')),
      inactiveColor,
    );
    expect(
      _callControlIconColor(tester, const Key('call_shell_flip')),
      backIconColor,
    );
    check(gateway.switchCameraCount).equals(1);
  });

  testWidgets('Switch camera failure shows friendly error toast', (
    tester,
  ) async {
    final gateway = _RecordingCallControlGateway(failSwitchCamera: true);

    await tester.pumpWidget(
      _shellApp(
        InAppCallShellScreen(
          sessionId: 'session_1',
          callType: SessionCallType.videoCall,
          callProviderKind: SessionCallProviderKind.agora,
          callControlGateway: gateway,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('call_shell_flip')));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not complete that action. Try again.'),
      findsOneWidget,
    );
    check(gateway.switchCameraCount).equals(1);
  });

  testWidgets('Switch camera hidden when only one lens available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shellApp(
        InAppCallShellScreen(
          sessionId: 'session_1',
          callType: SessionCallType.videoCall,
          callProviderKind: SessionCallProviderKind.external,
          callControlGateway: _RecordingCallControlGateway(),
        ),
      ),
    );

    expect(find.byKey(const Key('call_shell_flip')), findsNothing);
  });

  testWidgets('Speaker toggle updates active icon state', (tester) async {
    final gateway = _RecordingCallControlGateway();

    await tester.pumpWidget(
      _shellApp(
        InAppCallShellScreen(
          sessionId: 'session_1',
          callControlGateway: gateway,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('call_shell_speaker')));
    await tester.pumpAndSettle();

    check(gateway.speakerEnabledCalls).deepEquals([true]);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.hearing_rounded), findsNothing);
  });

  testWidgets('Injected call surface fills immersive body under chrome', (
    tester,
  ) async {
    const surfaceKey = Key('fake_call_surface');

    await tester.pumpWidget(
      _shellApp(
        InAppCallShellScreen(
          sessionId: 'session_1',
          callProviderKind: SessionCallProviderKind.agora,
          callType: SessionCallType.videoCall,
          callSurface: const SizedBox(
            key: surfaceKey,
            child: Text('Video area'),
          ),
          callControlGateway: _RecordingCallControlGateway(),
        ),
      ),
    );

    expect(find.byKey(surfaceKey), findsOneWidget);
    expect(find.byKey(const Key('call_shell_video')), findsOneWidget);
    expect(find.byKey(const Key('call_shell_flip')), findsOneWidget);
  });

  testWidgets('Video toggle swaps active background and slash icon', (
    tester,
  ) async {
    final gateway = _RecordingCallControlGateway();
    late ThemeData theme;

    await tester.pumpWidget(
      _shellApp(
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return InAppCallShellScreen(
              sessionId: 'session_1',
              callType: SessionCallType.videoCall,
              callProviderKind: SessionCallProviderKind.agora,
              callControlGateway: gateway,
            );
          },
        ),
      ),
    );

    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        theme.componentTokens.iconToggle.inactiveBackgroundColor;
    final activeIconColor = theme.colorScheme.onPrimary;

    expect(
      _callControlMaterialColor(tester, const Key('call_shell_video')),
      activeColor,
    );
    expect(
      _callControlIconColor(tester, const Key('call_shell_video')),
      activeIconColor,
    );
    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    expect(find.byIcon(Icons.videocam_off_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('call_shell_video')));
    await tester.pumpAndSettle();

    check(gateway.cameraEnabledCalls).deepEquals([false]);
    expect(
      _callControlMaterialColor(tester, const Key('call_shell_video')),
      inactiveColor,
    );
    expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
    expect(find.byIcon(Icons.videocam_rounded), findsNothing);
    expect(
      tester
          .getSemantics(find.byKey(const Key('call_shell_video')))
          .flagsCollection
          .isToggled,
      Tristate.isFalse,
    );
  });

  testWidgets('Flip camera stays neutral when video is on', (tester) async {
    final gateway = _RecordingCallControlGateway();
    late ThemeData theme;

    await tester.pumpWidget(
      _shellApp(
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return InAppCallShellScreen(
              sessionId: 'session_1',
              callType: SessionCallType.videoCall,
              callProviderKind: SessionCallProviderKind.agora,
              callControlGateway: gateway,
            );
          },
        ),
      ),
    );

    final inactiveColor =
        theme.componentTokens.iconToggle.inactiveBackgroundColor;

    expect(
      _callControlMaterialColor(tester, const Key('call_shell_video')),
      theme.colorScheme.primary,
    );
    expect(
      _callControlMaterialColor(tester, const Key('call_shell_flip')),
      inactiveColor,
    );
    expect(
      _callControlIconColor(tester, const Key('call_shell_flip')),
      theme.colorScheme.onSurface,
    );
  });
}

Widget _shellApp(Widget home) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    localizationsDelegates: const [
      QuranSessionsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: QuranSessionsLocalizations.supportedLocales,
    builder: (context, child) => TilawaFeedbackHost(child: child!),
    home: home,
  );
}

Color _callControlMaterialColor(WidgetTester tester, Key key) {
  final materialFinder = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Material),
  );
  return tester.widget<Material>(materialFinder).color!;
}

Color _callControlIconColor(WidgetTester tester, Key key) {
  final buttonFinder = find.byKey(key);
  final iconFinder = find.descendant(
    of: buttonFinder,
    matching: find.byType(Icon),
  );
  final icon = tester.widget<Icon>(iconFinder);
  if (icon.color != null) {
    return icon.color!;
  }

  final iconThemeFinder = find.descendant(
    of: buttonFinder,
    matching: find.byType(IconTheme),
  );
  return tester.widgetList<IconTheme>(iconThemeFinder).first.data.color!;
}

class _RecordingCallControlGateway implements SessionCallControlGateway {
  _RecordingCallControlGateway({
    this.delaySwitchCamera = false,
    this.failSwitchCamera = false,
  });

  final bool delaySwitchCamera;
  final bool failSwitchCamera;
  final List<bool> microphoneEnabledCalls = [];
  final List<bool> cameraEnabledCalls = [];
  final List<bool> speakerEnabledCalls = [];
  int switchCameraCount = 0;
  int leaveCount = 0;

  @override
  Future<void> setMicrophoneEnabled({required bool enabled}) async {
    microphoneEnabledCalls.add(enabled);
  }

  @override
  Future<void> setCameraEnabled({required bool enabled}) async {
    cameraEnabledCalls.add(enabled);
  }

  @override
  Future<void> switchCamera() async {
    if (delaySwitchCamera) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    switchCameraCount++;
    if (failSwitchCamera) {
      throw StateError('switch camera failed');
    }
  }

  @override
  Future<void> setSpeakerEnabled({required bool enabled}) async {
    speakerEnabledCalls.add(enabled);
  }

  @override
  Future<void> leave() async {
    leaveCount++;
  }
}
