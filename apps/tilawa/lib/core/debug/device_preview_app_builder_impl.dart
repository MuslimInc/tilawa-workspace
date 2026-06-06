// device_preview is a dev_dependency; this file is excluded from release builds
// via the conditional export in device_preview_app_builder.dart.
// ignore_for_file: depend_on_referenced_packages

import 'package:device_preview/device_preview.dart';
import 'package:flutter/widgets.dart';

Widget applyDevicePreviewAppBuilder(BuildContext context, Widget? child) {
  return DevicePreview.appBuilder(context, child);
}

Widget wrapRootAppWithDevicePreview(Widget app) {
  return DevicePreview(
    enabled: false,
    builder: (context) => app,
  );
}
