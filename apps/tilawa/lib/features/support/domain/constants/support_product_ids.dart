/// Google Play consumable product IDs for one-time support tiers.
///
/// Create matching in-app products in Play Console (managed products,
/// consumable). Prices are set in Play Console; labels below are UI-only.
abstract final class SupportProductIds {
  static const String small = 'support_once_small';
  static const String kind = 'support_once_kind';
  static const String generous = 'support_once_generous';

  static const String androidPackageName = 'com.tilawa.app';

  static const List<String> all = <String>[small, kind, generous];
}
