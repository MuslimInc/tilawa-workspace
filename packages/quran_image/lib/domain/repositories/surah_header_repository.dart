import '../entities/surah_header_data.dart';

/// Interface defining the contract for retrieving semantic Surah header models.
abstract class SurahHeaderRepository {
  /// Returns a list of all header layouts applicable on a given [pageNumber].
  ///
  /// If the current page contains no headers, this method returns an empty list.
  List<SurahHeaderData> getHeadersForPage(int pageNumber);
}
