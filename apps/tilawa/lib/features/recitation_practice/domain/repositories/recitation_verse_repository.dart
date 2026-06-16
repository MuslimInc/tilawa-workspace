import '../entities/recitation_target.dart';

/// Loads ayah text and page targets for recitation practice.
abstract class RecitationVerseRepository {
  List<RecitationTarget> getTargetsForPage(int pageNumber);
}
