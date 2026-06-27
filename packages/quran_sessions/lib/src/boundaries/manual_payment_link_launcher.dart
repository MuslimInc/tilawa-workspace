/// Host-injected launchers for manual-payment external actions.
///
/// Keeps `url_launcher` out of [package:quran_sessions]. The app registers
/// implementations at startup; widgets fall back to clipboard copy when null
/// or when launch fails.
abstract final class ManualPaymentLinkLauncher {
  /// Opens [url] in an external browser/app. Returns true when handled.
  static Future<bool> Function(String url)? launchUrl;

  /// Opens WhatsApp for [phoneE164] (e.g. +201060099009). Returns true when
  /// handled.
  static Future<bool> Function(String phoneE164)? launchWhatsApp;
}
