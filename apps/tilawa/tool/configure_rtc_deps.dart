// ignore_for_file: avoid_print

import 'dart:io';

/// Switches Tilawa between RTC SDK and no-SDK dependency graphs.
///
/// Play production AABs must run with `--stub` so Agora/LiveKit native libs are
/// not linked. Dev/staging defaults use `--sdk`.
///
/// ```sh
/// dart run tool/configure_rtc_deps.dart --stub   # production
/// dart run tool/configure_rtc_deps.dart --sdk    # restore dev default
/// ```
void main(List<String> args) {
  final useStub = args.contains('--stub');
  final useSdk = args.contains('--sdk');
  if (useStub == useSdk) {
    stderr.writeln('Pass exactly one of --stub or --sdk');
    exit(64);
  }

  final appRoot = Directory.current;
  if (!File('${appRoot.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from apps/tilawa');
    exit(64);
  }

  _configureImplExport(appRoot, useStub: useStub);
  _configurePubspec(appRoot, useStub: useStub);
  print(
    useStub
        ? 'RTC deps: stub (no Agora/LiveKit native SDKs)'
        : 'RTC deps: sdk (Agora + LiveKit)',
  );
}

void _configureImplExport(Directory appRoot, {required bool useStub}) {
  const implPath =
      'lib/features/quran_sessions/rtc/quran_sessions_rtc_impl.dart';
  final exportLine = useStub
      ? "export 'package:quran_sessions_rtc_stub/quran_sessions_rtc_stub.dart';"
      : "export 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';";
  final content =
      '''// RTC implementation barrel — swap via tool/configure_rtc_deps.dart.
//
// Default (dev/staging): exports quran_sessions_rtc_sdk with Agora/LiveKit.
// Production Play builds: run `dart run tool/configure_rtc_deps.dart --stub`
// to point here at quran_sessions_rtc_stub instead.
$exportLine
''';
  File('${appRoot.path}/$implPath').writeAsStringSync(content);
}

void _configurePubspec(Directory appRoot, {required bool useStub}) {
  final pubspecFile = File('${appRoot.path}/pubspec.yaml');
  var lines = pubspecFile.readAsLinesSync();
  const sdkKey = '  quran_sessions_rtc_sdk:';
  const stubKey = '  quran_sessions_rtc_stub:';

  lines = lines.where((line) {
    if (line.startsWith(sdkKey) || line.startsWith(stubKey)) {
      return false;
    }
    if (line.trim() == 'path: ../../packages/quran_sessions_rtc_sdk' ||
        line.trim() == 'path: ../../packages/quran_sessions_rtc_stub') {
      return false;
    }
    return true;
  }).toList();

  final rtcIndex = lines.indexWhere(
    (line) => line.startsWith('  quran_sessions_rtc:'),
  );
  if (rtcIndex == -1) {
    stderr.writeln('quran_sessions_rtc dependency not found in pubspec.yaml');
    exit(1);
  }

  final insertAt = rtcIndex + 2;
  if (useStub) {
    lines.insertAll(insertAt, [
      '  quran_sessions_rtc_stub:',
      '    path: ../../packages/quran_sessions_rtc_stub',
    ]);
  } else {
    lines.insertAll(insertAt, [
      '  quran_sessions_rtc_sdk:',
      '    path: ../../packages/quran_sessions_rtc_sdk',
    ]);
  }

  pubspecFile.writeAsStringSync('${lines.join('\n')}\n');
}
