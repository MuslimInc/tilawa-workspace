import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Resolves the current Quran Sessions user id from [AuthSessionProvider].
String? quranSessionsCurrentUserId(GetIt sl) =>
    sl<AuthSessionProvider>().currentUserId;

/// Requires a signed-in user for Quran Sessions flows.
String requireQuranSessionsUserId(GetIt sl) {
  final userId = quranSessionsCurrentUserId(sl);
  if (userId == null || userId.isEmpty) {
    throw StateError('Quran Sessions requires a signed-in user.');
  }
  return userId;
}
