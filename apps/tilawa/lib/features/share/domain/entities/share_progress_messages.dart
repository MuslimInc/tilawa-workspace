typedef DownloadingVerseMessageBuilder =
    String Function(int currentVerse, int totalVerses);

class AudioClipProgressMessages {
  const AudioClipProgressMessages({
    required this.preparingToTrimLocalAudio,
    required this.reciterNotSupportedForLocalTrim,
    required this.fetchingAyahTimings,
    required this.noTimingsFound,
    required this.noTimingsFoundForRange,
    required this.trimmingAudio,
    required this.downloadingVerse,
    required this.assemblingAudioClip,
    required this.done,
  });

  final String preparingToTrimLocalAudio;
  final String reciterNotSupportedForLocalTrim;
  final String fetchingAyahTimings;
  final String noTimingsFound;
  final String noTimingsFoundForRange;
  final String trimmingAudio;
  final DownloadingVerseMessageBuilder downloadingVerse;
  final String assemblingAudioClip;
  final String done;
}

class VideoProgressMessages {
  const VideoProgressMessages({
    required this.preparingVideoEncoding,
    required this.encodingVerticalVideo,
    required this.videoGenerated,
  });

  final String preparingVideoEncoding;
  final String encodingVerticalVideo;
  final String videoGenerated;
}

class ShareProgressMessages {
  const ShareProgressMessages({
    required this.preparingImage,
    required this.preparingAudioClip,
    required this.preparingVideo,
    required this.generatingAudioClip,
    required this.capturingReaderVisuals,
    required this.combiningVideoMedia,
    required this.audioClip,
    required this.video,
  });

  final String preparingImage;
  final String preparingAudioClip;
  final String preparingVideo;
  final String generatingAudioClip;
  final String capturingReaderVisuals;
  final String combiningVideoMedia;
  final AudioClipProgressMessages audioClip;
  final VideoProgressMessages video;
}
