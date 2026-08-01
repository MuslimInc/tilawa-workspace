/// Public social profile URLs for Settings "Follow us" links.
///
/// Override at build time when needed:
/// `--dart-define=TILAWA_FACEBOOK_URL=https://...`
abstract final class AppSocialUrls {
  AppSocialUrls._();

  static const String facebook = String.fromEnvironment(
    'TILAWA_FACEBOOK_URL',
    defaultValue: 'https://www.facebook.com/memuslimapp/',
  );

  static const String instagram = String.fromEnvironment(
    'TILAWA_INSTAGRAM_URL',
    defaultValue: 'https://www.instagram.com/memuslimapp/',
  );

  static const String youtube = String.fromEnvironment(
    'TILAWA_YOUTUBE_URL',
    defaultValue: 'https://www.youtube.com/@memuslimapp',
  );
}
