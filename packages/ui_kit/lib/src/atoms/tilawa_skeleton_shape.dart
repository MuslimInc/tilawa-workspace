/// Defines the shape of a skeleton placeholder block.
///
/// Used by [TilawaSkeletonBlock] to determine the border radius and aspect ratio
/// of the placeholder.
enum TilawaSkeletonShape {
  /// A rectangle with sharp corners (0 radius).
  ///
  /// Use for: full-width sections, divider-like placeholders, image containers.
  rectangle,

  /// A perfect circle (50% radius).
  ///
  /// Use for: avatars, profile pictures, circular icons.
  /// When using circle, width and height should typically be equal.
  circle,

  /// A rectangle with rounded corners.
  ///
  /// Use for: text lines, cards, buttons, general content blocks.
  /// Border radius is controlled by [TilawaSkeletonTokens.borderRadius].
  rounded,
}
