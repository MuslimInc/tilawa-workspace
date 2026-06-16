import 'package:tilawa/core/logging/app_logger.dart';

/// Single log tag for voice recitation debugging.
///
/// Filter device logs with `[VoiceRecitation]`.
abstract final class VoiceRecitationLog {
  static const String tag = '[VoiceRecitation]';

  static void d(String message) => logger.d('$tag $message');

  static void i(String message) => logger.i('$tag $message');

  static void w(String message) => logger.w('$tag $message');
}
