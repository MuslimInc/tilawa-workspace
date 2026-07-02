import 'package:flutter/widgets.dart';

import 'package:tilawa/core/extensions.dart';

import '../bloc/home_dashboard_state.dart';

/// Localized snackbar copy for a failed Home pull-to-refresh.
String homeDashboardRefreshErrorMessage(
  BuildContext context,
  HomeDashboardFailureKind kind,
) {
  if (kind == HomeDashboardFailureKind.offline) {
    return context.l10n.homeRefreshOfflineMessage;
  }
  return context.l10n.homeRefreshFailedMessage;
}
