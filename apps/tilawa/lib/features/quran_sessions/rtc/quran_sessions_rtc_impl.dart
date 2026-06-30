// RTC implementation barrel — swap via tool/configure_rtc_deps.dart.
//
// Default (dev/staging): exports quran_sessions_rtc_sdk with Agora/LiveKit.
// Production Play builds: run `dart run tool/configure_rtc_deps.dart --stub`
// to point here at quran_sessions_rtc_stub instead.
export 'package:quran_sessions_rtc_sdk/quran_sessions_rtc_sdk.dart';
