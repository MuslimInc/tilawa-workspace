import 'package:quran_sessions/quran_sessions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Registers host launchers for manual-payment InstaPay links and WhatsApp.
void registerManualPaymentLinkLauncher() {
  ManualPaymentLinkLauncher.launchUrl = _launchUrl;
  ManualPaymentLinkLauncher.launchWhatsApp = _launchWhatsApp;
}

Future<bool> _launchUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> _launchWhatsApp(String phoneE164) async {
  final digits = phoneE164.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return false;
  final uri = Uri.parse('https://wa.me/$digits');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
