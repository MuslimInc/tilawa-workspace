import 'dart:convert';
import 'dart:io';

/// Temporary jump/jank probe. Tag: `[QuranImageJump]`.
///
/// #region agent log
void quranImageJumpLog(
  String message, {
  String hypothesisId = '',
  String location = '',
  Map<String, Object?> data = const <String, Object?>{},
}) {
  final StringBuffer buf = StringBuffer('[QuranImageJump] $message');
  if (hypothesisId.isNotEmpty) {
    buf.write(' hyp=$hypothesisId');
  }
  for (final MapEntry<String, Object?> e in data.entries) {
    buf.write(' ${e.key}=${e.value}');
  }
  // ignore: avoid_print
  print(buf.toString());
  try {
    final Map<String, Object?> payload = <String, Object?>{
      'sessionId': 'f2eb8c',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'hypothesisId': hypothesisId,
      'data': data,
    };
    File(
      '/Users/mohammadkamel/flutter_projects/tilawa_workspace/.cursor/debug-f2eb8c.log',
    ).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
  } catch (_) {}
}

/// #endregion
