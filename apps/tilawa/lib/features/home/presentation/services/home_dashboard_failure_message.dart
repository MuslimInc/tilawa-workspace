import 'package:flutter/widgets.dart';

import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';

/// Localized hero copy when the initial Home dashboard load fails.
String homeDashboardFailureMessage(
  BuildContext context,
  HomeDashboardFailure failure,
) {
  if (failure.kind == HomeDashboardFailureKind.offline) {
    return context.l10n.homeDashboardOfflineError;
  }
  return context.l10n.homeDashboardLoadError;
}
