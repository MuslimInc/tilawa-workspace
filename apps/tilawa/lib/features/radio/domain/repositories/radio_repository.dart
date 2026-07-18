import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/radio_station.dart';

/// Catalog, favorites, and recently played for Islamic Radio.
abstract class RadioRepository {
  /// Cache-first station list; refreshes from network when online.
  ResultFuture<List<RadioStation>> getStations({required String language});

  /// Force network refresh. On failure, returns cached list when available.
  ResultFuture<List<RadioStation>> refreshStations({
    required String language,
    DateTime? after,
  });

  /// Local filter on the last loaded/cached catalog by station name.
  ResultFuture<List<RadioStation>> searchStations(String query);

  ResultFuture<List<RadioStation>> getFavorites();

  ResultFuture<RadioStation> toggleFavorite(String stationId);

  ResultFuture<List<RadioStation>> getRecentStations();

  ResultFuture<void> addRecentStation(RadioStation station);
}
