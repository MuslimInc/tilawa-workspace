import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Test override for [openLegalUrl].
@visibleForTesting
Future<bool> Function(Uri uri)? openLegalUrlOverride;

/// Opens a legal/support URL in the external browser.
Future<bool> openLegalUrl(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  if (openLegalUrlOverride != null) {
    return openLegalUrlOverride!(uri);
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
