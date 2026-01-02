import 'dart:developer';

/// Utility class for URL validation and manipulation.
///
/// This class provides static methods to validate URLs before they are used
/// in network requests or audio playback to prevent crashes from malformed URLs.
class UrlValidator {
  const UrlValidator._();

  /// Validates if a URL string is valid and properly formatted.
  ///
  /// Returns `true` if the URL is valid, `false` otherwise.
  ///
  /// A valid URL must:
  /// - Not be empty
  /// - Have a valid scheme (http, https, or file)
  /// - For http/https URLs: have a non-empty host
  /// - For file URLs: have a non-empty path
  ///
  /// Example:
  /// ```dart
  /// UrlValidator.isValid('https://example.com/audio.mp3'); // true
  /// UrlValidator.isValid(''); // false
  /// UrlValidator.isValid('not-a-url'); // false
  /// ```
  static bool isValid(String url) {
    if (url.isEmpty) {
      return false;
    }

    // Check for unencoded spaces or other invalid characters
    if (url.contains(' ') || url.contains('\t') || url.contains('\n')) {
      log('URL contains unencoded whitespace: $url');
      return false;
    }

    try {
      final Uri uri = Uri.parse(url);

      // Check if it's a valid HTTP/HTTPS URL or a valid file path
      if (uri.scheme.isEmpty) {
        return false;
      }

      if (uri.scheme == 'http' || uri.scheme == 'https') {
        // Validate host exists for network URLs
        return uri.host.isNotEmpty;
      }

      if (uri.scheme == 'file') {
        // Accept file URIs with non-empty paths
        return uri.path.isNotEmpty;
      }

      // Reject other schemes
      return false;
    } catch (e) {
      log('Invalid URL format: $url, error: $e');
      return false;
    }
  }

  /// Validates and throws an [ArgumentError] if the URL is invalid.
  ///
  /// Use this when you want to ensure a URL is valid and fail fast if not.
  ///
  /// Throws [ArgumentError] if the URL is invalid.
  ///
  /// Example:
  /// ```dart
  /// UrlValidator.validate('https://example.com/audio.mp3'); // OK
  /// UrlValidator.validate(''); // throws ArgumentError
  /// ```
  static void validate(String url, {String? context}) {
    if (!isValid(url)) {
      final contextMsg = context != null ? ' ($context)' : '';
      throw ArgumentError('Invalid URL$contextMsg: $url');
    }
  }

  /// Attempts to parse a URL and returns null if invalid.
  ///
  /// This is useful when you want to handle invalid URLs gracefully.
  ///
  /// Returns the parsed [Uri] if valid, `null` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final uri = UrlValidator.tryParse('https://example.com/audio.mp3');
  /// if (uri != null) {
  ///   // Use the URI
  /// }
  /// ```
  static Uri? tryParse(String url) {
    if (!isValid(url)) {
      return null;
    }

    try {
      return Uri.parse(url);
    } catch (e) {
      log('Error parsing URL: $url, error: $e');
      return null;
    }
  }

  /// Checks if a URL scheme is supported for audio playback.
  ///
  /// Supported schemes: http, https, file
  static bool isSupportedScheme(String scheme) {
    return scheme == 'http' || scheme == 'https' || scheme == 'file';
  }
}
