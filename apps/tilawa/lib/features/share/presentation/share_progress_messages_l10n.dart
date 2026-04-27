import 'package:flutter/widgets.dart';
import 'package:tilawa/core/extensions.dart';

import '../domain/entities/share_progress_messages.dart';

extension ShareProgressMessagesL10nX on BuildContext {
  ShareProgressMessages get shareProgressMessages {
    final l10n = this.l10n;

    return ShareProgressMessages(
      preparingImage: l10n.preparingScreenshot,
      preparingAudioClip: l10n.preparingAudioClip,
      preparingVideo: l10n.preparingReelStatus,
      generatingAudioClip: l10n.generatingAudioClipStatus,
      capturingReaderVisuals: l10n.capturingReaderVisuals,
      combiningVideoMedia: l10n.combiningReelMedia,
      audioClip: AudioClipProgressMessages(
        preparingToTrimLocalAudio: l10n.preparingToTrimLocalAudio,
        reciterNotSupportedForLocalTrim: l10n.reciterNotSupportedForLocalTrim,
        fetchingAyahTimings: l10n.fetchingAyahTimings,
        noTimingsFound: l10n.noTimingsFound,
        noTimingsFoundForRange: l10n.noTimingsFoundForRange,
        trimmingAudio: l10n.trimmingAudio,
        downloadingVerse: l10n.downloadingVerseProgress,
        assemblingAudioClip: l10n.assemblingAudioClip,
        done: l10n.done,
      ),
      video: VideoProgressMessages(
        preparingVideoEncoding: l10n.preparingVideoEncoding,
        encodingVerticalVideo: l10n.encodingVerticalVideo,
        videoGenerated: l10n.reelGenerated,
        videoGenerationFailed: l10n.reelGenerationFailed,
        videoGenerationFailedInvalidFrame:
            l10n.reelGenerationFailedInvalidFrame,
        videoGenerationFailedMissingScreenshot:
            l10n.reelGenerationFailedMissingScreenshot,
        videoGenerationFailedInvalidOutput:
            l10n.reelGenerationFailedInvalidOutput,
      ),
    );
  }
}
