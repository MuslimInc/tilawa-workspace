import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'marionette_env_io.dart'
    if (dart.library.html) 'marionette_env_stub.dart'
    as marionette_env;

/// Forwards [logger] lines into Marionette `get_logs` in debug only.
final PrintLogCollector marionettePrintLogCollector = PrintLogCollector();

/// Sink wired from [logger] so Marionette can read runtime logs.
void Function(String message)? debugMarionetteLogSink;

/// Initializes the single Flutter binding for Tilawa.
///
/// Debug (non-test): [MarionetteBinding] first so VM extensions exist and
/// Sentry reuses that binding. Profile/release: [SentryWidgetsFlutterBinding]
/// (existing production path). Never enable Marionette outside [kDebugMode].
void ensureTilawaWidgetsBinding() {
  if (kDebugMode && !marionette_env.isFlutterTestEnv) {
    debugMarionetteLogSink = marionettePrintLogCollector.addLog;
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(
        logCollector: marionettePrintLogCollector,
        isInteractiveWidget: (Type type) =>
            type == TilawaInteractiveSurface ||
            type == TilawaButton ||
            type == TilawaIconButton ||
            type == TilawaCard,
        extractText: (Element element) {
          final Widget widget = element.widget;
          if (widget is TilawaButton) {
            return widget.semanticLabel ?? widget.text;
          }
          if (widget is TilawaInteractiveSurface) {
            return widget.semanticLabel;
          }
          if (widget is TilawaIconButton) {
            return widget.semanticLabel ?? widget.tooltip;
          }
          return null;
        },
      ),
    );
    return;
  }

  // Construct directly when absent — SentryWidgetsFlutterBinding.ensureInitialized()
  // probes WidgetsBinding.instance first, which throws FlutterError on cold start.
  if (BindingBase.debugBindingType() == null) {
    SentryWidgetsFlutterBinding();
  }
}
