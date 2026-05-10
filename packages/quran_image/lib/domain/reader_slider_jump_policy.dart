/// Policy for when the Quran image reader captures an offscreen transition
/// snapshot during a **slider** / programmatic page jump.
///
/// Medium jumps only await image decode + [PageController.jumpToPage]. Very
/// long jumps additionally rasterize a [RawImage] overlay to mask a possible
/// one-frame GPU gap.
const int quranReaderJumpSnapshotMinPageDelta = 36;

/// Whether a jump of [absolutePageDelta] pages should use the snapshot path.
///
/// [absolutePageDelta] is \|targetIndex − currentIndex\| (0-based indices).
bool quranReaderShouldUseJumpTransitionSnapshot(int absolutePageDelta) =>
    absolutePageDelta >= quranReaderJumpSnapshotMinPageDelta;
