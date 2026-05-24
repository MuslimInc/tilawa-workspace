import 'package:injectable/injectable.dart';
import 'package:tilawa_core/entities/audio.dart';

import '../entities/reciter_audio_catalog.dart';

/// Resolves an artist playlist from a pre-built catalog index.
@lazySingleton
class ArtistPlaylistBuilder {
  const ArtistPlaylistBuilder();

  /// O(1) lookup when [catalog] was built with [ReciterAudioCatalogBuilder].
  List<AudioEntity> playlistForArtist(
    ReciterAudioCatalog catalog,
    String artistName,
  ) {
    return catalog.tracksForArtist(artistName);
  }
}
