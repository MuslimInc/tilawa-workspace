import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Resolves the current Quran Sessions user id from [AuthSessionProvider].
String? quranSessionsCurrentUserId(GetIt sl) =>
    sl<AuthSessionProvider>().currentUserId;

/// Signed-in Quran Sessions user id, or null when absent or empty.
///
/// Never throws — route redirects and UI gates must handle null.
String? resolveQuranSessionsUserId(GetIt sl) {
  final userId = quranSessionsCurrentUserId(sl);
  if (userId == null || userId.isEmpty) {
    return null;
  }
  return userId;
}
