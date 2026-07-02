/// Detects Firebase/gRPC/Dart connectivity errors that ship in English.
bool isNetworkConnectivityErrorMessage(String message) {
  final String normalized = message.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  return normalized.contains('network error') ||
      normalized.contains('interrupted connection') ||
      normalized.contains('unreachable host') ||
      normalized.contains('socketexception') ||
      normalized.contains('failed host lookup') ||
      normalized.contains('connection refused') ||
      normalized.contains('no address associated with hostname') ||
      normalized.contains('network is unreachable') ||
      normalized.contains('connection timed out') ||
      normalized.contains('connection closed') ||
      normalized.contains('client is offline') ||
      normalized.contains('unable to resolve host');
}
