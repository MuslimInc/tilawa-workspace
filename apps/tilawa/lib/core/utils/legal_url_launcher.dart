import 'package:url_launcher/url_launcher.dart';

/// Opens a legal/support URL in the external browser.
Future<bool> openLegalUrl(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
