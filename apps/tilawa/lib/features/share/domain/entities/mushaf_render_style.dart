/// The visual style the mushaf is rendered in when generating shareable
/// media such as video reels.
///
/// Domain-level concept: expresses *what* the output should look like, not
/// *which* package produces it. The data/presentation layers decide how to
/// realize each style.
enum MushafRenderStyle {
  /// High-fidelity, pre-rendered Mushaf page images. Matches what a user
  /// sees in a printed Mushaf at the cost of flexibility (no dynamic
  /// layout or line-wrapping).
  highFidelity,

  /// Dynamically laid out text using QCF/QCP fonts. Flexible (responds to
  /// viewport width, supports per-verse background colors) at the cost of
  /// slight visual divergence from the printed Mushaf.
  dynamicLayout,
}
