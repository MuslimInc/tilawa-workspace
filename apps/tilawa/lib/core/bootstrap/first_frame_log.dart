import 'package:flutter/foundation.dart';

/// Cold-start splash tracing. Filter logcat / console with `[FirstFrame]`.
void firstFrameLog(String message) {
  debugPrint('[FirstFrame] $message');
}
