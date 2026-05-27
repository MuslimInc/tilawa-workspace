import 'package:injectable/injectable.dart';
import 'package:quran_image/core/di/dependency_injection.dart' as qi_di;
import 'package:quran_image/data/repositories/asset_verse_marker_repository.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';

import '../../domain/ports/quran_image_preload_status.dart';

/// Reads preload readiness from the `quran_image` package DI graph.
@LazySingleton(as: QuranImagePreloadStatus)
class QuranImagePreloadStatusAdapter implements QuranImagePreloadStatus {
  const QuranImagePreloadStatusAdapter();

  @override
  bool get isReady {
    final AssetVerseMarkerRepository markers =
        qi_di.sl<AssetVerseMarkerRepository>();
    final QuranImageCacheRepository images =
        qi_di.sl<QuranImageCacheRepository>();
    return markers.isInitialized && images.status.isReady;
  }
}
