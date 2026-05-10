import 'dart:math' as math;

/// Policy for when the Quran image reader captures an offscreen transition
/// snapshot during a **slider** / programmatic page jump.
///
/// Medium jumps only await image decode + [PageController.jumpToPage]. Very
/// long jumps additionally rasterize a [RawImage] overlay to mask a possible
/// one-frame GPU gap.
const int quranReaderJumpSnapshotMinPageDelta = 36;

/// Maximum [RenderRepaintBoundary.toImage] pixel ratio for jump snapshots.
///
/// High-DPR devices otherwise rasterize at full resolution (cost scales
/// roughly with the square of pixel ratio). The overlay is transient; capping
/// keeps work bounded while typical phones at ≤2.0 DPR are unchanged.
const double quranReaderSnapshotToImagePixelRatioCap = 2.0;

/// Effective pixel ratio for snapshot capture on this device.
double quranReaderSnapshotPixelRatioForCapture(double devicePixelRatio) =>
    math.min(devicePixelRatio, quranReaderSnapshotToImagePixelRatioCap);

/// Whether a jump of [absolutePageDelta] pages should use the snapshot path.
///
/// [absolutePageDelta] is \|targetIndex − currentIndex\| (0-based indices).
bool quranReaderShouldUseJumpTransitionSnapshot(int absolutePageDelta) =>
    absolutePageDelta >= quranReaderJumpSnapshotMinPageDelta;
