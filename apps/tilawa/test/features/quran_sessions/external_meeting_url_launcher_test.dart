import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/external_meeting_url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _FakeUrlLauncher({
    this.launchUrlResult = true,
    this.launchUrlThrows = false,
    this.canLaunchResult = false,
  });

  final bool launchUrlResult;
  final bool launchUrlThrows;
  final bool canLaunchResult;

  String? launchedUrl;
  LaunchOptions? launchOptions;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (launchUrlThrows) {
      throw PlatformException(code: 'LAUNCH_ERROR');
    }
    launchedUrl = url;
    launchOptions = options;
    return launchUrlResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUrlLauncher fakeLauncher;
  late UrlLauncherPlatform previousLauncher;

  setUp(() {
    previousLauncher = UrlLauncherPlatform.instance;
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = previousLauncher;
  });

  group('launchExternalMeetingUrl', () {
    test('throws MeetingLinkUnavailableFailure for URL without scheme', () async {
      await expectLater(
        launchExternalMeetingUrl('meet.google.com/room'),
        throwsA(isA<MeetingLinkUnavailableFailure>()),
      );
    });

    test('opens valid https URL even when canLaunchUrl is false', () async {
      fakeLauncher = _FakeUrlLauncher(canLaunchResult: false);
      UrlLauncherPlatform.instance = fakeLauncher;

      await launchExternalMeetingUrl('https://meet.google.com/fiy-jjux-mpq');

      expect(fakeLauncher.launchedUrl, 'https://meet.google.com/fiy-jjux-mpq');
      expect(
        fakeLauncher.launchOptions?.mode,
        PreferredLaunchMode.externalApplication,
      );
    });

    test('throws ExternalMeetingLaunchFailure when launchUrl returns false', () async {
      fakeLauncher = _FakeUrlLauncher(launchUrlResult: false);
      UrlLauncherPlatform.instance = fakeLauncher;

      await expectLater(
        launchExternalMeetingUrl('https://meet.google.com/fiy-jjux-mpq'),
        throwsA(isA<ExternalMeetingLaunchFailure>()),
      );
    });

    test('throws ExternalMeetingLaunchFailure when launchUrl throws', () async {
      fakeLauncher = _FakeUrlLauncher(launchUrlThrows: true);
      UrlLauncherPlatform.instance = fakeLauncher;

      await expectLater(
        launchExternalMeetingUrl('https://meet.google.com/fiy-jjux-mpq'),
        throwsA(isA<ExternalMeetingLaunchFailure>()),
      );
    });
  });
}
