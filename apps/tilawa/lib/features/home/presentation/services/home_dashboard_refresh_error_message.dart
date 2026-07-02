import 'package:flutter/widgets.dart';

import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/network/network_error_message.dart';

/// Localized snackbar copy for a failed Home pull-to-refresh.
String homeDashboardRefreshErrorMessage(
  BuildContext context,
  String message,
) {
  if (isNetworkConnectivityErrorMessage(message)) {
    return context.l10n.homeRefreshOfflineMessage;
  }
  return context.l10n.homeRefreshFailedMessage;
}
