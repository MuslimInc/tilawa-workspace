import 'package:flutter/widgets.dart';

/// Release/profile stub — no [device_preview] dependency in store builds.
Widget applyDevicePreviewAppBuilder(BuildContext context, Widget? child) {
  return child ?? const SizedBox.shrink();
}

/// Release/profile stub — root app is not wrapped in [DevicePreview].
Widget wrapRootAppWithDevicePreview(Widget app) => app;
