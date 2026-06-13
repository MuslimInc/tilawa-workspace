import 'package:flutter/foundation.dart';

/// Filter logcat / Flutter console with: `TilawaGSignIn`
void tilawaGSignInDebug(
  String message, {
  String? hypothesisId,
  Map<String, Object?>? data,
}) {
  final StringBuffer buffer = StringBuffer('TilawaGSignIn');
  if (hypothesisId != null) {
    buffer.write(' H=$hypothesisId');
  }
  buffer.write(' $message');
  if (data != null && data.isNotEmpty) {
    buffer.write(
      ' | ${data.entries.map((MapEntry<String, Object?> e) => '${e.key}=${e.value}').join(' ')}',
    );
  }
  debugPrint(buffer.toString());
}
