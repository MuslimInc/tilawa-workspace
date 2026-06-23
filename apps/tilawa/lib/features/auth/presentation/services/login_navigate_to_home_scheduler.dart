import 'package:flutter/scheduler.dart';

/// Posts home navigation after the current frame when [isMounted] is true.
void scheduleLoginNavigateToHome({
  required bool Function() isMounted,
  required void Function() navigate,
}) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!isMounted()) {
      return;
    }
    navigate();
  });
}
